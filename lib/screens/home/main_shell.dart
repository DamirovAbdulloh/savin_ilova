import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../services/providers.dart';
import '../../services/referral_service.dart';
import '../home/home_screen.dart';
import '../catalog/catalog_screen.dart';
import '../qr/qr_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  final _screens = const [
    HomeScreen(),
    CatalogScreen(),
    QrScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    AppLocale.instance.addListener(_onLocaleChanged);
    WidgetsBinding.instance.addObserver(this);
    // Ilova ochilganda "men faolman" signali — taklif qilgan do'stning
    // 7 kunlik hisobiga kun qo'shiladi (kunига bir marta).
    ReferralService.instance.ping();
    ReferralService.instance.load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ilova fondan qaytganda ham faollik belgilanadi — foydalanuvchi
    // ilovani qayta ishga tushirishi shart emas.
    if (state == AppLifecycleState.resumed) {
      ReferralService.instance.ping();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppLocale.instance.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.instance;
    final index = ref.watch(mainShellIndexProvider);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.015),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(index),
          child: _screens[index],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => ref.read(mainShellIndexProvider.notifier).state = i,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: loc.t('nav_home')),
          BottomNavigationBarItem(icon: const Icon(Icons.grid_view_outlined), activeIcon: const Icon(Icons.grid_view), label: loc.t('nav_catalog')),
          BottomNavigationBarItem(
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: index == 2
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: const Icon(Icons.qr_code_2, color: Colors.white),
            ),
            label: loc.t('nav_qr'),
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.account_balance_wallet_outlined), activeIcon: const Icon(Icons.account_balance_wallet), label: loc.t('nav_wallet')),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person), label: loc.t('nav_profile')),
        ],
      ),
    );
  }
}
