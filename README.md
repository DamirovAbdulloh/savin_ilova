# Savin — Flutter Mobile App (1-bosqich)

Bu paket **to'liq Flutter loyiha emas**, balki Flutter loyihasining `lib/` papkasi va `pubspec.yaml` fayli — chunki `android/`, `ios/` kabi platforma fayllarini faqat Flutter SDK o'zi generatsiya qila oladi (bu muhitda Flutter SDK yo'q).

## Nima qilingan (1-bosqich)

- ✅ Loyiha arxitekturasi (`core/`, `models/`, `services/`, `screens/`)
- ✅ Django backendingiz bilan ishlaydigan API client (JWT + avto-refresh)
- ✅ Auth oqimi: ism → telefon → SMS kod (backend: `/auth/register/`, `/auth/login/`)
- ✅ Til tanlash + Onboarding (3 slayd)
- ✅ Asosiy navigatsiya: Asosiy, Katalog, QR, Hamyon, Profil
- ✅ Savin brend dizayni (yashil rang palitrasi, Figma'ga mos)

## Keyingi bosqichlarda qo'shiladi (aytsangiz davom ettiraman)

- Pricing/Membership va to'lov ekranlari (Click/Payme)
- Xarita (Google Maps) to'liq integratsiyasi
- Hamyon — grafik va tarix (fl_chart bilan)
- Referal va Bildirishnomalar
- Sozlamalar, akkauntni o'chirish
- Ruxsatlar (bildirishnoma, lokatsiya) oqimi

## O'rnatish qadamlar

1. **Flutter SDK** o'rnating (agar hali qilmagan bo'lsangiz): https://docs.flutter.dev/get-started/install

2. Android Studio yoki terminalda yangi bo'sh Flutter loyiha yarating:
   ```
   flutter create savin_app
   ```

3. Yangi yaratilgan `savin_app` papkasidagi `lib/` papkasi va `pubspec.yaml` faylini **shu paketdagilar bilan almashtiring** (ustidan yozing):
   ```
   savin_app/
     ├── android/       ← flutter create yaratgani, TEGMANG
     ├── ios/           ← flutter create yaratgani, TEGMANG
     ├── lib/           ← BU PAKETDAGI lib/ bilan almashtiring
     └── pubspec.yaml   ← BU PAKETDAGI pubspec.yaml bilan almashtiring
   ```

4. Paketlarni o'rnating:
   ```
   cd savin_app
   flutter pub get
   ```

5. `lib/core/constants.dart` faylida `baseUrl` ni tekshiring:
   - Android emulyator uchun: `http://10.0.2.2:8000/api/v1` (hozir shu turibdi)
   - Haqiqiy telefon uchun: kompyuteringiz IP manzili, masalan `http://192.168.1.5:8000/api/v1`

6. Django backendni ishga tushiring:
   ```
   python manage.py runserver 0.0.0.0:8000
   ```

7. Flutter'ni ishga tushiring:
   ```
   flutter run
   ```

## Muhim eslatmalar

- `google_maps_flutter` paketi qo'shilgan, lekin Xarita ekrani hali to'liq ulanmagan (keyingi bosqichda). Agar hozir kerak bo'lmasa, `pubspec.yaml`'dan olib tashlashingiz mumkin.
- OTP (SMS kod) tasdiqlash UI tayyor, lekin backendda haqiqiy SMS yuborish hali ulanmagan (`README.md`da backend tomonda ham qayd etilgan: `pyotp` yoki SMS-provayder kerak).
- Barcha matnlar backend tuzilishiga mos — agar API javob formatini o'zgartirsangiz, `lib/services/auth_service.dart` va `lib/models/user.dart` fayllarini moslashtirish kerak bo'ladi.

Savol tug'ilsa yoki keyingi ekranlarni (Pricing, Xarita, Referal va h.k.) qo'shishimni xohlasangiz — ayting, davom ettiraman.
