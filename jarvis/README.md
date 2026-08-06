# Jarvis — shaxsiy AI agent

Bu — kompyuterda ish qila oladigan, xotirasi bor va mustaqil qaror qabul
qiladigan agentning **ishlaydigan yadrosi**. Ovozli "Jarvis" tizimlarining
asosida aynan shu turadi; ovoz — ustiga qo'shiladigan qatlam.

Kod o'qish uchun yozilgan: har bir fayl kichik va izohlangan.

---

## Ishga tushirish (5 daqiqa)

```bash
cd jarvis

# 1. Virtual muhit
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate

# 2. Kutubxona
pip install -r requirements.txt

# 3. API kaliti — console.anthropic.com dan olinadi
export ANTHROPIC_API_KEY=sk-ant-...

# 4. Ishga tushirish
python agent.py
```

Sinab ko'rish uchun birinchi savollar:

```
siz > hozir soat necha?
siz > workspace papkasida nima bor?
siz > menga test.txt fayl yasab, ichiga salom deb yoz
siz > men Flutter'da yozaman, buni eslab qol
siz > /xotira
```

Oxirgi buyruqdan keyin dasturni o'chirib qayta oching va so'rang:
`men qaysi tilda yozaman?` — eslab qolganini ko'rasiz.

---

## Fayllar

| Fayl | Vazifasi |
|---|---|
| `config.py` | Barcha sozlamalar: model, xarajat, shaxsiyat, xavfsizlik chegaralari |
| `memory.py` | Xotira (SQLite): suhbat tarixi + doimiy faktlar |
| `tools.py` | Agentning "qo'llari" — fayl, buyruq, vaqt, xotira asboblari |
| `agent.py` | Asosiy halqa + terminal interfeysi |

## Agent qanday ishlaydi

```
foydalanuvchi xabari
        ↓
  ┌─────────────────────────────────────┐
  │ 1. Xotiradan faktlarni qo'sh        │
  │ 2. Modelga yubor (tizim prompti +   │
  │    tarix + asboblar ro'yxati)       │
  │ 3. Model asbob chaqirdimi?          │
  │      ha  → tools.execute() → 2 ga   │
  │      yo'q → javobni qaytar          │
  └─────────────────────────────────────┘
```

`agent.py` dagi `chat()` funksiyasining ichi — shu. Boshqa hech qanday
sehr yo'q. Agentni "aqlli" qiladigan narsa — asboblar sifati, xotira va
tizim prompti, model emas.

## Xavfsizlik — buni o'chirmang

Uchta himoya qatlami bor:

1. **Sandbox** — agent faqat `workspace/` papkasi ichida fayl ko'ra va
   o'zgartira oladi. `tools.py` dagi `_safe_path()` buni ta'minlaydi.
2. **Ruxsat so'rash** — mavjud faylni o'chirish yoki xavfli buyruq
   bajarish oldidan sizdan so'raydi (`agent.py` → `_ask_permission`).
3. **Qadam limiti** — `MAX_STEPS` cheksiz halqadan himoya qiladi.

Agentni to'liq avtonom qilsangiz ham 2-qatlamni olib tashlamang — uni
Telegram'ga xabar yuborish yoki logga yozishga almashtiring.

## Xarajat

| Model | ID | Kirish $/1M | Chiqish $/1M |
|---|---|---|---|
| Claude Opus 5 | `claude-opus-5` | $5 | $25 |
| Claude Sonnet 5 | `claude-sonnet-5` | $3 | $15 |
| Claude Haiku 4.5 | `claude-haiku-4-5` | $1 | $5 |

Kundalik shaxsiy foydalanishda oyiga taxminan **$15–60**.

Kamaytirish yo'llari:
- `JARVIS_EFFORT=low` — oddiy ishlar uchun o'ylash chuqurligini kamaytirish
- `JARVIS_MODEL=claude-sonnet-5` — sifat deyarli o'sha, narx 5x arzon
- Tizim prompti allaqachon keshlangan (`cache_control`) — takroriy
  o'qish ~10 barobar arzon

Sozlamalar muhit o'zgaruvchilari orqali beriladi:

```bash
JARVIS_MODEL=claude-sonnet-5 JARVIS_EFFORT=low python agent.py
```

---

## Keyingi qadamlar — o'sish yo'li

Bu 1 va 2-bosqich (matnli agent + asboblar + xotira). Davomi:

**3-bosqich — yaxshiroq xotira.**
Faktlar soni yuzdan oshsa, `memory.recall()` dagi `LIKE` qidiruvi
yetarli bo'lmaydi. Vektor bazaga o'ting (`chromadb` yoki `sqlite-vec`) —
"o'xshash ma'noli" faktlarni topadi, faqat bir xil so'zni emas.

**4-bosqich — ovoz.**
- Nutq → matn: `openai-whisper` (lokal, bepul) yoki Deepgram (tez, pullik)
- Matn → nutq: ElevenLabs yoki `piper` (lokal)
- Wake word ("Jarvis" deb chaqirish): `pvporcupine`

Yig'ilishi: mikrofon → wake word → STT → `jarvis.chat()` → TTS. Ya'ni
`agent.py` dagi `input()` va `print()` ni almashtirasiz, xolos.

**5-bosqich — integratsiyalar.**
`tools.py` ga yangi asbob qo'shasiz: kalendar, pochta, Telegram, smart-uy.
Har biri — bitta funksiya + bitta sxema. Kalitlarni `.env` da saqlang,
hech qachon kodda emas.

**6-bosqich — kompyuterni boshqarish.**
Ekranni ko'rib, sichqoncha bosadigan agent. Bu computer-use rejimi bilan
qilinadi va **albatta Docker konteyner ichida** ishlashi kerak.

**7-bosqich — model tanlash.**
Har so'rovni Opus'ga yubormang. Oddiy savolni Haiku aniqlasin, murakkabini
Opus bajarsin. `config.FAST_MODEL` shu uchun tayyor turibdi.

---

## Bilib qo'yish foydali

- **Tool description eng muhim narsa.** Model qaysi asbobni qachon
  ishlatishni AYNAN tavsif matnidan biladi. Asbob noto'g'ri ishlatilsa,
  avval tavsifni yaxshilang — prompt emas.
- **Xatoni modelga qaytaring.** `tools.execute()` exception otmaydi,
  xato matnini qaytaradi. Model o'zi tuzatishga urinadi. Bu agentni
  ancha barqaror qiladi.
- **Barcha tool natijalarini bitta xabarda qaytaring.** Bo'lib yuborsangiz
  model parallel asbob ishlatishni to'xtatadi.
- **`response.content` ni to'liq saqlang.** Ichidagi "thinking" bloklarini
  o'zgartirmasdan qaytarish shart, aks holda API xato beradi.
- **`temperature` ishlatmang.** Opus 5 da bu parametr qabul qilinmaydi.
  Xulq-atvorni prompt orqali boshqaring.
