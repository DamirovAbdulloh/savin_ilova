import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../core/widgets/confirm_sheets.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/notification_prefs.dart';
import '../../services/referral_service.dart';
import '../../services/wallet_service.dart';
import '../catalog/favorites_screen.dart';
import '../notifications/notifications_screen.dart';
import '../splash_onboarding/language_select_screen.dart';
import 'about_app_screen.dart';
import 'how_it_works_screen.dart';
import 'edit_profile_screen.dart';
import 'help_center_screen.dart';
import 'language_settings_screen.dart';
import 'notifications_settings_screen.dart';
import 'premium_info_screen.dart';
import 'referral_screen.dart';
import 'terms_screen.dart';

/// Profil — foydalanuvchi ma'lumotlari backend /me/ dan, server ishlamasa
/// zaxira ko'rinish. Membership holati, referral taklifnoma va to'liq
/// sozlamalar menyusi bilan.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    NotificationPrefs.instance.addListener(_onPrefsChanged);
    // Til o'zgarganda profil ekrani ham darhol yangi tilda chizilsin
    AppLocale.instance.addListener(_onPrefsChanged);
    _load();
  }

  @override
  void dispose() {
    NotificationPrefs.instance.removeListener(_onPrefsChanged);
    AppLocale.instance.removeListener(_onPrefsChanged);
    super.dispose();
  }

  void _onPrefsChanged() {
    if (mounted) setState(() {});
  }

  /// Akkountni o'chirish oynasida "nima yo'qotasiz" ro'yxati uchun —
  /// HAQIQIY tejash summasi (ilgari bu yerda soxta "247 500" yozilgan edi).
  int _savedAllTime = 0;

  Future<void> _load() async {
    try {
      final user = await AuthService.instance.fetchMe();
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
    // Ixtiyoriy — bo'lmasa 0 qoladi
    try {
      final stats = await WalletService.instance.fetchStats();
      if (mounted) setState(() => _savedAllTime = stats.savedAllTime);
    } catch (_) {}
    ReferralService.instance.load();
  }

  String _fmtSum(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final left = s.length - i - 1;
      if (left > 0 && left % 3 == 0) buf.write(' ');
    }
    return buf.toString();
  }

  int? get _membershipDaysLeft {
    final exp = _user?.membershipExpiresAt;
    if (exp == null) return null;
    final days = exp.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  Future<void> _confirmLogout() async {
    await AuthService.instance.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute(page: const LanguageSelectScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _confirmDelete() async {
    try {
      await AuthService.instance.deleteAccount();
    } catch (_) {
      // Server bilan bog'lanib bo'lmasa ham, xavfsizlik uchun mahalliy
      // seansni tozalab, foydalanuvchini chiqarib yuboramiz.
    }
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute(page: const LanguageSelectScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.instance;
    final name = _user?.fullName.isNotEmpty == true ? _user!.fullName : 'Foydalanuvchi';
    final phone = _user?.phoneNumber ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    final isPremium = _user?.isPremium == true;
    final daysLeft = _membershipDaysLeft;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            FadeSlideIn(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.t('profile_title'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: _user?.avatarUrl != null
                            ? NetworkImage(_user!.avatarUrl!) as ImageProvider
                            : null,
                        child: _loading
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.primary))
                            : (_user?.avatarUrl == null
                                ? Text(initial,
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 22))
                                : null),
                      ),
                      if (isPremium)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: AppColors.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.star,
                                size: 11, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 17)),
                        if (phone.isNotEmpty)
                          Text(phone,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final changed = await Navigator.of(context).push(
                        AppPageRoute(page: EditProfileScreen(user: _user)),
                      );
                      if (changed == true) _load();
                    },
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: PressableScale(
                onTap: () => Navigator.of(context).push(
                  AppPageRoute(page: PremiumInfoScreen(user: _user)),
                ),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryDark, Color(0xFF14522F)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.t('profile_membership'),
                                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
                              Text(isPremium ? loc.t('profile_premium') : loc.t('profile_standard'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isPremium ? loc.t('profile_extend') : loc.t('profile_upgrade'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      if (isPremium && daysLeft != null) ...[
                        const SizedBox(height: 14),
                        Text('$daysLeft ${loc.t('profile_days_left')}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                                begin: 0, end: (1 - (daysLeft / 30)).clamp(0, 1)),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) => LinearProgressIndicator(
                              value: v,
                              minHeight: 6,
                              backgroundColor: Colors.white24,
                              valueColor:
                                  const AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                        ),
                      ] else if (!isPremium) ...[
                        const SizedBox(height: 8),
                        Text(loc.t('profile_upgrade_sub'), // I'll add this key to app_strings
                            style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: const Duration(milliseconds: 220),
              child: PressableScale(
                onTap: () => Navigator.of(context).push(
                  AppPageRoute(page: ReferralScreen(user: _user)),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const Text('🎁', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.t('profile_invite_friend'),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(loc.t('profile_invite_sub'),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 280),
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.favorite_border,
                    label: loc.t('fav_title'),
                    onTap: () => Navigator.of(context)
                        .push(AppPageRoute(page: const FavoritesScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.notifications_none,
                    label: loc.t('notif_title'),
                    onTap: () => Navigator.of(context)
                        .push(AppPageRoute(page: const NotificationsScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.help_center_outlined,
                    label: loc.t('how_title'),
                    onTap: () => Navigator.of(context)
                        .push(AppPageRoute(page: const HowItWorksScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.language,
                    label: loc.t('profile_lang'),
                    value: loc.code.toUpperCase(),
                    onTap: () => Navigator.of(context)
                        .push(AppPageRoute(page: const LanguageSettingsScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.notifications_outlined,
                    label: loc.t('profile_notifications'),
                    value: NotificationPrefs.instance.masterEnabled
                        ? (loc.code == 'ru' ? 'Вкл' : (loc.code == 'en' ? 'On' : 'Yoqilgan'))
                        : (loc.code == 'ru' ? 'Выкл' : (loc.code == 'en' ? 'Off' : 'Yoqilmagan')),
                    onTap: () => Navigator.of(context).push(
                        AppPageRoute(page: const NotificationsSettingsScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.help_outline,
                    label: loc.t('profile_help'),
                    onTap: () => Navigator.of(context)
                        .push(AppPageRoute(page: const HelpCenterScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.description_outlined,
                    label: loc.t('profile_terms'),
                    onTap: () => Navigator.of(context)
                        .push(AppPageRoute(page: const TermsScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.info_outline,
                    label: loc.t('profile_about'),
                    onTap: () => Navigator.of(context)
                        .push(AppPageRoute(page: const AboutAppScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 340),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => showLogoutSheet(
                    context,
                    onConfirm: _confirmLogout,
                    membershipDaysLeft: daysLeft,
                  ),
                  icon: const Icon(Icons.logout, color: AppColors.danger),
                  label: Text(loc.t('profile_logout'),
                      style: const TextStyle(color: AppColors.danger)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 380),
              child: Center(
                child: TextButton(
                  onPressed: () => showDeleteAccountSheet(
                    context,
                    onConfirm: _confirmDelete,
                    losses: [
                      if (_savedAllTime > 0)
                        loc
                            .t('delete_loss_savings')
                            .replaceAll('{n}', _fmtSum(_savedAllTime)),
                      if (ReferralService.instance.activeCount > 0)
                        loc.t('delete_loss_friends').replaceAll(
                            '{n}', '${ReferralService.instance.activeCount}'),
                      if (isPremium)
                        loc
                            .t('delete_loss_premium')
                            .replaceAll('{n}', '${daysLeft ?? 0}'),
                    ],
                  ),
                  child: Text(loc.t('profile_delete'),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  const _MenuTile({required this.icon, required this.label, this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: value != null
          ? Text(value!, style: const TextStyle(color: AppColors.textSecondary))
          : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
