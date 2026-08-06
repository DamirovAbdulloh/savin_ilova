import 'package:flutter/material.dart';

import '../../core/i18n/locale_builder.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  /// Bandlar soni — matnlar `app_strings.dart` da uch tilda saqlanadi
  /// (`terms_1_t`/`terms_1_b` ... ). Ilgari ular shu yerda faqat o'zbekcha
  /// yozib qo'yilgan edi va til almashtirilganda o'zgarmasdi.
  static const _sectionCount = 6;

  @override
  Widget build(BuildContext context) {
    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
      appBar: AppBar(leading: BackButton(), title: Text(loc.t('terms_title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.t('terms_version'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(loc.t('terms_date'),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            ...List.generate(_sectionCount, (i) {
              final n = i + 1;
              return FadeSlideIn(
                delay: Duration(milliseconds: 60 + i * 50),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.t('terms_${n}_t'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text(loc.t('terms_${n}_b'),
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.5)),
                    ],
                  ),
                ),
              );
            }),
            FadeSlideIn(
              delay: Duration(milliseconds: 60 + _sectionCount * 50),
              child: TextButton(
                onPressed: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(loc.t('terms_read_full')),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
