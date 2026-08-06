import 'package:flutter/material.dart';
import '../i18n/app_strings.dart';
import '../theme.dart';

/// Ilova bo'ylab ishlatiladigan tasdiqlash bottom-sheet'lari
/// (hisobdan chiqish, akkountni o'chirish va h.k.) — Figma dizayniga mos.
///
/// Matnlar `app_strings.dart` dan olinadi — ilgari o'zbekcha yozib
/// qo'yilgani uchun til almashtirilganda o'zgarmasdi.

Future<void> showLogoutSheet(
  BuildContext context, {
  required VoidCallback onConfirm,
  int? membershipDaysLeft,
}) {
  final loc = AppLocale.instance;
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _ConfirmSheet(
      emoji: '👋',
      iconBg: AppColors.primaryLight,
      title: loc.t('logout_title'),
      description: loc.t('logout_desc'),
      badge: membershipDaysLeft != null
          ? loc.t('logout_badge').replaceAll('{n}', '$membershipDaysLeft')
          : null,
      confirmLabel: loc.t('logout_confirm'),
      confirmColor: AppColors.primary,
      cancelLabel: loc.t('common_cancel'),
      onConfirm: onConfirm,
    ),
  );
}

Future<void> showDeleteAccountSheet(
  BuildContext context, {
  required VoidCallback onConfirm,
  required List<String> losses,
}) {
  final loc = AppLocale.instance;
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _ConfirmSheet(
      icon: Icons.warning_rounded,
      iconBg: AppColors.danger.withValues(alpha: 0.12),
      iconColor: AppColors.danger,
      title: loc.t('delete_title'),
      description: loc.t('delete_desc'),
      losses: losses,
      confirmLabel: loc.t('delete_confirm'),
      confirmColor: AppColors.danger,
      cancelLabel: loc.t('common_cancel'),
      onConfirm: onConfirm,
    ),
  );
}

class _ConfirmSheet extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final Color iconBg;
  final Color? iconColor;
  final String title;
  final String description;
  final String? badge;
  final List<String>? losses;
  final String confirmLabel;
  final Color confirmColor;
  final String cancelLabel;
  final VoidCallback onConfirm;

  const _ConfirmSheet({
    this.emoji,
    this.icon,
    required this.iconBg,
    this.iconColor,
    required this.title,
    required this.description,
    this.badge,
    this.losses,
    required this.confirmLabel,
    required this.confirmColor,
    required this.cancelLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: emoji != null
                  ? Text(emoji!, style: const TextStyle(fontSize: 30))
                  : Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4)),
            if (losses != null && losses!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: losses!
                      .map((l) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                const Icon(Icons.close, size: 14, color: AppColors.danger),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(l,
                                      style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
            if (badge != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge!,
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                child: Text(confirmLabel),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(cancelLabel,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
