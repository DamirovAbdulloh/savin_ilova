import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/constants.dart';

/// Referal (do'st taklif qilish) holatini boshqaradi.
///
/// 1-bosqich: taklif qilingan do'stlar va mukofot so'rovi holati qurilmada
/// (shared_preferences) saqlanadi. 2-bosqich: bu ma'lumot backend bilan
/// sinxronlanadi va "mukofot so'rovi" admin backendga POST qilinadi
/// (admin panelning "So'rovlar" bo'limida ko'rinadi).
class ReferralService extends ChangeNotifier {
  ReferralService._internal();
  static final ReferralService instance = ReferralService._internal();

  static const _kFriends = 'referral_invited_friends';
  static const _kRequested = 'referral_reward_requested';

  final List<String> _invitedFriends = [];
  bool _rewardRequested = false;

  // Backend'dagi oxirgi so'rov natijasi (sinxronlangandan keyin):
  // null | 'approved' | 'rejected'. 'rejected' bo'lsa _lastReason to'ladi.
  String? _lastResult;
  String _lastReason = '';

  String? get lastResult => _lastResult;
  String get lastReason => _lastReason;

  List<String> get invitedFriends => List.unmodifiable(_invitedFriends);
  int get invitedCount => _invitedFriends.length;

  /// 1-bosqichda "a'zo bo'lgan" do'stlar soni taklif qilinganlarga teng deb
  /// olinadi (haqiqiy tasdiq 2-bosqichda backenddan keladi).
  int get joinedCount => _invitedFriends.length;

  /// Har 3 ta do'st uchun 1 oy (30 kun) bonus.
  int get bonusDays => (joinedCount ~/ 3) * 30;

  /// Mukofot so'rovini yuborish mumkinmi? (kamida 3 ta do'st a'zo bo'lgan)
  bool get isEligible => joinedCount >= 3;

  bool get rewardRequested => _rewardRequested;

  int get remainingForReward {
    final left = 3 - (joinedCount % 3);
    return left == 3 ? 0 : left;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _invitedFriends
        ..clear()
        ..addAll(prefs.getStringList(_kFriends) ?? const []);
      _rewardRequested = prefs.getBool(_kRequested) ?? false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> inviteFriend(String name) async {
    final trimmed = name.trim();
    _invitedFriends.add(trimmed.isEmpty ? "Do'st ${_invitedFriends.length + 1}" : trimmed);
    notifyListeners();
    await _persist();
  }

  /// Admin'ga referal mukofoti so'rovini yuborish.
  /// Backendga (savin_django /referral/request/) POST qiladi — u yerda so'rov
  /// saqlanadi va admin panelning "So'rovlar" bo'limida ko'rinadi.
  Future<void> requestReward() async {
    if (!isEligible) return;
    try {
      await ApiClient.instance.dio.post(ApiConstants.referralRequest, data: {
        'invited_count': joinedCount,
      });
    } catch (_) {
      // Internet/server bo'lmasa ham mahalliy holatni belgilaymiz —
      // foydalanuvchi qayta urinishi shart bo'lmasin (best-effort).
    }
    _rewardRequested = true;
    notifyListeners();
    await _persist();
  }

  /// Backend'dagi so'rov holatini tekshiradi. Admin TASDIQLAGAN bo'lsa —
  /// mukofot berilgan, referal hisoblagichi 0 ga qaytadi (yangi tsikl).
  /// RAD ETILGAN bo'lsa — sabab saqlanadi va foydalanuvchi qayta so'rov
  /// yubora oladi.
  Future<void> syncStatus() async {
    if (!_rewardRequested) return;
    try {
      final res = await ApiClient.instance.dio.get(ApiConstants.referralStatus);
      final status = res.data['status'] as String?;
      if (status == 'approved') {
        _invitedFriends.clear(); // 3/3 -> 0/3 (mukofot olindi)
        _rewardRequested = false;
        _lastResult = 'approved';
        _lastReason = '';
        notifyListeners();
        await _persist();
      } else if (status == 'rejected') {
        _rewardRequested = false;
        _lastResult = 'rejected';
        _lastReason = (res.data['reason'] as String?) ?? '';
        notifyListeners();
        await _persist();
      }
    } catch (_) {
      // internet/server bo'lmasa — jim o'tkazamiz
    }
  }

  void clearLastResult() {
    _lastResult = null;
    _lastReason = '';
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kFriends, _invitedFriends);
      await prefs.setBool(_kRequested, _rewardRequested);
    } catch (_) {}
  }
}
