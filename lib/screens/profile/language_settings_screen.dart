import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';

/// Sozlamalardagi til ekrani (onboarding'dagi til tanlashdan farqli —
/// bu yerda "Saqlash" bosilgach shunchaki profilga qaytadi).
///
/// MUHIM: bu yerdagi tanlov endi haqiqatan ham qo'llaniladi va qurilmada
/// saqlanadi (AppLocale orqali) — oldin bu tugma hech narsaga ulanmagan
/// edi, shuning uchun "til umuman ishlamayapti" degan xato bor edi.
class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  late String _selected = AppLocale.instance.code;

  final _languages = const [
    {'code': 'uz', 'label': "O'zbek (Lotin)", 'sub': "O'zbekistondagi asosiy til"},
    {'code': 'ru', 'label': 'Русский', 'sub': 'Russian'},
    {'code': 'en', 'label': 'English', 'sub': 'International'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text(AppLocale.instance.t('lang_title'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: RadioGroup<String>(
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v!),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(
                child: Text(AppLocale.instance.t('lang_subtitle'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
              const SizedBox(height: 16),
              ...List.generate(_languages.length, (i) {
                final lang = _languages[i];
                final selected = _selected == lang['code'];
                return FadeSlideIn(
                  delay: Duration(milliseconds: 60 + i * 60),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _selected = lang['code']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primaryLight : AppColors.surface,
                          border: Border.all(
                              color: selected ? AppColors.primary : Colors.transparent,
                              width: 1.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(lang['label']!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600, fontSize: 15)),
                                  Text(lang['sub']!,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            Radio<String>(
                              value: lang['code']!,
                              activeColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocale.instance.t('lang_note'),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FadeSlideIn(
                delay: const Duration(milliseconds: 320),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await AppLocale.instance.setLanguage(_selected);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocale.instance.t('lang_saved_snackbar'))),
                      );
                      Navigator.of(context).pop();
                    },
                    child: Text(AppLocale.instance.t('common_save')),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
