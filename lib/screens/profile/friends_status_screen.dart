import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../services/referral_service.dart';

/// Do'stlar holati — taklif qilingan do'stlar ro'yxati, progress va
/// (3 ta do'st a'zo bo'lgach) admin'ga mukofot so'rovi yuborish tugmasi.
class FriendsStatusScreen extends StatefulWidget {
  const FriendsStatusScreen({super.key});

  @override
  State<FriendsStatusScreen> createState() => _FriendsStatusScreenState();
}

class _FriendsStatusScreenState extends State<FriendsStatusScreen> {
  final _ref = ReferralService.instance;

  @override
  void initState() {
    super.initState();
    _ref.addListener(_onChanged);
    AppLocale.instance.addListener(_onChanged);
    // Admin so'rovni tasdiqlagan/rad etgan bo'lsa — holatni yangilaymiz
    // (tasdiqlansa hisoblagich 0 ga qaytadi).
    _syncAndNotify();
  }

  Future<void> _syncAndNotify() async {
    await _ref.syncStatus();
    if (!mounted) return;
    final result = _ref.lastResult;
    if (result == null) return;
    final loc = AppLocale.instance;
    final msg = result == 'approved'
        ? loc.t('friends_reward_approved')
        : '${loc.t('friends_reward_rejected')}${_ref.lastReason.isNotEmpty ? ': ${_ref.lastReason}' : ''}';
    _ref.clearLastResult();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: result == 'approved' ? AppColors.primary : AppColors.danger,
      ),
    );
  }

  @override
  void dispose() {
    _ref.removeListener(_onChanged);
    AppLocale.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _addFriend() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocale.instance.t('profile_invite_friend')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Do'st ismi"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocale.instance.t('common_cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(AppLocale.instance.t('common_save')),
          ),
        ],
      ),
    );
    if (name != null) {
      await _ref.inviteFriend(name);
    }
  }

  Future<void> _sendReward() async {
    await _ref.requestReward();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.instance.t('friends_reward_sent'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.instance;
    final friends = _ref.invitedFriends;

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text(loc.t('friends_title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Statistika
            FadeSlideIn(
              child: Row(
                children: [
                  _stat('${_ref.invitedCount}', loc.t('friends_invited')),
                  const SizedBox(width: 10),
                  _stat('${_ref.joinedCount}', loc.t('friends_joined')),
                  const SizedBox(width: 10),
                  _stat('${_ref.bonusDays}', loc.t('friends_bonus_days')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Mukofot so'rovi kartasi
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: _rewardCard(loc),
            ),
            const SizedBox(height: 20),
            // Do'stlar ro'yxati
            if (friends.isEmpty)
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: const BoxDecoration(
                            color: AppColors.surface, shape: BoxShape.circle),
                        child: const Icon(Icons.group_outlined,
                            color: AppColors.textSecondary, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(loc.t('friends_empty'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(friends.length, (i) {
                return FadeSlideIn(
                  delay: Duration(milliseconds: 140 + i * 50),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            friends[i].isNotEmpty ? friends[i][0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(friends[i],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreenBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(loc.t('friends_joined'),
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 220),
              child: OutlinedButton.icon(
                onPressed: _addFriend,
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: Text(loc.t('profile_invite_friend')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _rewardCard(AppLocale loc) {
    if (_ref.rewardRequested) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(loc.t('friends_reward_pending'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    if (_ref.isEligible) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF2BA94A)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.t('friends_reward_ready'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                onPressed: _sendReward,
                icon: const Icon(Icons.card_giftcard, size: 18),
                label: Text(loc.t('friends_reward_send')),
              ),
            ),
          ],
        ),
      );
    }

    // Hali 3 taga yetmagan
    final need = _ref.remainingForReward;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loc.t('friends_need_more').replaceAll('{n}', '$need'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
