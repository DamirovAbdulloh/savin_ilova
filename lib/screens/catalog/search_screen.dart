import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/category_icons.dart';
import '../../core/i18n/locale_builder.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../services/catalog_service.dart';
import '../../services/providers.dart';
import 'business_detail_screen.dart';

/// Qidirish ekrani (dizayn: "Empty — Bizneslar (qidirish)" va
/// "Xarita — Qidiruv"): so'nggi qidiruvlar, ommabop so'rovlar va
/// natija topilmagan holat.
class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _kRecent = 'recent_searches';

  final _controller = TextEditingController();
  Timer? _debounce;

  List<BusinessItem> _results = const [];
  List<CategoryItem> _categories = const [];
  List<String> _recent = const [];
  bool _searching = false;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _loadRecent();
    CatalogService.instance.fetchCategories().then((c) {
      if (mounted) setState(() => _categories = c);
    });
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      _search(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() => _recent = prefs.getStringList(_kRecent) ?? const []);
    } catch (_) {}
  }

  Future<void> _rememberQuery(String q) async {
    final query = q.trim();
    if (query.isEmpty) return;
    final list = [query, ..._recent.where((e) => e != query)].take(6).toList();
    setState(() => _recent = list);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kRecent, list);
    } catch (_) {}
  }

  Future<void> _removeRecent(String q) async {
    final list = _recent.where((e) => e != q).toList();
    setState(() => _recent = list);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kRecent, list);
    } catch (_) {}
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _touched = false;
      });
      return;
    }
    setState(() {
      _searching = true;
      _touched = true;
    });
    final items = await CatalogService.instance.fetchBusinesses(search: query);
    if (!mounted) return;
    setState(() {
      _results = items;
      _searching = false;
    });
    await _rememberQuery(query);
  }

  void _openCategory(CategoryItem c) {
    ref.read(selectedCategoryNameProvider.notifier).state = c.name;
    ref.read(mainShellIndexProvider.notifier).state = 1;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(loc.t('search_title')),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TextField(
                  controller: _controller,
                  autofocus: widget.initialQuery == null,
                  textInputAction: TextInputAction.search,
                  onChanged: _onChanged,
                  onSubmitted: _search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: loc.t('search_hint'),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _controller.clear();
                              _search('');
                            },
                          ),
                  ),
                ),
              ),
              Expanded(
                child: _searching
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2.5))
                    : _touched
                        ? (_results.isEmpty
                            ? _emptyResult(loc)
                            : _resultList())
                        : _suggestions(loc),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final b = _results[i];
        return FadeSlideIn(
          key: ValueKey(b.id),
          delay: Duration(milliseconds: (i.clamp(0, 8)) * 50),
          child: PressableScale(
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyResult(dynamic loc) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
                color: AppColors.primaryLight, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.search_off,
                size: 44, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 20),
        Text(loc.t('search_empty'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(loc.t('search_empty_sub'),
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton(
            onPressed: () {
              _controller.clear();
              _search('');
            },
            child: Text(loc.t('search_categories')),
          ),
        ),
      ],
    );
  }

  Widget _suggestions(dynamic loc) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        if (_recent.isNotEmpty) ...[
          Text(loc.t('search_recent'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final q in _recent)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.history,
                  size: 18, color: AppColors.textSecondary),
              title: Text(q, style: const TextStyle(fontSize: 13.5)),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => _removeRecent(q),
              ),
              onTap: () {
                _controller.text = q;
                _search(q);
              },
            ),
          const SizedBox(height: 12),
        ],
        Text(loc.t('search_popular'),
            style: const TextStyle(
                fontSize: 11,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in _categories.take(8))
              ActionChip(
                label: Text(c.name, style: const TextStyle(fontSize: 12.5)),
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
                onPressed: () => _openCategory(c),
              ),
          ],
        ),
      ],
    );
  }
}
