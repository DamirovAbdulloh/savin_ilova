import 'package:geolocator/geolocator.dart';

/// Foydalanuvchining haqiqiy GPS joylashuvi bilan ishlash uchun.
///
/// MUHIM — HALOL IZOH: bu haqiqiy GPS koordinatasini oladi va bizneslar
/// bilan orasidagi masofani to'g'ri hisoblaydi (Google Maps'dagidek "necha
/// km narida" ko'rsatish uchun yetarli). Lekin xarita EKRANI hamon o'zining
/// stilizatsiya qilingan (chizilgan) ko'rinishida qoladi — chunki haqiqiy
/// yo'l/bino tasvirlari bo'lgan xarita (Google Maps tile'lari) uchun
/// to'lovli API kalit kerak, hozircha mavjud emas. Ya'ni: masofa/joylashuv
/// HAQIQIY, lekin xaritaning fon rasmi hali ham chizilgan taxminiy ko'rinish.
class LocationService {
  LocationService._internal();
  static final LocationService instance = LocationService._internal();

  Position? _lastKnown;
  Position? get lastKnown => _lastKnown;

  /// Ruxsat so'raydi va joriy joylashuvni qaytaradi. Ruxsat berilmasa yoki
  /// GPS o'chirilgan bo'lsa `null` qaytaradi — chaqiruvchi tomon buni
  /// "joylashuv mavjud emas" holati sifatida ishlatishi kerak.
  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _lastKnown = position;
      return position;
    } catch (_) {
      return null;
    }
  }

  /// Ikki koordinata orasidagi masofa (km, 1 xonali aniqlik bilan).
  double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    final meters = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    return (meters / 1000 * 10).round() / 10;
  }

  String formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
  }

  /// Berilgan markaz atrofida lat/lng'ni taxminiy ekran nisbiy
  /// koordinatasiga (0..1) proyeksiya qiladi — xarita ekranidagi pinlarni
  /// haqiqiy nisbiy joylashuvga mos joylashtirish uchun.
  static ({double x, double y}) projectRelative({
    required double lat,
    required double lng,
    required double centerLat,
    required double centerLng,
    double spanDegrees = 0.09,
  }) {
    final dx = (lng - centerLng) / spanDegrees;
    final dy = (lat - centerLat) / spanDegrees;
    final x = (0.5 + dx).clamp(0.06, 0.94).toDouble();
    // Ekranda shimol yuqorida bo'lgani uchun kenglik (lat) teskari o'qiladi
    final y = (0.5 - dy).clamp(0.12, 0.82).toDouble();
    return (x: x, y: y);
  }
}
