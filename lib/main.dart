import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/i18n/app_strings.dart';
import 'core/theme.dart';
import 'core/storage/token_storage.dart';
import 'core/widgets/savin_logo.dart';
import 'services/deep_link_service.dart';
import 'services/favorites_service.dart';
import 'services/notification_prefs.dart';
import 'screens/referral/invite_accept_screen.dart';
import 'screens/splash_onboarding/language_select_screen.dart';
import 'screens/home/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocale.instance.load();
  await NotificationPrefs.instance.load();
  await FavoritesService.instance.load();
  // Do'st taklif havolasi (deep link) — ilova havola orqali ochilgan bo'lsa
  // kod shu yerda o'qiladi va ro'yxatdan o'tishga uzatiladi.
  await DeepLinkService.instance.init();
  runApp(
    const ProviderScope(
      child: SavinApp(),
    ),
  );
}

class SavinApp extends StatelessWidget {
  const SavinApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AppLocale o'zgarganda (til almashtirilganda) butun ilova darhol
    // qayta chiziladi — foydalanuvchi ilovani qayta ochishi shart emas.
    return AnimatedBuilder(
      animation: AppLocale.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Savin',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          // MUHIM: qurilmaning tizim shrift o'lchami juda katta (Katta matn
          // accessibility sozlamasi) qilib qo'yilgan bo'lsa, ba'zi qisqa
          // qatorlar (masalan biznes nomi + chegirma belgisi) sig'may qolib,
          // matn keskin qisqarib ketishi mumkin edi. Shrift ko'paytmasini
          // oqilona oraliqqa (0.9x — 1.25x) cheklaymiz — bu tizim
          // sozlamasini butunlay o'chirmaydi, faqat haddan tashqari katta
          // bo'lib layout buzilishining oldini oladi.
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            final clamped = mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.25);
            return MediaQuery(
              data: mq.copyWith(textScaler: clamped),
              child: child!,
            );
          },
          home: const _SplashGate(),
        );
      },
    );
  }
}

/// Ilova ochilganda avval saqlangan JWT sessiya bor-yo'qligini tekshiradi.
/// Bor bo'lsa — to'g'ridan-to'g'ri asosiy ekranga, yo'q bo'lsa — onboarding'ga.
/// Logo yumshoq "paydo bo'lish + kattarish" animatsiyasi bilan chiqadi.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5, curve: Curves.easeOut)),
    );
    _controller.forward();
    _decide();
  }

  Future<void> _decide() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    final hasSession = await TokenStorage.instance.hasSession();
    if (!mounted) return;

    // Taklif havolasi orqali kelgan va hali ro'yxatdan o'tmagan bo'lsa —
    // avval "Sizni taklif qilishdi" ekrani ko'rsatiladi.
    final inviteCode = DeepLinkService.instance.justArrivedCode;
    final showInvite = !hasSession && inviteCode != null && inviteCode.isNotEmpty;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) {
          if (showInvite) return InviteAcceptScreen(code: inviteCode);
          return hasSession ? const MainShell() : const LanguageSelectScreen();
        },
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SavinLogo(height: 56),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
