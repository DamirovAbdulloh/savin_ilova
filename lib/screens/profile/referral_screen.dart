import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_builder.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../models/user.dart';
import '../../services/referral_service.dart';
import 'friends_status_screen.dart';

/// Do'stlarni taklif qilish (dizayn: "Referal — Main").
///
/// Taklif kodi va havolasi backenddan keladi. Havola do'stga yuborilganda:
/// bosilsa ilova ochiladi, ilova yo'q bo'lsa Play Market ochiladi. Do'st
/// ro'yxatdan o'tsa taklif biriktiriladi, ammo TO'LIQ hisoblanishi uchun u
/// bir hafta davomida ilovaga kirib turishi kerak.
class ReferralScreen extends StatefulWidget {
  final AppUser? user;
  const ReferralScreen({super.key, this.user});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _ref = ReferralService.instance;
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

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _ref.link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocale.instance.t('ref_link_copied'))),
    );
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _ref.code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocale.instance.t('ref_code_copied'))),
    );
  }

  Future<void> _shareTo(String app) async {
    final text = Uri.encodeComponent(_ref.shareText);
    final link = Uri.encodeComponent(_ref.link);
    final url = switch (app) {
      'telegram' => 'https://t.me/share/url?url=$link&text=$text',
      'whatsapp' => 'https://wa.me/?text=$text',
      _ => _ref.link,
    };
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      await _copyLink();
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

  String get _rewardHint {
    final loc = AppLocale.instance;
    final left = _ref.remainingForReward;
    if (left <= 0) return loc.t('friends_reward_ready');
    return loc.t('friends_need_more').replaceAll('{n}', '$left');
  }

  @override
  Widget build(BuildContext context) {
    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(loc.t('ref_title')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).push(
                AppPageRoute(page: const FriendsStatusScreen()),
              ),
              child: Text(loc.t('friends_title')),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _ref.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                FadeSlideIn(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, Color(0xFF2BA94A)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const Text('🎁', style: TextStyle(fontSize: 26)),
                        ),
                        const SizedBox(height: 14),
                        Text(loc.t('ref_invite_title'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(loc.t('ref_invite_sub'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Text(loc.t('ref_your_code'),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5)),
                ),
                const SizedBox(height: 8),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _ref.code.isEmpty ? '—' : _ref.code,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _ref.code.isEmpty ? null : _copyCode,
                          icon: const Icon(Icons.copy, size: 16),
                          label: Text(loc.t('ref_copy')),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: InkWell(
                    onTap: _copyLink,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_ref.link,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12)),
                          ),
                          const Icon(Icons.copy, size: 14, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(loc.t('ref_progress'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('${_ref.progress}/${_ref.rewardRequired}',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            for (var i = 0; i < _ref.rewardRequired; i++) ...[
                              if (i > 0) _progressLine(filled: i < _ref.progress),
                              _friendAvatar(_initialAt(i), filled: i < _ref.progress),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Text('🎁', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_rewardHint,
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc
                              .t('friends_rule')
                              .replaceAll('{n}', '${_ref.requiredDays}'),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_ref.canRequest || _ref.rewardRequested) ...[
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _sending || _ref.rewardRequested ? null : _requestReward,
                        child: Text(_ref.rewardRequested
                            ? loc.t('friends_reward_pending')
                            : loc.t('friends_reward_send')),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 220),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _shareTo('telegram'),
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: Text(loc.t('ref_send_friends')),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 260),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareTo('telegram'),
                          icon: const Icon(Icons.send, size: 16),
                          label: const Text('Telegram'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareTo('whatsapp'),
                          icon: const Icon(Icons.chat, size: 16),
                          label: const Text('WhatsApp'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyLink,
                          icon: const Icon(Icons.more_horiz, size: 16),
                          label: const Text('Boshqa'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _initialAt(int index) {
    // Progressda faqat FAOL do'stlar ko'rsatiladi (mukofotga shular kiradi)
    final active = _ref.friends.where((f) => f.isActive).toList();
    if (index >= active.length) return null;
    final n = active[index].name.trim();
    return n.isEmpty ? null : n[0].toUpperCase();
  }

  Widget _friendAvatar(String? initial, {required bool filled}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: filled ? AppColors.primary : AppColors.border.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: initial != null
          ? Text(initial,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700))
          : const Icon(Icons.add, color: AppColors.textSecondary, size: 18),
    );
  }

  Widget _progressLine({required bool filled}) {
    return Expanded(
      child: Container(
        height: 2,
        color: filled ? AppColors.primary : AppColors.border,
      ),
    );
  }
}
