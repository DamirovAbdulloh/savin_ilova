/// Backend bilan bog'liq global sozlamalar.
///
/// Manzil kodga qotirilmagan — build vaqtida `--dart-define` orqali
/// almashtiriladi, shuning uchun bitta kod bazasi har qanday muhitda ishlaydi:
///
///   flutter run   --dart-define=SAVIN_API_BASE_URL=http://10.0.2.2:8000/api/v1/mobile
///   flutter build --dart-define=SAVIN_API_BASE_URL=https://staging.example.com/api/v1/mobile
///
/// Lokal test uchun manzil tanlash:
/// - Android emulator: http://10.0.2.2:8000  (localhost o'rniga)
/// - Haqiqiy telefon (USB): `adb reverse tcp:8000 tcp:8000` + http://127.0.0.1:8000
/// - Haqiqiy telefon (WiFi): http://<kompyuter-LAN-IP>:8000
///
/// Hech narsa berilmasa — production (Railway) manzili ishlatiladi.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'SAVIN_API_BASE_URL',
    defaultValue: 'https://savin-backend-production.up.railway.app/api/v1/mobile',
  );

  // Auth
  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String tokenRefresh = '/auth/token/refresh/';
  static const String me = '/me/';

  // Businesses / Categories
  static const String categories = '/categories/';
  static const String businesses = '/businesses/';

  // Hamyon (Wallet) — haqiqiy tranzaksiyalar backenddan
  static const String transactions = '/transactions/';
  static const String transactionStats = '/transactions/stats/';

  // Notifications
  static const String notifications = '/notifications/';

  // Premium a'zolik
  static const String membershipActivate = '/membership/activate/';

  // Referal mukofot so'rovi
  static const String referralRequest = '/referral/request/';
  static const String referralStatus = '/referral/status/';

  // Kassaga aytiladigan 4 xonali kod (QR o'rniga) — har 5 daqiqada yangilanadi
  static const String redeemCode = '/redeem-code/';
}
