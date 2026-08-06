"""Agentning asboblari (tools).

Bu fayl — agentning "qo'llari". Model faqat gapira oladi; haqiqiy ish
(fayl o'qish, buyruq bajarish) shu yerdagi Python funksiyalar orqali bo'ladi.

Ishlash tartibi:
  1. TOOLS ro'yxati modelga yuboriladi (nomi, tavsifi, parametrlari).
  2. Model "get_current_time ni chaqir" deb qaytaradi — o'zi bajarmaydi.
  3. agent.py `execute()` ni chaqiradi va natijani modelga qaytaradi.

Yangi asbob qo'shish uchun: TOOLS ga sxema yozing + _HANDLERS ga funksiya.
Tavsif (description) juda muhim — model AYNAN shu matnga qarab qaysi asbobni
qachon ishlatishni hal qiladi. Aniq va batafsil yozing.
"""

from __future__ import annotations

import subprocess
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Callable

from config import FORBIDDEN_PATTERNS, SAFE_COMMANDS, WORKSPACE
from memory import Memory


@dataclass
class ToolContext:
    """Asboblar ishlashi uchun kerak bo'ladigan hamma narsa."""

    memory: Memory
    workspace: Path
    # Xavfli amal uchun foydalanuvchidan ruxsat so'raydigan funksiya.
    # CLI da bu input() ni chaqiradi; veb/ovozda boshqacha bo'ladi.
    confirm: Callable[[str], bool]


# --- Asboblar sxemasi (model shuni ko'radi) ------------------------------

TOOLS = [
    {
        "name": "get_current_time",
        "description": (
            "Returns the current date and time. Call this whenever the answer "
            "depends on 'now' — scheduling, deadlines, 'how long ago', or when "
            "the user says today/tomorrow/this week."
        ),
        "input_schema": {"type": "object", "properties": {}},
    },
    {
        "name": "list_files",
        "description": (
            "Lists files and folders inside the agent's workspace. Call this "
            "before reading or writing when you are not certain what exists. "
            "Paths are relative to the workspace root; '.' means the root."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Relative folder path. Use '.' for the root.",
                }
            },
            "required": ["path"],
        },
    },
    {
        "name": "read_file",
        "description": (
            "Reads a text file from the workspace and returns its contents. "
            "Call this instead of guessing what a file contains. Returns an "
            "error string if the file is missing or is not text."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "Relative file path."}
            },
            "required": ["path"],
        },
    },
    {
        "name": "write_file",
        "description": (
            "Creates or overwrites a text file in the workspace. Parent folders "
            "are created automatically. Overwriting an existing file asks the "
            "user for confirmation first, so do not fear losing data — but do "
            "read the file first if you only mean to change part of it."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "Relative file path."},
                "content": {"type": "string", "description": "Full file contents."},
            },
            "required": ["path", "content"],
        },
    },
    {
        "name": "run_command",
        "description": (
            "Runs a shell command inside the workspace and returns stdout, "
            "stderr and the exit code. Read-only commands (ls, cat, grep, ...) "
            "run immediately; anything else asks the user for permission. "
            "Use this for things the other tools cannot do — running a script, "
            "checking git status, counting lines. One command per call; no "
            "interactive programs."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "command": {"type": "string", "description": "The shell command."}
            },
            "required": ["command"],
        },
    },
    {
        "name": "remember",
        "description": (
            "Saves a durable fact about the user or their projects so future "
            "sessions can use it. Call this when you learn something that will "
            "still matter next week: preferences, names, project details, "
            "recurring tasks. Use a short stable key like 'til' or "
            "'loyiha.savin.stack'. Re-using a key overwrites the old value."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "key": {"type": "string", "description": "Short identifier."},
                "value": {"type": "string", "description": "The fact itself."},
            },
            "required": ["key", "value"],
        },
    },
    {
        "name": "recall",
        "description": (
            "Searches saved facts by keyword. Call this when the user refers to "
            "something from an earlier conversation, or before starting a task "
            "where their past preferences would change how you do it."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Keyword to search for."}
            },
            "required": ["query"],
        },
    },
    {
        "name": "forget",
        "description": (
            "Deletes a saved fact by its exact key. Call this when the user says "
            "a stored fact is wrong or no longer applies."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "key": {"type": "string", "description": "Exact key to delete."}
            },
            "required": ["key"],
        },
    },
]


# --- Xavfsizlik ----------------------------------------------------------


def _safe_path(ctx: ToolContext, raw: str) -> Path:
    """Yo'lni workspace ichiga qamab qo'yadi.

    Bu funksiya butun sandbox'ning tayanchi. Modeldan kelgan yo'lga
    ISHONMAYMIZ: '../../etc/passwd' kabi urinishlar shu yerda to'xtaydi.
    """
    candidate = (ctx.workspace / raw).resolve()
    if candidate != ctx.workspace and not candidate.is_relative_to(ctx.workspace):
        raise PermissionError(
            f"Ruxsat yo'q: '{raw}' workspace papkasidan tashqarida."
        )
    return candidate


