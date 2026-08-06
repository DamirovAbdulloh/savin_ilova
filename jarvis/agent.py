"""Jarvis — agentning yuragi.

Bu yerdagi eng muhim narsa — `chat()` ichidagi halqa. Butun "agent"
tushunchasi shu 30 qatordan iborat:

    kuzat -> o'yla -> harakat qil -> natijani ko'r -> takrorla

Qolgan hamma narsa (ovoz, interfeys, integratsiyalar) shu halqa ustiga
qurilgan qatlam xolos.

Ishga tushirish:  python agent.py
"""

from __future__ import annotations

import os
import sys

import anthropic

import config
import tools
from memory import Memory


class Jarvis:
    def __init__(self) -> None:
        # Kalit ANTHROPIC_API_KEY muhit o'zgaruvchisidan olinadi.
        # Kodga kalit yozmang — .env ishlating (README ga qarang).
        self.client = anthropic.Anthropic()
        self.memory = Memory(config.DB_PATH)
        config.WORKSPACE.mkdir(parents=True, exist_ok=True)

        self.ctx = tools.ToolContext(
            memory=self.memory,
            workspace=config.WORKSPACE,
            confirm=self._ask_permission,
        )

        # Server tomonidagi zaxira model bor-yo'qligini bir marta tekshiramiz.
        self._use_fallbacks = True

    # --- Foydalanuvchidan ruxsat so'rash --------------------------------

    @staticmethod
    def _ask_permission(question: str) -> bool:
        """Xavfli amaldan oldin chaqiriladi. Bu — inson nazorati nuqtasi.

        Agentni avtonom qilsangiz ham, shu funksiyani olib tashlamang —
        uni Telegram'ga xabar yuborish yoki logga yozishga almashtiring.
        """
        print(f"\n  \033[33m[ruxsat kerak]\033[0m {question}")
        answer = input("  ha / yo'q > ").strip().lower()
        return answer in ("ha", "h", "y", "yes", "ok")

    # --- Modelga murojaat -----------------------------------------------

    def _call_model(self, messages: list[dict]):
        """Bitta API so'rovi.

        Diqqat qiling:
        - `thinking` ni yozmayapmiz: Opus 5 da u sukut bo'yicha yoqilgan.
        - `effort` — o'ylash chuqurligi va xarajatni boshqaradigan tugma.
        - `cache_control` — tizim prompti keshlanadi, takroriy o'qish ~10x arzon.
        - `temperature` YO'Q: Opus 5 da bu parametr qabul qilinmaydi (400 xato).
        """
        params = dict(
            model=config.MODEL,
            max_tokens=config.MAX_TOKENS,
            output_config={"effort": config.EFFORT},
            system=[
                {
                    "type": "text",
                    "text": config.SYSTEM_PROMPT,
                    "cache_control": {"type": "ephemeral"},
                }
            ],
            tools=tools.TOOLS,
            messages=messages,
        )

        # Xavfsizlik klassifikatori so'rovni rad etsa, API uni avtomatik
        # boshqa modelda qayta ishga tushiradi. Eski SDK da bu parametr
        # bo'lmasligi mumkin — shuning uchun ehtiyot chorasi bilan.
        if self._use_fallbacks:
            try:
                return self.client.beta.messages.create(
                    betas=["server-side-fallback-2026-07-01"],
                    fallbacks="default",
                    **params,
                )
            except (TypeError, anthropic.BadRequestError, anthropic.NotFoundError):
                self._use_fallbacks = False

        return self.client.messages.create(**params)

    # --- Asosiy halqa ----------------------------------------------------

    def chat(self, user_input: str) -> str:
        """Foydalanuvchining bitta xabariga to'liq javob beradi.

        Ichida bir necha marta modelga murojaat bo'lishi mumkin — model
        asbob chaqirsa, biz uni bajarib, natijani qaytaramiz va model
        davom etadi. Shuning uchun bu "so'rov-javob" emas, "halqa".
        """
        # Xotiradagi faktlarni suhbatga qo'shamiz. Ularni tizim promptiga
        # emas, foydalanuvchi xabariga qo'yamiz — aks holda kesh buziladi.
        facts = self.memory.all_facts()
        content = user_input
        if facts:
            fact_lines = "\n".join(f"- {f['key']}: {f['value']}" for f in facts)
            content = (
                f"<xotira>\nSen bu foydalanuvchi haqida quyidagilarni bilasan:\n"
                f"{fact_lines}\n</xotira>\n\n{user_input}"
            )

        self.memory.add_message("user", content)
        messages = self.memory.recent_messages(config.HISTORY_LIMIT)

        final_text = ""

        for step in range(config.MAX_STEPS):
            response = self._call_model(messages)

            # 1. Rad etishni content'dan OLDIN tekshiramiz.
            #    content[0] ga to'g'ridan-to'g'ri murojaat qilish xato bo'ladi.
            if response.stop_reason == "refusal":
                return (
                    "Bu so'rovni bajara olmadim — xavfsizlik filtri to'xtatdi. "
                    "Savolni boshqacha shakllantirib ko'ring."
                )

            # 2. Model javobini tarixga qo'shamiz.
            #    MUHIM: butun `response.content` ni saqlaymiz — ichidagi
            #    "thinking" bloklarini o'zgartirmasdan qaytarish shart.
            assistant_blocks = [block.model_dump() for block in response.content]
            messages.append({"role": "assistant", "content": assistant_blocks})
            self.memory.add_message("assistant", assistant_blocks)

            # 3. Matnni yig'amiz.
            text_now = "".join(
                b.text for b in response.content if b.type == "text"
            ).strip()
            if text_now:
                final_text = text_now

            # 4. Asbob chaqirilmagan bo'lsa — ish tugadi.
            if response.stop_reason != "tool_use":
                return final_text or "(model matn qaytarmadi)"

            # 5. Chaqirilgan asboblarni bajaramiz.
            tool_results = []
            for block in response.content:
                if block.type != "tool_use":
                    continue

                print(f"  \033[90m-> {block.name}({_short(block.input)})\033[0m")
                result, is_error = tools.execute(self.ctx, block.name, block.input)

                tool_results.append(
                    {
                        "type": "tool_result",
                        "tool_use_id": block.id,
                        "content": result,
                        "is_error": is_error,
                    }
                )

            # 6. HAMMA natijani BITTA xabarda qaytaramiz.
            #    Ularni bo'lib yuborsangiz — model parallel asbob
            #    ishlatishni to'xtatadi. Bu keng tarqalgan xato.
            messages.append({"role": "user", "content": tool_results})
            self.memory.add_message("user", tool_results)

        return (
            final_text
            + f"\n\n[{config.MAX_STEPS} qadam limitiga yetdim va to'xtadim.]"
        )

    def close(self) -> None:
        self.memory.close()


