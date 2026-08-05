import 'package:flutter/material.dart';

import '../../core/category_icons.dart';
import '../../core/i18n/locale_builder.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../services/catalog_service.dart';
import 'business_detail_screen.dart';

/// "Yangi hamkorlar" (dizayn: Asosiy — Yangi hamkorlar).
///
/// Yuqorida hafta tavsiyasi (eng katta chegirmali biznes), pastda yaqinda
/// qo'shilgan hamkorlar ro'yxati.
class NewPartnersScreen extends StatefulWidget {
  const NewPartnersScreen({super.key});

  @override
  State<NewPartnersScreen> createState() => _NewPartnersScreenState();
}

class _NewPartnersScreenState extends State<NewPartnersScreen> {
  List<BusinessItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await CatalogService.instance.fetchBusinesses();
    if (!mounted) return;
    // Eng katta chegirmalilar "yangi hamkorlar" sifatida yuqorida turadi
    final sorted = [...items]
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    setState(() {
      _items = sorted;
      _loading = false;
    });
  }

  void _open(BusinessItem b) {
    Navigator.of(context)
        .push(AppPageRoute(page: BusinessDetailScreen(business: b)));
  }

  @override
  Widget build(BuildContext context) {
    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(loc.t('partners_title')),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2.5))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_items.isNotEmpty) _featured(_items.first, loc),
                      const SizedBox(height: 18),
                      Text(
                        '${loc.t('partners_added')} · ${_items.length} ta',
                        style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      for (var i = 1; i < _items.length; i++)
                        FadeSlideIn(
                          key: ValueKey(_items[i].id),
                          delay: Duration(milliseconds: (i.clamp(0, 8)) * 50),
                          child: _row(_items[i], loc),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _featured(BusinessItem b, dynamic loc) {
    return PressableScale(
      onTap: () => _open(b),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999)),
                  child: Text(loc.t('partners_week'),
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
                const Spacer(),
                Icon(categoryIconFor(b.categoryName),
                    color: Colors.white24, size: 34),
              ],
            ),
            const SizedBox(height: 14),
            Text(b.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${b.categoryName}${b.district.isEmpty ? '' : ' • ${b.district}'}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('-${b.discountPercent}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BusinessItem b, dynamic loc) {
    return PressableScale(
      onTap: () => _open(b),
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(b.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      if (b.isPremium) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.accentGreenBg,
                              borderRadius: BorderRadius.circular(5)),
                          child: Text(loc.t('partners_new'),
                              style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                        ),
                      ],
                    ],
                  ),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.accentGreenBg,
                  borderRadius: BorderRadius.circular(8)),
              child: Text('-${b.discountPercent}%',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5)),
            ),
          ],
        ),
      ),
    );
  }
}
