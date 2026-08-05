import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/category_icons.dart';
import '../../core/i18n/locale_builder.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../services/catalog_service.dart';
import '../../services/favorites_service.dart';
import '../../services/providers.dart';
import 'business_detail_screen.dart';

/// Sevimli bizneslar (dizayn: "Sevimli bizneslar" va "Sevimlilar — Empty").
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final _fav = FavoritesService.instance;
  List<BusinessItem> _all = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fav.addListener(_onChanged);
    _load();
  }

  @override
  void dispose() {
    _fav.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final items = await CatalogService.instance.fetchBusinesses();
    if (!mounted) return;
    setState(() {
      _all = items;
      _loading = false;
    });
  }

  List<BusinessItem> get _favorites =>
      _all.where((b) => _fav.isFavorite(b.id)).toList();

  void _goToCatalog() {
    ref.read(mainShellIndexProvider.notifier).state = 1;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final items = _favorites;

    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(loc.t('fav_title')),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2.5))
              : items.isEmpty
                  ? _empty(loc)
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.favorite,
                                    color: AppColors.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${items.length} ta sevimli biznes',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          for (var i = 0; i < items.length; i++)
                            FadeSlideIn(
                              key: ValueKey(items[i].id),
                              delay: Duration(milliseconds: i * 60),
                              child: _favTile(items[i]),
                            ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _empty(dynamic loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                  color: AppColors.surface, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.favorite_border,
                  size: 44, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 22),
            Text(loc.t('fav_empty'),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(loc.t('fav_empty_sub'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 22),
            OutlinedButton(
              onPressed: _goToCatalog,
              child: Text(loc.t('fav_go_catalog')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _favTile(BusinessItem b) {
    return PressableScale(
      onTap: () => Navigator.of(context)
          .push(AppPageRoute(page: BusinessDetailScreen(business: b))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(categoryIconFor(b.categoryName),
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${b.categoryName}${b.district.isEmpty ? '' : ' · ${b.district}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.accentGreenBg,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('-${b.discountPercent}%',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5)),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _fav.toggle(b.id),
                  child: const Icon(Icons.favorite,
                      size: 17, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
