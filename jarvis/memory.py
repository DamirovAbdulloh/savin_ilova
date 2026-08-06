"""Agentning xotirasi — SQLite ustida.

Ikki xil xotira bor:

1. `messages`  — epizodik xotira: kim nima dedi, qachon.
                 Suhbat tarixi shu yerdan tiklanadi (dastur o'chsa ham qoladi).

2. `facts`     — semantik xotira: "foydalanuvchi Flutter'da yozadi",
                 "loyiha nomi Savin". Agent buni o'zi to'ldiradi.

Nega vektor baza emas? Boshlash uchun kerak emas — qo'shimcha kutubxona,
qo'shimcha xarajat. Faktlar soni yuzlab bo'lsa oddiy matn qidiruvi yetadi.
Minglab bo'lganda vektor bazaga o'tasiz (README dagi "Keyingi qadamlar").
"""

import json
import sqlite3
import time
from pathlib import Path


def _is_tool_result(content) -> bool:
    """Xabar asbob natijalaridan iboratmi?"""
    return isinstance(content, list) and any(
        isinstance(b, dict) and b.get("type") == "tool_result" for b in content
    )


class Memory:
    def __init__(self, db_path: Path):
        db_path.parent.mkdir(parents=True, exist_ok=True)
        # check_same_thread=False — keyinchalik ovoz/veb qo'shsangiz kerak bo'ladi.
        self.db = sqlite3.connect(db_path, check_same_thread=False)
        self.db.row_factory = sqlite3.Row
        self._init_schema()

    def _init_schema(self) -> None:
        self.db.executescript(
            """
            CREATE TABLE IF NOT EXISTS messages (
                id      INTEGER PRIMARY KEY AUTOINCREMENT,
                ts      REAL NOT NULL,
                role    TEXT NOT NULL,          -- user | assistant
                content TEXT NOT NULL           -- JSON (content bloklari)
            );

            CREATE TABLE IF NOT EXISTS facts (
                key        TEXT PRIMARY KEY,
                value      TEXT NOT NULL,
                updated_at REAL NOT NULL
            );
            """
        )
        self.db.commit()

    # --- Epizodik xotira: suhbat tarixi ---------------------------------

    def add_message(self, role: str, content) -> None:
        """Bitta xabarni saqlaydi. `content` — matn yoki content-bloklar ro'yxati."""
        self.db.execute(
            "INSERT INTO messages (ts, role, content) VALUES (?, ?, ?)",
            (time.time(), role, json.dumps(content, ensure_ascii=False)),
        )
        self.db.commit()

    def recent_messages(self, limit: int) -> list[dict]:
        """Oxirgi N ta xabarni Anthropic API formatida qaytaradi."""
        rows = self.db.execute(
            "SELECT role, content FROM messages ORDER BY id DESC LIMIT ?", (limit,)
        ).fetchall()
        # Teskari tartibda oldik — to'g'rilaymiz.
        messages = [
            {"role": r["role"], "content": json.loads(r["content"])}
            for r in reversed(rows)
        ]
        # API ikkita talab qo'yadi:
        #   1. birinchi xabar "user" bo'lishi kerak;
        #   2. "tool_result" bloki undan oldingi "tool_use" bilan juftlashishi kerak.
        # Tarixni kesganimizda juftlik buzilishi mumkin — boshidagi yetim
        # tool_result larni tashlab yuboramiz.
        while messages and (
            messages[0]["role"] != "user" or _is_tool_result(messages[0]["content"])
        ):
            messages.pop(0)
        return messages

    def clear_conversation(self) -> int:
        cur = self.db.execute("DELETE FROM messages")
        self.db.commit()
        return cur.rowcount

    # --- Semantik xotira: faktlar ---------------------------------------

    def remember(self, key: str, value: str) -> str:
        """Faktni saqlaydi yoki mavjudini yangilaydi."""
        existing = self.db.execute(
            "SELECT value FROM facts WHERE key = ?", (key,)
        ).fetchone()
        self.db.execute(
            "INSERT INTO facts (key, value, updated_at) VALUES (?, ?, ?) "
            "ON CONFLICT(key) DO UPDATE SET value = excluded.value, "
            "updated_at = excluded.updated_at",
            (key, value, time.time()),
        )
        self.db.commit()
        return "yangilandi" if existing else "saqlandi"

    def forget(self, key: str) -> bool:
        cur = self.db.execute("DELETE FROM facts WHERE key = ?", (key,))
        self.db.commit()
        return cur.rowcount > 0

    def recall(self, query: str, limit: int = 10) -> list[dict]:
        """Kalit yoki qiymat bo'yicha oddiy matn qidiruvi."""
        pattern = f"%{query}%"
        rows = self.db.execute(
            "SELECT key, value FROM facts WHERE key LIKE ? OR value LIKE ? "
            "ORDER BY updated_at DESC LIMIT ?",
            (pattern, pattern, limit),
        ).fetchall()
        return [dict(r) for r in rows]

    def all_facts(self, limit: int = 40) -> list[dict]:
        """Eng so'nggi faktlar — har suhbat boshida modelga beriladi."""
        rows = self.db.execute(
            "SELECT key, value FROM facts ORDER BY updated_at DESC LIMIT ?", (limit,)
        ).fetchall()
        return [dict(r) for r in rows]

    def close(self) -> None:
        self.db.close()
