import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../core/widgets/savin_logo.dart';
import 'onboarding_screen.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  late String _selected = AppLocale.instance.code;

  final _languages = const [
    {'code': 'uz', 'flag': '🇺🇿', 'label': "O'zbek", 'sub': "O'zbekiston · Lotin yozuvi"},
    {'code': 'ru', 'flag': '🇷🇺', 'label': 'Русский', 'sub': 'Россия · СНГ'},
    {'code': 'en', 'flag': '🇬🇧', 'label': 'English', 'sub': 'United Kingdom · International'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const FadeSlideIn(
                child: SavinLogo(height: 34),
              ),
              const SizedBox(height: 40),
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: Text(AppLocale.instance.t('lang_subtitle'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 20),
              ...List.generate(_languages.length, (idx) {
                final lang = _languages[idx];
                final isSelected = _selected == lang['code'];
                return FadeSlideIn(
                  delay: Duration(milliseconds: 180 + idx * 80),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _selected = lang['code']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryLight : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            // Dizayn: har bir til qatorida davlat bayrog'i
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(lang['flag']!,
                                  style: const TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(lang['label']!,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                  Text(lang['sub']!,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                ],
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: Icon(
                                isSelected ? Icons.check_circle : Icons.circle_outlined,
                                key: ValueKey(isSelected),
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              FadeSlideIn(
                delay: const Duration(milliseconds: 450),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await AppLocale.instance.setLanguage(_selected);
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        AppPageRoute(page: const OnboardingScreen()),
                      );
                    },
                    child: Text(AppLocale.instance.t('common_continue')),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
