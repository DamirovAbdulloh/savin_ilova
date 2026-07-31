import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../models/user.dart';
import '../home/main_shell.dart';
import '../profile/premium_info_screen.dart';

/// Ro'yxatdan o'tgandan (kod kiritilgandan) so'ng darhol ochiladigan
/// Premium taklif ekrani. Foydalanuvchi Premium'ni faollashtirishi yoki
/// hozircha o'tkazib yuborib ilovaga kirishi mumkin.
class PremiumOnboardingScreen extends StatelessWidget {
  final AppUser? user;
  const PremiumOnboardingScreen({super.key, this.user});

  void _enterApp(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      AppPageRoute(page: const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.instance;
    final benefits = [
      loc.t('premium_ob_benefit_1'),
      loc.t('premium_ob_benefit_2'),
      loc.t('premium_ob_benefit_3'),
    ];

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  onPressed: () => _enterApp(context),
                  child: Text(loc.t('premium_ob_later'),
                      style: const TextStyle(color: Colors.white60)),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.5, end: 1),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          builder: (context, v, child) =>
                              Transform.scale(scale: v, child: child),
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                    blurRadius: 32),
                              ],
                            ),
                            child: const Icon(Icons.workspace_premium,
                                color: Colors.white, size: 52),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: Text(loc.t('premium_ob_title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 10),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 140),
                      child: Text(loc.t('premium_ob_sub'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14, height: 1.4)),
                    ),
                    const SizedBox(height: 28),
                    ...List.generate(benefits.length, (i) {
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 200 + i * 70),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                    color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(benefits[i],
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14.5)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        AppPageRoute(page: PremiumInfoScreen(user: user)),
                      ),
                      child: Text(loc.t('premium_ob_start')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _enterApp(context),
                    child: Text(loc.t('premium_ob_later'),
                        style: const TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
