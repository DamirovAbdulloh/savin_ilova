import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sevimli bizneslar (dizayn: "Sevimlilar").
///
/// Backendda hozircha sevimlilar endpointi yo'q, shuning uchun ro'yxat
/// qurilmada saqlanadi — ilova qayta ochilganda ham joyida qoladi.
class FavoritesService extends ChangeNotifier {
  FavoritesService._internal();
  static final FavoritesService instance = FavoritesService._internal();

  static const _kIds = 'favorite_business_ids';

  final Set<String> _ids = <String>{};

  Set<String> get ids => Set.unmodifiable(_ids);
  int get count => _ids.length;
  bool isFavorite(String id) => _ids.contains(id);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _ids
        ..clear()
        ..addAll(prefs.getStringList(_kIds) ?? const []);
      notifyListeners();
    } catch (_) {}
  }

  /// Qaytaradi: endi sevimlilardami (true = qo'shildi).
  Future<bool> toggle(String id) async {
    final added = !_ids.contains(id);
    if (added) {
      _ids.add(id);
    } else {
      _ids.remove(id);
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kIds, _ids.toList());
    } catch (_) {}
    return added;
  }
}