# --- Asboblarning amalga oshirilishi -------------------------------------


def _get_current_time(ctx: ToolContext, _: dict) -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S (%A)")


def _list_files(ctx: ToolContext, args: dict) -> str:
    target = _safe_path(ctx, args.get("path", "."))
    if not target.exists():
        return f"Xato: '{args.get('path')}' mavjud emas."
    if not target.is_dir():
        return f"Xato: '{args.get('path')}' papka emas."

    lines = []
    for item in sorted(target.iterdir(), key=lambda p: (p.is_file(), p.name)):
        if item.is_dir():
            lines.append(f"[papka] {item.name}/")
        else:
            lines.append(f"[fayl]  {item.name}  ({item.stat().st_size} bayt)")
    return "\n".join(lines) or "(bo'sh papka)"


def _read_file(ctx: ToolContext, args: dict) -> str:
    target = _safe_path(ctx, args["path"])
    if not target.is_file():
        return f"Xato: '{args['path']}' fayli topilmadi."
    try:
        text = target.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return f"Xato: '{args['path']}' matnli fayl emas (binary)."
    # Juda katta fayl kontekstni to'ldirib yuboradi — kesamiz.
    if len(text) > 40_000:
        return text[:40_000] + "\n\n[... fayl kesildi, 40000 belgidan uzun ...]"
    return text


def _write_file(ctx: ToolContext, args: dict) -> str:
    target = _safe_path(ctx, args["path"])
    if target.exists():
        # Mavjud faylni yo'q qilish — qaytarib bo'lmaydigan amal. So'raymiz.
        if not ctx.confirm(f"'{args['path']}' fayli ustiga yozilsinmi?"):
            return "Foydalanuvchi rad etdi: fayl o'zgartirilmadi."
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(args["content"], encoding="utf-8")
    return f"Yozildi: {args['path']} ({len(args['content'])} belgi)"


def _run_command(ctx: ToolContext, args: dict) -> str:
    command = args["command"].strip()

    for bad in FORBIDDEN_PATTERNS:
        if bad in command:
            return f"Rad etildi: buyruqda taqiqlangan naqsh bor ('{bad}')."

    first_word = command.split()[0] if command.split() else ""
    is_safe = first_word in SAFE_COMMANDS and not any(
        op in command for op in ("&&", "||", ";", "|", ">", "<", "`", "$(")
    )

    if not is_safe:
        if not ctx.confirm(f"Buyruq bajarilsinmi?\n    {command}"):
            return "Foydalanuvchi rad etdi: buyruq bajarilmadi."

    try:
        proc = subprocess.run(
            command,
            shell=True,
            cwd=ctx.workspace,
            capture_output=True,
            text=True,
            timeout=60,
        )
    except subprocess.TimeoutExpired:
        return "Xato: buyruq 60 soniyada tugamadi, to'xtatildi."

    parts = [f"exit_code: {proc.returncode}"]
    if proc.stdout:
        parts.append(f"stdout:\n{proc.stdout[:10_000]}")
    if proc.stderr:
        parts.append(f"stderr:\n{proc.stderr[:5_000]}")
    return "\n".join(parts)


def _remember(ctx: ToolContext, args: dict) -> str:
    status = ctx.memory.remember(args["key"], args["value"])
    return f"Xotiraga {status}: {args['key']}"


def _recall(ctx: ToolContext, args: dict) -> str:
    hits = ctx.memory.recall(args["query"])
    if not hits:
        return f"'{args['query']}' bo'yicha xotirada hech narsa topilmadi."
    return "\n".join(f"{h['key']}: {h['value']}" for h in hits)


def _forget(ctx: ToolContext, args: dict) -> str:
    if ctx.memory.forget(args["key"]):
        return f"O'chirildi: {args['key']}"
    return f"'{args['key']}' kaliti xotirada yo'q edi."


_HANDLERS: dict[str, Callable[[ToolContext, dict], str]] = {
    "get_current_time": _get_current_time,
    "list_files": _list_files,
    "read_file": _read_file,
    "write_file": _write_file,
    "run_command": _run_command,
    "remember": _remember,
    "recall": _recall,
    "forget": _forget,
}


def execute(ctx: ToolContext, name: str, args: dict) -> tuple[str, bool]:
    """Asbobni bajaradi.

    Qaytaradi: (natija matni, xato_bormi).
    Xato bo'lsa ham exception otmaydi — modelga xato matnini qaytaramiz,
    u o'zi tuzatishga urinadi. Bu agentni ancha barqaror qiladi.
    """
    handler = _HANDLERS.get(name)
    if handler is None:
        return f"Noma'lum asbob: {name}", True
    try:
        return handler(ctx, args), False
    except PermissionError as e:
        return str(e), True
    except Exception as e:  # noqa: BLE001 — modelga har qanday xatoni qaytaramiz
        return f"{type(e).__name__}: {e}", True
