import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Do'st taklif havolalarini (deep link) ushlaydi.
///
/// Qo'llab-quvvatlanadigan ko'rinishlar:
///   * `savin://invite/AZIZ2026`
///   * `https://savin.uz/i/AZIZ2026`
///
/// Havola bosilganda kod shu yerda saqlanadi va ro'yxatdan o'tish so'rovига
/// qo'shiladi. Ilova o'rnatilmagan bo'lsa brauzer foydalanuvchini Play
/// Marketga olib boradi (landing saytdagi `/i/<KOD>` sahifasi shu ishni
/// qiladi) — ilova o'rnatilib ochilgach havola qayta bosilsa kod keladi.
class DeepLinkService extends ChangeNotifier {
  DeepLinkService._internal();
  static final DeepLinkService instance = DeepLinkService._internal();

  static const _kPendingCode = 'pending_referral_code';

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  String? _pendingCode;

  /// Ro'yxatdan o'tishda ishlatiladigan taklif kodi (bo'lmasa `null`).
  String? get pendingCode => _pendingCode;

  /// Ilova endi ochilganda kelgan havola — "Sizni taklif qilishdi" ekranini
  /// bir marta ko'rsatish uchun ishlatiladi.
  String? justArrivedCode;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _pendingCode = prefs.getString(_kPendingCode);

    // Ilova havola orqali ishga tushgan bo'lsa
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) await _handle(initial, firstLaunch: true);
    } catch (_) {
      // Deep link qo'llab-quvvatlanmasa oddiy ishga tushish davom etadi
    }

    // Ilova ochiq turganda kelgan havolalar
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handle(uri, firstLaunch: false),
      onError: (_) {},
    );
  }

  Future<void> _handle(Uri uri, {required bool firstLaunch}) async {
    final code = extractCode(uri);
    if (code == null) return;
    justArrivedCode = code;
    await savePendingCode(code);
  }

  /// `savin://invite/<KOD>` yoki `https://savin.uz/i/<KOD>` dan kodni ajratadi.
  static String? extractCode(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    if (uri.scheme == 'savin') {
      // savin://invite/AZIZ2026 -> host = "invite", segments = ["AZIZ2026"]
      if (uri.host == 'invite' && segments.isNotEmpty) {
        return _clean(segments.first);
      }
      if (segments.length >= 2 && segments.first == 'invite') {
        return _clean(segments[1]);
      }
      return null;
    }

    // https://savin.uz/i/AZIZ2026
    if (segments.length >= 2 && (segments.first == 'i' || segments.first == 'invite')) {
      return _clean(segments[1]);
    }

    // ?code=AZIZ2026 (Play Market referrer bilan kelgan holat)
    final q = uri.queryParameters['code'];
    return q == null ? null : _clean(q);
  }

  static String? _clean(String raw) {
    final code = raw.trim().toUpperCase();
    return code.isEmpty ? null : code;
  }

  Future<void> savePendingCode(String code) async {
    _pendingCode = code;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPendingCode, code);
    } catch (_) {}
  }

  /// Ro'yxatdan o'tish tugagach chaqiriladi — kod bir marta ishlatiladi.
  Future<void> consume() async {
    _pendingCode = null;
    justArrivedCode = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPendingCode);
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
