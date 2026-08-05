import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/constants.dart';

/// Bitta taklif qilingan do'st va uning faollik holati.
class ReferralFriend {
  final String id;
  final String name;
  final String phone;
  final String status; // 'pending' | 'active'
  final int activeDays;
  final int daysLeft;
  final int requiredDays;
  final DateTime? joinedAt;

  const ReferralFriend({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.activeDays,
    required this.daysLeft,
    required this.requiredDays,
    this.joinedAt,
  });

  bool get isActive => status == 'active';

  factory ReferralFriend.fromJson(Map<String, dynamic> json) {
    return ReferralFriend(
      id: '${json['id']}',
      name: (json['name'] ?? "Do'st").toString(),
      phone: (json['phone'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      activeDays: (json['active_days'] ?? 0) as int,
      daysLeft: (json['days_left'] ?? 0) as int,
      requiredDays: (json['required_days'] ?? 7) as int,
      joinedAt: DateTime.tryParse('${json['joined_at']}'),
    );
  }
}

/// Referal (do'st taklif qilish) holati — HAQIQIY backend ma'lumoti bilan.
///
/// Muhim qoida: do'st ro'yxatdan o'tishi taklifni to'liq qilmaydi. U bir
/// hafta davomida ilovaga kirib turishi kerak; shundan keyingina "Aktiv"
/// bo'ladi. 3 ta faol do'st yig'ilganda adminga 1 oylik obuna arizasi
/// yuboriladi.
class ReferralService extends ChangeNotifier {
  ReferralService._internal();
  static final ReferralService instance = ReferralService._internal();

  String _code = '';
  String _link = '';
  int _invitedCount = 0;
  int _activeCount = 0;
  int _pendingCount = 0;
  int _progress = 0;
  int _remainingForReward = 3;
  int _rewardRequired = 3;
  int _requiredDays = 7;
  int _bonusDays = 0;
  bool _canRequest = false;
  String? _requestStatus; // null | 'pending' | 'approved' | 'rejected'
  String _requestReason = '';
  List<ReferralFriend> _friends = const [];
  bool _loaded = false;

  String get code => _code;
  String get link => _link.isNotEmpty ? _link : 'https://savin.uz';
  int get invitedCount => _invitedCount;
  int get activeCount => _activeCount;
  int get pendingCount => _pendingCount;
  int get progress => _progress;
  int get remainingForReward => _remainingForReward;
  int get rewardRequired => _rewardRequired;
  int get requiredDays => _requiredDays;
  int get bonusDays => _bonusDays;
  bool get canRequest => _canRequest;
  bool get rewardRequested => _requestStatus == 'pending';
  String? get requestStatus => _requestStatus;
  String get requestReason => _requestReason;
  List<ReferralFriend> get friends => List.unmodifiable(_friends);
  bool get loaded => _loaded;

  /// Do'stlarga yuboriladigan matn (havola bilan).
  String get shareText =>
      "Men sizni Savin'ga taklif qilaman! Ro'yxatdan o'ting va 400+ joyda "
      "10–40% chegirmadan foydalaning.\n$link";

  /// Backenddan holatni oladi. Internet bo'lmasa oxirgi holat qoladi.
  Future<void> load() async {
    try {
      final res = await ApiClient.instance.dio.get(ApiConstants.referralOverview);
      final data = Map<String, dynamic>.from(res.data as Map);
      _code = (data['code'] ?? '').toString();
      _link = (data['link'] ?? '').toString();
      _invitedCount = (data['invited_count'] ?? 0) as int;
      _activeCount = (data['active_count'] ?? 0) as int;
      _pendingCount = (data['pending_count'] ?? 0) as int;
      _progress = (data['progress'] ?? 0) as int;
      _remainingForReward = (data['remaining_for_reward'] ?? 3) as int;
      _rewardRequired = (data['reward_required'] ?? 3) as int;
      _requiredDays = (data['required_days'] ?? 7) as int;
      _bonusDays = (data['bonus_days'] ?? 0) as int;
      _canRequest = (data['can_request'] ?? false) as bool;
      _requestStatus = data['request_status'] as String?;
      _requestReason = (data['request_reason'] ?? '').toString();
      _friends = ((data['friends'] as List?) ?? const [])
          .map((e) => ReferralFriend.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _loaded = true;
      notifyListeners();
    } catch (_) {
      // Internet/server yo'q — mavjud holat saqlanadi
    }
  }

  /// Ilova ochilganda "men faolman" signali. Taklif qilingan do'stning
  /// 7 kunlik hisobiga shu orqali kun qo'shiladi.
  Future<void> ping() async {
    try {
      await ApiClient.instance.dio.post(ApiConstants.activityPing);
    } catch (_) {}
  }

  /// 3 ta faol do'st yig'ilganda adminga 1 oylik obuna arizasini yuborish.
  /// Xato bo'lsa sabab matni qaytadi, muvaffaqiyatli bo'lsa `null`.
  Future<String?> requestReward() async {
    try {
      await ApiClient.instance.dio.post(ApiConstants.referralRequest);
      await load();
      return null;
    } catch (e) {
      String message = "So'rovni yuborib bo'lmadi. Keyinroq urinib ko'ring.";
      try {
        final data = (e as dynamic).response?.data;
        if (data is Map && data['detail'] != null) message = data['detail'].toString();
      } catch (_) {}
      return message;
    }
  }

  /// Admin qarorini ko'rsatgandan keyin bayroqni tozalash.
  void clearLastResult() {
    if (_requestStatus == 'approved' || _requestStatus == 'rejected') {
      _requestStatus = null;
      _requestReason = '';
      notifyListeners();
    }
  }
}