def _short(value, limit: int = 70) -> str:
    """Asbob argumentlarini terminalda qisqa ko'rsatish uchun."""
    text = str(value)
    return text if len(text) <= limit else text[:limit] + "..."


# --- Terminal interfeysi -------------------------------------------------

BANNER = """\033[36m
  ┌──────────────────────────────────────────┐
  │  JARVIS · shaxsiy agent                  │
  │  /yordam · /xotira · /tozala · /chiqish  │
  └──────────────────────────────────────────┘\033[0m"""


def main() -> int:
    if not os.getenv("ANTHROPIC_API_KEY"):
        print("Xato: ANTHROPIC_API_KEY o'rnatilmagan.")
        print("  export ANTHROPIC_API_KEY=sk-ant-...")
        return 1

    print(BANNER)
    print(f"  model: {config.MODEL} · effort: {config.EFFORT}")
    print(f"  workspace: {config.WORKSPACE}\n")

    jarvis = Jarvis()
    try:
        while True:
            try:
                user_input = input("\033[32msiz >\033[0m ").strip()
            except (EOFError, KeyboardInterrupt):
                print()
                break

            if not user_input:
                continue

            if user_input in ("/chiqish", "/exit", "/quit"):
                break

            if user_input == "/yordam":
                print(
                    "\n  /xotira  — saqlangan faktlarni ko'rsatish"
                    "\n  /tozala  — suhbat tarixini o'chirish (faktlar qoladi)"
                    "\n  /chiqish — dasturdan chiqish\n"
                )
                continue

            if user_input == "/xotira":
                facts = jarvis.memory.all_facts(limit=100)
                if not facts:
                    print("\n  (xotira bo'sh)\n")
                else:
                    print()
                    for f in facts:
                        print(f"  {f['key']}: {f['value']}")
                    print()
                continue

            if user_input == "/tozala":
                n = jarvis.memory.clear_conversation()
                print(f"\n  {n} ta xabar o'chirildi. Faktlar saqlanib qoldi.\n")
                continue

            try:
                answer = jarvis.chat(user_input)
            except anthropic.RateLimitError:
                print("\n  Limitga yetdingiz. Bir oz kutib qayta urinib ko'ring.\n")
                continue
            except anthropic.APIConnectionError:
                print("\n  Tarmoqqa ulanib bo'lmadi. Internetni tekshiring.\n")
                continue
            except anthropic.APIStatusError as e:
                print(f"\n  API xatosi {e.status_code}: {e.message}\n")
                continue

            print(f"\n\033[36mjarvis >\033[0m {answer}\n")
    finally:
        jarvis.close()

    print("Xayr.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
