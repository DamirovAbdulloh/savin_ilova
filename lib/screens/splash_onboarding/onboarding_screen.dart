import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../core/widgets/savin_logo.dart';
import '../auth/auth_name_screen.dart';
import '../profile/how_it_works_screen.dart';
import 'permissions_screen.dart';

class _OnboardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bg;
  final Color fg;
  const _OnboardData(this.title, this.subtitle, this.icon, this.bg, this.fg);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  List<_OnboardData> get _pages => [
    _OnboardData(
      AppLocale.instance.t('onboard_1_title'),
      AppLocale.instance.t('onboard_1_sub'),
      Icons.local_offer,
      AppColors.primaryLight,
      AppColors.primary,
    ),
    _OnboardData(
      AppLocale.instance.t('onboard_2_title'),
      AppLocale.instance.t('onboard_2_sub'),
      Icons.qr_code_2,
      AppColors.primaryDark,
      Colors.white,
    ),
    // Dizayn (photo_1, 4-kadr): 3-sahifa och yashil fonda, "247K tejagansiz"
    // halqasi va suzuvchi foiz belgilari bilan.
    _OnboardData(
      AppLocale.instance.t('onboard_3_title'),
      AppLocale.instance.t('onboard_3_sub'),
      Icons.account_balance_wallet,
      AppColors.primaryLight,
      AppColors.primary,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final page = pages[_index];
    final isDark = page.bg == AppColors.primaryDark;

    // Dizayn: sahifa OQ fonda; rangli faqat yuqoridagi tasvir paneli.
    // Sarlavha va matn har doim oq qismda, qora rangda turadi.
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SavinLogo(height: 26),
                  TextButton(
                    onPressed: _goToAuth,
                    child: Text(AppLocale.instance.t('common_skip'),
                        style: const TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = pages[i];
                  return Column(
                    children: [
                      // Tasvir paneli — chetdan chetgacha, rangli fon
                      Expanded(
                        flex: 5,
                        child: Container(
                          width: double.infinity,
                          color: p.bg,
                          alignment: Alignment.center,
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey(i == _index),
                            tween: Tween(begin: 0.7, end: 1),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                            builder: (context, scale, child) =>
                                Transform.scale(scale: scale, child: child),
                            child: switch (i) {
                              // 1-sahifa: ustma-ust chegirma kartalari
                              0 => const _StackedDiscountCards(),
                              // 2-sahifa: telefon ichida QR (dizayndagidek)
                              1 => const _QrShowcase(),
                              // 3-sahifa: "247K tejagansiz" halqasi
                              _ => const _SavingsRing(),
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
                          child: Column(
                            children: [
                              Text(
                                p.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                p.subtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_index < pages.length - 1) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        _goToAuth();
                      }
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _index < pages.length - 1
                            ? AppLocale.instance.t('common_continue')
                            : AppLocale.instance.t('common_start'),
                        key: ValueKey(_index < pages.length - 1),
                      ),
                    ),
                  ),
                ),
              ),
              // Dizayn: oxirgi sahifada "Akkountingiz bormi? Kirish" havolasi
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _index == pages.length - 1 ? 1 : 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${AppLocale.instance.t('onboard_have_account')} ',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _index == pages.length - 1 ? _goToAuth : null,
                        child: Text(
                          AppLocale.instance.t('onboard_login'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  void _goToAuth() {
    // Dizayndagi ketma-ketlik: onboarding -> ruxsatlar -> "Qanday ishlaydi?"
    // -> "QR chegirma olish" bosilgach ro'yxatdan o'tish boshlanadi.
    Navigator.of(context).push(
      AppPageRoute(
        page: PermissionsScreen(
          onDone: () => Navigator.of(context).pushReplacement(
            AppPageRoute(
              page: HowItWorksScreen(
                onContinue: () => Navigator.of(context).pushReplacement(
                  AppPageRoute(page: const AuthNameScreen()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Onboarding 2-sahifasi tasviri (dizayn: "QR ko'rsating — tejang").
///
/// To'q yashil fonda: orqada katta yashil doira, oldinda telefon konturi,
/// uning ichida oq QR kvadrat va atrofida uchqunlar.
class _QrShowcase extends StatelessWidget {
  const _QrShowcase();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Orqadagi katta doira
          Positioned(
            right: 6,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Telefon konturi
          Container(
            width: 118,
            height: 196,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35), width: 2),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 76,
              height: 76,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomPaint(
                      size: const Size(62, 44),
                      painter: _MiniQrPainter(),
                    ),
                  ),
                  const Text('QR',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark)),
                ],
              ),
            ),
          ),
          // Uchqunlar
          const Positioned(top: 32, right: 30, child: _Sparkle(size: 16)),
          const Positioned(bottom: 54, right: 16, child: _Sparkle(size: 11)),
          const Positioned(bottom: 40, left: 44, child: _Sparkle(size: 13)),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  final double size;
  const _Sparkle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome, size: size, color: AppColors.primary);
  }
}

/// Kichik QR naqshi — haqiqiy kod emas, faqat tasvir.
class _MiniQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primaryDark;
    const cols = 7;
    const rows = 5;
    final cw = size.width / cols;
    final ch = size.height / rows;
    // Barqaror "tasodifiy" naqsh (har chizishda bir xil)
    const pattern = [
      1, 1, 0, 1, 0, 1, 1,
      1, 0, 1, 0, 1, 0, 1,
      0, 1, 1, 1, 0, 1, 0,
      1, 0, 1, 0, 1, 1, 1,
      1, 1, 0, 1, 1, 0, 1,
    ];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (pattern[r * cols + c] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(c * cw + 1, r * ch + 1, cw - 2, ch - 2),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Figma'dagi kabi ustma-ust chegirma kartalari (-40% CHEGIRMA).
class _StackedDiscountCards extends StatelessWidget {
  const _StackedDiscountCards();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Orqa kartalar (biroz burilgan)
          Transform.rotate(
            angle: -0.18,
            child: _card(AppColors.accentGreenBg, null),
          ),
          Transform.rotate(
            angle: 0.10,
            child: _card(const Color(0xFFB9EDC6), null),
          ),
          // Old karta
          Transform.rotate(
            angle: -0.05,
            child: _card(AppColors.primary, '-40%'),
          ),
          // Yuqoridagi kichik yashil doira (+ belgisi)
          Positioned(
            top: 6,
            right: 18,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Color color, String? text) {
    return Container(
      width: 170,
      height: 110,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: text == null
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(text,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800)),
                const Text('CHEGIRMA',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600)),
              ],
            ),
    );
  }
}

/// Dizayndagi (photo_1, 4-kadr) "247K tejagansiz" halqasi — och yashil fon
/// ustida qalin yashil halqa, markazida summa, atrofida suzuvchi foiz
/// belgilari (+10%, +25%, +15%, +40%).
class _SavingsRing extends StatelessWidget {
  const _SavingsRing();

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tashqi och halqa
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentGreenBg, width: 18),
            ),
          ),
          // Ichki to'q yashil halqa (qisman) — soddalashtirilgan ko'rinish
          const SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: 0.72,
              strokeWidth: 18,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          // Markaz: 247K tejagansiz
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('247K',
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              Text(AppLocale.instance.t('qr_saved_label'),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          // Suzuvchi foiz belgilari
          Positioned(top: 10, left: 8, child: _badge('+10%')),
          Positioned(top: 24, right: 0, child: _badge('+25%')),
          Positioned(bottom: 26, left: 0, child: _badge('+15%')),
          Positioned(bottom: 40, right: 6, child: _badge('+40%')),
        ],
      ),
    );
  }
}
