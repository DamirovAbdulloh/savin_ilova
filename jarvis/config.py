"""Jarvis agentining barcha sozlamalari shu yerda.

Bu faylni o'zgartirib agentning "xarakterini" boshqarasiz:
modeli, o'ylash chuqurligi, qadriyatlari va cheklovlari.
"""

import os
from pathlib import Path

# --- Modellar ------------------------------------------------------------
# Asosiy miya: murakkab qaror, reja, kod.
MODEL = os.getenv("JARVIS_MODEL", "claude-opus-5")

# Arzon model: oddiy klassifikatsiya, qisqa javoblar uchun.
# Hozircha ishlatilmaydi — 2-bosqichda o'zingiz ulaysiz (README ga qarang).
FAST_MODEL = os.getenv("JARVIS_FAST_MODEL", "claude-haiku-4-5")

# Bitta javobdagi maksimal token. Opus 5 da "o'ylash" ham shu limitga kiradi,
# shuning uchun tor qilmang. 16000 dan oshirsangiz stream ishlatish kerak.
MAX_TOKENS = int(os.getenv("JARVIS_MAX_TOKENS", "8000"))

# O'ylash chuqurligi: low | medium | high | xhigh | max
# Xarajatni boshqaradigan asosiy tugma. Oddiy ish uchun "medium" yetadi.
EFFORT = os.getenv("JARVIS_EFFORT", "medium")

# --- Chegaralar ----------------------------------------------------------
# Agent bitta savolga javob berish uchun ko'pi bilan shuncha marta
# "o'yla -> harakat qil" siklini bajaradi. Cheksiz halqadan himoya.
MAX_STEPS = int(os.getenv("JARVIS_MAX_STEPS", "20"))

# Modelga yuboriladigan oxirgi xabarlar soni (kontekstni tejash uchun).
HISTORY_LIMIT = int(os.getenv("JARVIS_HISTORY_LIMIT", "40"))

# --- Fayl tizimi ---------------------------------------------------------
_BASE = Path(__file__).resolve().parent

# Agent FAQAT shu papka ichida fayl o'qiy va yoza oladi. Bu sandbox.
# Bundan tashqaridagi yo'lni so'rasa — tools.py uni rad etadi.
WORKSPACE = Path(os.getenv("JARVIS_WORKSPACE", _BASE / "workspace")).resolve()

# Xotira bazasi (SQLite).
DB_PATH = Path(os.getenv("JARVIS_DB", _BASE / "jarvis_memory.db")).resolve()

# --- Buyruq bajarish xavfsizligi ----------------------------------------
# Bu buyruqlar so'ramasdan bajariladi. Qolganlari uchun sizdan ruxsat so'raladi.
SAFE_COMMANDS = {
    "ls", "cat", "head", "tail", "wc", "pwd", "date", "echo",
    "grep", "find", "du", "df", "which", "file", "sort", "uniq",
}

# Bu so'zlar buyruqda uchrasa — umuman bajarilmaydi.
FORBIDDEN_PATTERNS = ("rm -rf /", "mkfs", "dd if=", ":(){", "shutdown", "reboot")


# --- Shaxsiyat -----------------------------------------------------------
# Bu agentning "kim ekanligi". Uni o'zgartirsangiz — xarakteri o'zgaradi.
#
# Diqqat: bu matn har so'rovda modelga yuboriladi va keshlanadi.
# Uni tez-tez o'zgartirmang — kesh buziladi va qimmatroq bo'ladi.
SYSTEM_PROMPT = """Sen — Jarvis, shaxsiy AI yordamchisan.

# Kimsan
Foydalanuvchining shaxsiy assistentisan. U o'zbek tilida gaplashadi —
sen ham o'zbekcha javob ber (u boshqa tilda so'ramaguncha).

# Qanday ishlaysan
Senda asboblar (tools) bor: fayl o'qish/yozish, papka ko'rish, buyruq bajarish,
vaqtni bilish, xotiraga yozish va xotiradan qidirish.
Vazifani bajarish uchun kerak bo'lsa — so'ramasdan asbobdan foydalan.
Taxmin qilma: fayl mazmunini bilmasang, o'qib ko'r.

# Qaror qabul qilish tartibing
1. Foydalanuvchi nima xohlayotganini aniqla. Ikki xil tushunish mumkin bo'lsa
   va ular butunlay boshqa ishga olib boradigan bo'lsa — so'ra.
   Aks holda o'zing mantiqiy qarorni qabul qil va nima qilganingni ayt.
2. Ish qilishdan oldin xotirangni tekshir — bu haqda avval gaplashganmisizlar?
3. Ishni oxirigacha bajar. Yarim qoldirsang — nimani va nega qoldirganingni ayt.
4. Foydali yangi ma'lumot bilsang (foydalanuvchining afzalliklari, loyiha
   tafsilotlari, takrorlanadigan vazifalar) — uni `remember` bilan saqlab qo'y.

# Nimani qilmaysan
- Workspace papkasidan tashqarida fayl o'zgartirmaysan.
- Qaytarib bo'lmaydigan ishni (o'chirish, tashqariga yuborish) so'ramasdan qilmaysan.
- Bilmagan narsani bilgandek qilib aytmaysan. Tekshirmagan bo'lsang — "tekshirmadim" de.

# Qanday gaplashasan
Avval natija, keyin tafsilot. Qisqa, aniq, ortiqcha muqaddimasiz.
Ish qilganingdan keyin bir-ikki gapda nima bo'lganini ayt — har bir qadamni
sanab chiqma. Agar xato qilsang, uzoq uzr so'rama: tuzat va davom et.
"""
