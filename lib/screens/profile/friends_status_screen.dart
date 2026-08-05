import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_builder.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../services/referral_service.dart';
import 'referral_screen.dart';

/// "Do'stlar holati" (dizayn: Referal — Do'stlar / Empty — Friends).
///
/// Har bir do'st uchun ko'rsatiladi: u faollashganmi ("Aktiv") yoki
/// faollashishi uchun yana necha kun ilovaga kirishi kerak. 3 ta faol
/// do'st yig'ilganda adminga 1 oylik obuna arizasi yuboriladi.
class FriendsStatusScreen extends StatefulWidget {
  const FriendsStatusScreen({super.key});

  @override
  State<FriendsStatusScreen> createState() => _FriendsStatusScreenState();
}

class _FriendsStatusScreenState extends State<FriendsStatusScreen> {
  final _ref = ReferralService.instance;
  int _tab = 0; // 0 = hammasi, 1 = aktiv, 2 = kutilmoqda
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _ref.addListener(_onChanged);
    _ref.load();
  }

  @override
  void dispose() {
    _ref.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  List<ReferralFriend> get _visible {
    final all = _ref.friends;
    return switch (_tab) {
      1 => all.where((f) => f.isActive).toList(),
      2 => all.where((f) => !f.isActive).toList(),
      _ => all,
    };
  }

  Future<void> _remind(ReferralFriend friend) async {
    final text = Uri.encodeComponent(
      "Salom${friend.name.isEmpty ? '' : ', ${friend.name}'}! Savin ilovasiga "
      "kirib turishni unutmang — faollashishga yana ${friend.daysLeft} kun qoldi.",
    );
    final uri = friend.phone.isNotEmpty
        ? Uri.parse('sms:${friend.phone}?body=$text')
        : Uri.parse(
            'https://t.me/share/url?url=${Uri.encodeComponent(_ref.link)}&text=$text');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.instance.t('help_link_error'))),
      );
    }
  }

  Future<void> _requestReward() async {
    setState(() => _sending = true);
    final error = await _ref.requestReward();
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? AppLocale.instance.t('friends_reward_sent')),
        backgroundColor: error == null ? AppColors.primary : AppColors.danger,
      ),
    );
  }

  void _openInvite() {
    Navigator.of(context).push(AppPageRoute(page: const ReferralScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(loc.t('friends_title')),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _ref.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                // Uchta ko'rsatkich: taklif qildim / a'zo bo'lgan / kun bonus
                FadeSlideIn(
                  child: Row(
                    children: [
                      _stat('${_ref.invitedCount}', loc.t('friends_invited')),
                      _stat('${_ref.activeCount}', loc.t('friends_joined'),
                          highlight: true),
                      _stat('${_ref.bonusDays}', loc.t('friends_bonus_days')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_ref.friends.isEmpty)
                  _emptyState(loc)
                else ...[
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: Row(
                      children: [
                        _tabChip(0, loc.t('friends_tab_all'), _ref.invitedCount),
                        const SizedBox(width: 8),
                        _tabChip(1, loc.t('friends_tab_active'), _ref.activeCount),
                        const SizedBox(width: 8),
                        _tabChip(2, loc.t('friends_tab_pending'), _ref.pendingCount),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _visible.length; i++)
                    FadeSlideIn(
                      key: ValueKey(_visible[i].id),
                      delay: Duration(milliseconds: 120 + i * 60),
                      child: _friendTile(_visible[i], loc),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc
                                .t('friends_rule')
                                .replaceAll('{n}', '${_ref.requiredDays}'),
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                if (_ref.canRequest || _ref.rewardRequested)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _sending || _ref.rewardRequested ? null : _requestReward,
                      child: Text(_ref.rewardRequested
                          ? loc.t('friends_reward_pending')
                          : loc.t('friends_reward_send')),
                    ),
                  ),
                if (_ref.requestStatus == 'rejected' &&
                    _ref.requestReason.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${loc.t('friends_reward_rejected')}: ${_ref.requestReason}',
                      style: const TextStyle(fontSize: 12, color: AppColors.danger),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _openInvite,
                  icon: const Icon(Icons.person_add_alt, size: 18),
                  label: Text(loc.t('ref_invite_more')),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '${loc.t('ref_your_code')}: ${_ref.code}',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(AppLocale loc) {
    return FadeSlideIn(
      delay: const Duration(milliseconds: 80),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('🎁', style: TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 18),
            Text(loc.t('friends_empty'),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(loc.t('friends_empty_sub'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _openInvite,
              child: Text(loc.t('friends_invite_btn')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, {bool highlight = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color:
                        highlight ? AppColors.primary : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(int index, String label, int count) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent),
          ),
          alignment: Alignment.center,
          child: Text('$label $count',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      selected ? AppColors.primary : AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _friendTile(ReferralFriend f, AppLocale loc) {
    final initial = f.name.trim().isEmpty ? '?' : f.name.trim()[0].toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: f.isActive ? AppColors.primary : AppColors.surface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(initial,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: f.isActive
                            ? Colors.white
                            : AppColors.textSecondary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (f.phone.isNotEmpty)
                      Text(f.phone,
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: f.isActive
                      ? AppColors.accentGreenBg
                      : AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  f.isActive
                      ? loc.t('friends_status_active')
                      : loc.t('friends_status_pending'),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: f.isActive ? AppColors.primary : AppColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Faollik jarayoni: necha kun kirdi / yana necha kun kerak
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: f.requiredDays == 0
                  ? 1
                  : (f.activeDays / f.requiredDays).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(
                  f.isActive ? AppColors.primary : AppColors.warning),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  f.isActive
                      ? loc.t('friends_active_done')
                      : loc
                          .t('friends_days_left')
                          .replaceAll('{n}', '${f.daysLeft}'),
                  style: TextStyle(
                      fontSize: 11.5,
                      color: f.isActive
                          ? AppColors.primary
                          : AppColors.textSecondary),
                ),
              ),
              Text(
                loc
                    .t('friends_active_progress')
                    .replaceAll('{a}', '${f.activeDays}')
                    .replaceAll('{b}', '${f.requiredDays}'),
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textSecondary),
              ),
              if (!f.isActive) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _remind(f),
                  child: Row(
                    children: [
                      Text(loc.t('friends_remind'),
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      const Icon(Icons.north_east,
                          size: 12, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
