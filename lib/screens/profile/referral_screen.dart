import 'package:flutter/material.dart';

import '../../core/i18n/locale_builder.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../models/user.dart';
import '../../services/referral_service.dart';
import 'friends_status_screen.dart';

/// Do'stlarni taklif qilish. Referal kodi hozircha mijoz tomonida
/// ism+ID asosida generatsiya qilinadi (haqiqiy kuzatuv/hisoblash uchun
/// backend'da Referral modeli va endpoint kerak bo'ladi — keyingi bosqich).
class ReferralScreen extends StatefulWidget {
  final AppUser? user;
  const ReferralScreen({super.key, this.user});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _ref = ReferralService.instance;

  @override
  void initState() {
    super.initState();
    _ref.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ref.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  AppUser? get user => widget.user;

  /// Joriy 3 kishilik tsiklda nechta do'st a'zo bo'lgani (0..3).
  int get _cycleProgress {
    final joined = _ref.joinedCount;
    if (joined == 0) return 0;
    final inCycle = joined % 3;
    // 3, 6, 9... — tsikl to'liq tugagan
    return inCycle == 0 ? 3 : inCycle;
  }

  /// Joriy tsikldagi do'stlar ismlari (eng oxirgi taklif qilinganlari).
  List<String> get _recentNames {
    final friends = _ref.invitedFriends;
    if (friends.isEmpty) return const [];
    return friends.sublist(friends.length - _cycleProgress);
  }

  String? _initialAt(int index) {
    final names = _recentNames;
    if (index >= names.length) return null;
    final n = names[index].trim();
    return n.isEmpty ? null : n[0].toUpperCase();
  }

  String get _rewardHint {
    final left = 3 - _cycleProgress;
    if (left <= 0) {
      return "3/3 to'ldi — mukofot so'rovini yuborishingiz mumkin!";
    }
    return "$left ta do'st qoldi va siz 1 oy bepul olasiz!";
  }

  String get _code {
    final name = (user?.firstName ?? 'SAVIN').toUpperCase();
    final base = name.length >= 4 ? name.substring(0, 4) : name.padRight(4, 'X');
    final idHash = (user?.id.hashCode ?? 2026).abs() % 10000;
    final idPart = idHash.toString().padLeft(4, '0');
    return '$base$idPart';
  }

  String get _shareText =>
      "Men sizni Savin'ga taklif qilaman! Ro'yxatdan o'ting va birinchi obunangizga +1 oy bepul Premium qo'shib beraman. Kod: $_code";

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _code));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.instance.t('ref_code_copied'))),
      );
    }
  }

  Future<void> _shareTo(String app) async {
    final text = Uri.encodeComponent(_shareText);
    final url = switch (app) {
      'telegram' => 'https://t.me/share/url?url=https://savin.uz&text=$text',
      'whatsapp' => 'https://wa.me/?text=$text',
      _ => 'https://savin.uz',
    };
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.instance;
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
            child: Text(AppLocale.instance.t('friends_title')),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
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
                      width: 56, height: 56,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Text('🎁', style: TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(height: 14),
                    Text(loc.t('ref_invite_title'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(loc.t('ref_invite_sub'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: Text(loc.t('ref_your_code'),
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 8),
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_code,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
                    ),
                    TextButton.icon(
                      onPressed: () => _copy(context),
                      icon: const Icon(Icons.copy, size: 16),
                      label: Text(loc.t('ref_copy')),
                    ),
                  ],
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
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('$_cycleProgress/3',
                            style: const TextStyle(
                                color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) _progressLine(filled: i < _cycleProgress),
                          _friendAvatar(_initialAt(i), filled: i < _cycleProgress),
                        ],
                      ],
                    ),
                    if (_recentNames.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(_recentNames.join(' · '),
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.textSecondary)),
                    ],
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
                                    fontSize: 11.5, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
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
          ? Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))
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
