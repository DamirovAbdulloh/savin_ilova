import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/locale_builder.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../services/providers.dart';

/// "Qanday ishlaydi?" — 4 qadamli tushuntirish (dizayndagi ekran).
///
/// Ikki joyda ishlatiladi:
///  * ro'yxatdan o'tishdan OLDIN — onboardingdan keyin ko'rsatiladi va
///    "QR chegirma olish" bosilganda ro'yxatdan o'tish boshlanadi
///    (`onContinue` beriladi);
///  * ilova ichida, Profil bo'limidan — tugma QR ekraniga olib boradi.
class HowItWorksScreen extends ConsumerWidget {
  /// Berilgan bo'lsa, pastdagi tugma shu funksiyani chaqiradi
  /// (ro'yxatdan o'tishni boshlash uchun).
  final VoidCallback? onContinue;

  const HowItWorksScreen({super.key, this.onContinue});

  void _openQr(BuildContext context, WidgetRef ref) {
    if (onContinue != null) {
      onContinue!();
      return;
    }
    ref.read(mainShellIndexProvider.notifier).state = 2;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
        appBar: AppBar(leading: const BackButton(), title: const Text('')),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  children: [
                    FadeSlideIn(
                      child: Text(loc.t('how_title'),
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 4),
                    Text(loc.t('how_sub'),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 22),
                    for (var i = 1; i <= 4; i++)
                      FadeSlideIn(
                        delay: Duration(milliseconds: 80 * i),
                        child: _step(
                          number: i,
                          title: loc.t('how_${i}_t'),
                          description: loc.t('how_${i}_d'),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _openQr(context, ref),
                    child: Text(loc.t('how_cta')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step({
    required int number,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('$number',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(description,
                    style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
