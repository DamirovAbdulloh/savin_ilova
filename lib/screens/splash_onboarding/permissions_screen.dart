import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/i18n/locale_builder.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../services/notification_prefs.dart';

/// Ruxsat so'rash ekranlari (dizayn: "Permission — Bildirishnoma" va
/// "Permission — Lokatsiya").
///
/// Onboardingdan keyin, ro'yxatdan o'tishdan oldin ko'rsatiladi. Ikkala
/// qadamni ham o'tkazib yuborish mumkin — ilova baribir ishlaydi.
class PermissionsScreen extends StatefulWidget {
  /// Ikkala qadam tugagach chaqiriladi (yoki "o'tkazib yuborish" bosilsa).
  final VoidCallback onDone;
  const PermissionsScreen({super.key, required this.onDone});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  int _step = 0; // 0 = bildirishnoma, 1 = lokatsiya
  bool _busy = false;

  Future<void> _allow() async {
    setState(() => _busy = true);
    if (_step == 0) {
      // Bildirishnomalar ilova ichida sozlanadi (push provayderi hali
      // ulanmagan) — foydalanuvchi tanlovini yoqib qo'yamiz.
      NotificationPrefs.instance.setMaster(true);
      NotificationPrefs.instance.set('newBusinesses', true);
      NotificationPrefs.instance.set('specialOffers', true);
      NotificationPrefs.instance.set('membershipReminders', true);
    } else {
      try {
        await Geolocator.requestPermission();
      } catch (_) {
        // Ruxsat berilmasa ham davom etamiz
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _next();
  }

  void _next() {
    if (_step == 0) {
      setState(() => _step = 1);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNotif = _step == 0;

    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton(
                    onPressed: widget.onDone,
                    child: const Text("O'tkazib yuborish",
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeSlideIn(
                        key: ValueKey('art$_step'),
                        child: Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              isNotif
                                  ? Icons.notifications_active
                                  : Icons.location_on,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      FadeSlideIn(
                        key: ValueKey('title$_step'),
                        delay: const Duration(milliseconds: 60),
                        child: Text(
                          loc.t(isNotif ? 'perm_notif_title' : 'perm_loc_title'),
                          style: const TextStyle(
                              fontSize: 23, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.t(isNotif ? 'perm_notif_sub' : 'perm_loc_sub'),
                        style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 22),
                      ...(isNotif
                              ? const [
                                  'Yangi hamkor bizneslar haqida xabar',
                                  'Premium tugashga 3 va 1 kun oldin eslatma',
                                  "Do'stlaringiz a'zo bo'lganda bilib turing",
                                ]
                              : const [
                                  'Yaqin atrofdagi hamkorlar xaritada',
                                  'Har bir biznesgacha aniq masofa',
                                  "Yo'l ko'rsatish — bitta bosishda",
                                ])
                          .map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle,
                                        size: 18, color: AppColors.primary),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(t,
                                          style: const TextStyle(fontSize: 13)),
                                    ),
                                  ],
                                ),
                              )),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _allow,
                        child: Text(loc.t('perm_allow')),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _next,
                      child: Text(loc.t('perm_later'),
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
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
}
