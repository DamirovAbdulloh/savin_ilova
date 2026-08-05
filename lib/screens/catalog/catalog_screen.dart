import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/category_icons.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../services/catalog_service.dart';
import '../../services/providers.dart';
import 'business_detail_screen.dart';

/// Katalog: Figma'dagi kabi — kategoriyalar to'ri (grid, foizlar bilan)
/// va tanlangan kategoriya bo'yicha bizneslar ro'yxati.
class CatalogScreen extends ConsumerStatefulWidget {
  /// Home ekranidan kategoriya bosib kelinganda shu kategoriya avtomatik
  /// tanlanadi (nomi bo'yicha, chunki ID API'dan async keladi).
  final String? initialCategoryName;
  const CatalogScreen({super.key, this.initialCategoryName});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  List<CategoryItem> _categories = CatalogService.fallbackCategories;
  List<BusinessItem> _businesses = CatalogService.fallbackBusinesses;
  String? _selectedCategoryId;
  bool _loadingBiz = false;

  @override
  void initState() {
    super.initState();
    AppLocale.instance.addListener(_onLocaleChanged);
    _load();
  }

  @override
  void dispose() {
    AppLocale.instance.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final cats = await CatalogService.instance.fetchCategories();
    if (!mounted) return;
    setState(() => _categories = cats);

    final initialCatName = widget.initialCategoryName ?? ref.read(selectedCategoryNameProvider);
    if (initialCatName != null) {
      final match = cats.where((c) => c.name == initialCatName).toList();
      if (match.isNotEmpty) {
        await _selectCategory(match.first);
        // Provayderni tozalaymiz, aks holda keyingi safar tabga o'tganda yana shu kategoriya tanlanib qoladi
        Future.microtask(() => ref.read(selectedCategoryNameProvider.notifier).state = null);
        return;
      }
    }

    final biz = await CatalogService.instance.fetchBusinesses();
    if (!mounted) return;
    setState(() => _businesses = biz);
  }

  Future<void> _selectCategory(CategoryItem c) async {
    final newId = _selectedCategoryId == c.id ? null : c.id;
    setState(() {
      _selectedCategoryId = newId;
      _loadingBiz = true;
    });
    final biz = await CatalogService.instance.fetchBusinesses(categoryId: newId);
    if (!mounted) return;
    setState(() {
      _businesses = biz;
      _loadingBiz = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.instance;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FadeSlideIn(
            child: Text(loc.t('catalog_title'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.95,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, i) {
              final c = _categories[i];
              final selected = _selectedCategoryId == c.id;
              return FadeSlideIn(
                delay: Duration(milliseconds: 60 + (i.clamp(0, 8)) * 50),
                child: PressableScale(
                  onTap: () => _selectCategory(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryLight : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? AppColors.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(categoryIconFor(c.name),
                            color: selected ? AppColors.primary : AppColors.textPrimary,
                            size: 28),
                        const SizedBox(height: 6),
                        Text(c.name,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        if (c.discountLabel.isNotEmpty)
                          Text(c.discountLabel,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.t('catalog_businesses'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text('${_businesses.length} ${loc.t('catalog_found')}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _loadingBiz
                ? const Padding(
                    key: ValueKey('loading'),
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2.5)),
                  )
                : _businesses.isEmpty
                    ? Center(
                        key: const ValueKey('empty'),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(loc.t('catalog_not_found')),
                        ))
                    : Column(
                        key: ValueKey('list-${_selectedCategoryId ?? 'all'}'),
                        children: List.generate(_businesses.length, (i) {
                          final b = _businesses[i];
                          return FadeSlideIn(
                            delay: Duration(milliseconds: (i.clamp(0, 8)) * 60),
                            child: _BizRow(business: b),
                          );
                        }),
                      ),
          ),
        ],
      ),
    );
  }
}

class _BizRow extends StatelessWidget {
  final BusinessItem business;
  const _BizRow({required this.business});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      // Biznes tafsiloti (dizayndagi "Biznes karta — Detail"): tavsif,
      // xizmatlar, manzil, yo'l ko'rsatish va "QR ko'rsatish".
      onTap: () => Navigator.of(context)
          .push(AppPageRoute(page: BusinessDetailScreen(business: business))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(
                business.name.isNotEmpty ? business.name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.primaryDark.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('PREMIUM',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: AppColors.textSecondary),
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
