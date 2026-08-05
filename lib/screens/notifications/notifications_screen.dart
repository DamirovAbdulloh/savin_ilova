import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/i18n/locale_builder.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String kind; // general | discount | referral | membership
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: '${json['id']}',
        title: (json['title'] ?? '').toString(),
        body: (json['body'] ?? '').toString(),
        kind: (json['kind'] ?? 'general').toString(),
        isRead: (json['is_read'] ?? false) as bool,
        createdAt: DateTime.tryParse('${json['created_at']}'),
      );
}

/// Bildirishnomalar / Xabarlar (dizayn: "Bildirishnomalar — Inbox" va
/// "Bildirishnomalar — Empty").
///
/// Kassir chegirma qo'llaganda, do'st ro'yxatdan o'tganda yoki referal
/// arizasi ko'rib chiqilganda backend shu ro'yxatga yozadi.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = const [];
  bool _loading = true;
  bool _failed = false;
  int _tab = 0; // 0 = hammasi, 1 = o'qilmagan

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final res = await ApiClient.instance.dio.get(ApiConstants.notifications);
      final data = res.data;
      final list = data is List ? data : (data['results'] as List? ?? []);
      if (!mounted) return;
      setState(() {
        _items = list
            .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiClient.instance.dio.post(ApiConstants.notificationsReadAll);
    } catch (_) {
      // Internet yo'q bo'lsa ham ro'yxatni qayta yuklaymiz
    }
    await _load();
  }

  List<AppNotification> get _visible =>
      _tab == 1 ? _items.where((n) => !n.isRead).toList() : _items;

  int get _unread => _items.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(loc.t('notif_title')),
          actions: [
            if (_unread > 0)
              TextButton(
                onPressed: _markAllRead,
                child: Text(loc.t('notif_mark_all'),
                    style: const TextStyle(fontSize: 12.5)),
              ),
          ],
        ),
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2.5))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? _emptyOrError(loc)
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          children: [
                            Row(
                              children: [
                                _tabChip(0, loc.t('notif_tab_all'), _items.length),
                                const SizedBox(width: 8),
                                _tabChip(1, loc.t('notif_tab_unread'), _unread),
                              ],
                            ),
                            const SizedBox(height: 14),
                            for (var i = 0; i < _visible.length; i++)
                              FadeSlideIn(
                                key: ValueKey(_visible[i].id),
                                delay: Duration(milliseconds: i * 50),
                                child: _tile(_visible[i]),
                              ),
                          ],
                        ),
                ),
        ),
      ),
    );
  }

  Widget _emptyOrError(dynamic loc) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
                color: AppColors.surface, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(_failed ? Icons.wifi_off : Icons.notifications_off_outlined,
                size: 44, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 22),
        Text(_failed ? 'Hech narsa yuklanmadi' : loc.t('notif_empty'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          _failed
              ? "Internet aloqangizni tekshirib qayta urinib ko'ring"
              : loc.t('notif_empty_sub'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        if (_failed) ...[
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _load,
              child: const Text('Qayta urinish'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _tabChip(int index, String label, int count) {
    final selected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border:
              Border.all(color: selected ? AppColors.primary : Colors.transparent),
        ),
        child: Text('$label $count',
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textSecondary)),
      ),
    );
  }

  Widget _tile(AppNotification n) {
    final (icon, color) = switch (n.kind) {
      'discount' => (Icons.local_offer, AppColors.primary),
      'referral' => (Icons.card_giftcard, AppColors.warning),
      'membership' => (Icons.workspace_premium, AppColors.primaryDark),
      _ => (Icons.notifications, AppColors.textSecondary),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: n.isRead ? Colors.white : AppColors.primaryLight,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(n.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13.5)),
                    ),
                    if (n.createdAt != null)
                      Text(_time(n.createdAt!),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                if (n.body.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(n.body,
                      style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _time(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    if (sameDay) return '$hh:$mm';
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}';
  }
}
