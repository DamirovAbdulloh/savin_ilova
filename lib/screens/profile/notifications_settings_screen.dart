import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../services/notification_prefs.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  final _prefs = NotificationPrefs.instance;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.instance;
    final master = _prefs.masterEnabled;
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text(loc.t('profile_notifications'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FadeSlideIn(
              child: Text(loc.t('notif_subtitle'),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
            const SizedBox(height: 16),
            // Umumiy (master) tugma — barcha bildirishnomalarni bittada boshqaradi
            FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: master ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: master ? AppColors.primary : AppColors.border, width: 1.2),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.primary,
                  secondary: Icon(
                    master ? Icons.notifications_active : Icons.notifications_off,
                    color: master ? AppColors.primary : AppColors.textSecondary,
                  ),
                  title: Text(loc.t('notif_master_title'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  subtitle: Text(loc.t('notif_master_sub'),
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  value: master,
                  onChanged: (v) => setState(() => _prefs.setMaster(v)),
                ),
              ),
            ),
            if (!master) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(loc.t('notif_disabled_hint'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // Master o'chirilganda quyidagi bo'limlar kulrang va bosilmaydigan bo'ladi
            IgnorePointer(
              ignoring: !master,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: master ? 1 : 0.4,
                child: Column(children: [
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: _Section(
                title: loc.t('notif_sec_services'),
                children: [
                  _toggle(loc.t('notif_new_biz'), loc.t('notif_new_biz_sub'),
                      _prefs.newBusinesses, 'newBusinesses'),
                  _toggle(loc.t('notif_offers'), loc.t('notif_offers_sub'),
                      _prefs.specialOffers, 'specialOffers'),
                  _toggle(loc.t('notif_birthday'), loc.t('notif_birthday_sub'),
                      _prefs.birthdayDiscount, 'birthdayDiscount'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: _Section(
                title: loc.t('notif_sec_account'),
                children: [
                  _toggle(loc.t('notif_membership'), loc.t('notif_membership_sub'),
                      _prefs.membershipReminders, 'membershipReminders'),
                  _toggle(loc.t('notif_tx'), loc.t('notif_tx_sub'),
                      _prefs.transactionReceipts, 'transactionReceipts'),
                  _toggle(loc.t('notif_ref'), loc.t('notif_ref_sub'),
                      _prefs.referralUpdates, 'referralUpdates'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: _Section(
                title: loc.t('notif_sec_marketing'),
                children: [
                  _toggle(loc.t('notif_email'), loc.t('notif_email_sub'),
                      _prefs.emailNewsletter, 'emailNewsletter'),
                  _toggle(loc.t('notif_sms'), loc.t('notif_sms_sub'),
                      _prefs.smsAds, 'smsAds'),
                ],
              ),
            ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle(String title, String subtitle, bool value, String key) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.primary,
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
      value: value,
      onChanged: (v) => setState(() => _prefs.set(key, v)),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
