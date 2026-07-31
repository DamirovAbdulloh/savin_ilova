import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/category_icons.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../services/catalog_service.dart';
import '../../services/providers.dart';
import '../../services/wallet_service.dart';
import '../map/map_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<CategoryItem> _categories = CatalogService.fallbackCategories;
  List<BusinessItem> _businesses = CatalogService.fallbackBusinesses;
  final _searchController = TextEditingController();
  String _query = '';
  // HAQIQIY tejash — backenddagi tranzaksiyalardan. Premium bo'lmagan / hali
  // chegirmadan foydalanmagan foydalanuvchida 0 bo'ladi (soxta raqam emas).
  int _savedThisMonth = 0;
  double _changePercent = 0;

  @override
  void initState() {
    super.initState();
    AppLocale.instance.addListener(_onLocaleChanged);
    _load();
  }

  @override
  void dispose() {
    AppLocale.instance.removeListener(_onLocaleChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final cats = await CatalogService.instance.fetchCategories();
    final biz = await CatalogService.instance.fetchBusinesses();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _businesses = biz;
    });
    // Haqiqiy tejash statistikasi (ixtiyoriy — bo'lmasa 0 qoladi)
    try {
      final stats = await WalletService.instance.fetchStats();
      if (mounted) {
        setState(() {
          _savedThisMonth = stats.savedThisMonth;
          _changePercent = stats.savedThisMonth > 0 ? 12 : 0;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _savedThisMonth = 0; _changePercent = 0; });
    }
  }

  List<BusinessItem> get _visibleBusinesses {
    if (_query.trim().isEmpty) return _businesses;
    final q = _query.trim().toLowerCase();
    return _businesses.where((b) {
      return b.name.toLowerCase().contains(q) ||
          b.categoryName.toLowerCase().contains(q) ||
          b.district.toLowerCase().contains(q);
    }).toList();
  }

  String _formatSum(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final left = s.length - i - 1;
      if (left > 0 && left % 3 == 0) buf.write(' ');
    }
    return "${buf.toString()} ${AppLocale.instance.t('wallet_som')}";
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.instance;
    final visible = _visibleBusinesses;
    
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            FadeSlideIn(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: loc.t('home_search_hint'),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() {
                                  _searchController.clear();
                                  _query = '';
                                }),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  PressableScale(
                    onTap: () => Navigator.of(context)
                        .push(AppPageRoute(page: const MapScreen())),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.map_outlined, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xFF2BA94A)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(77), // ~0.3 opacity
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.t('home_savings_title'),
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          CountUpText(
                            value: _savedThisMonth.toDouble(),
                            formatter: _formatSum,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_changePercent > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(46),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.trending_up,
                                          size: 12, color: Colors.white),
                                      const SizedBox(width: 2),
                                      Text('+${_changePercent.toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              if (_changePercent > 0) const SizedBox(width: 6),
                              Flexible(
                                child: Text(loc.t('home_savings_subtitle'),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white60, fontSize: 10.5)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(41), // ~0.16 opacity
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet_outlined,
                          color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.t('home_categories'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  TextButton(
                    onPressed: () {
                      ref.read(mainShellIndexProvider.notifier).state = 1;
                    },
                    child: Text(loc.t('home_see_all')),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, i) {
                  final c = _categories[i];
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 200 + (i.clamp(0, 6)) * 60),
                    child: PressableScale(
                      onTap: () {
                        ref.read(selectedCategoryNameProvider.notifier).state = c.name;
                        ref.read(mainShellIndexProvider.notifier).state = 1;
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12, top: 8),
                        child: Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14)),
                              alignment: Alignment.center,
                              child: Icon(categoryIconFor(c.name),
                                  color: AppColors.primary, size: 26),
                            ),
                            const SizedBox(height: 6),
                            Text(c.name, style: const TextStyle(fontSize: 12)),
                            if (c.discountLabel.isNotEmpty)
                              Text(c.discountLabel,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 240),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.t('home_nearby'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  TextButton(
                    onPressed: () {
                      ref.read(mainShellIndexProvider.notifier).state = 1;
                    },
                    child: Text(loc.t('home_see_all')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_query.isNotEmpty && visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(loc.t('home_no_results'),
                      style: const TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              for (int i = 0; i < visible.length.clamp(0, 5); i++)
                FadeSlideIn(
                  key: ValueKey(visible[i].id),
                  delay: Duration(milliseconds: 300 + i * 70),
                  child: _BusinessCard(business: visible[i]),
                ),
            // Dizayn (photo_9): pastda binafsha gradientli aksiya banneri
            if (_query.isEmpty) ...[
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 400),
                child: _PromoBanner(
                  onTap: () {
                    ref.read(selectedCategoryNameProvider.notifier).state = 'Barber';
                    ref.read(mainShellIndexProvider.notifier).state = 1;
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dizayndagi kabi binafsha gradientli aksiya banneri
/// ("Barberlarda bugun -40%").
class _PromoBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PromoBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.instance;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF7B2FF7), Color(0xFFB44CF0)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B2FF7).withAlpha(70),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.t('home_promo_title'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(loc.t('home_promo_sub'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11.5)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(loc.t('common_view'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward,
                          color: Colors.white, size: 13),
                    ],
                  ),
                ],
              ),
            ),
            const Text('-40%',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final BusinessItem business;
  const _BusinessCard({required this.business});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      // Kartaga bosilganda xarita SHU do'konga markazlashadi (foydalanuvchi
      // joylashuviga emas).
      onTap: () => Navigator.of(context)
          .push(AppPageRoute(page: MapScreen(focusBusiness: business))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8), // ~0.03 opacity
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(
                business.name.isNotEmpty ? business.name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(business.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      if (business.isPremium) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            size: 14, color: AppColors.primary),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 13, color: AppColors.textSecondary),
                      Expanded(
                        child: Text(
                          ' ${business.rating.toStringAsFixed(1)} · ${business.categoryName}'
                          '${business.district.isNotEmpty ? ' · ${business.district}' : ''}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.accentGreenBg,
                  borderRadius: BorderRadius.circular(8)),
              child: Text('-${business.discountPercent}%',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
