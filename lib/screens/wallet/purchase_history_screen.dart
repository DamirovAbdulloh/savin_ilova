import 'package:flutter/material.dart';

import '../../core/category_icons.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_builder.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../services/wallet_service.dart';

/// "Xarid tarixi" (dizayn: Hamyon — Xarid tarixi).
///
/// Tranzaksiyalar kunlar bo'yicha guruhlanadi; yuqorida oylik jami va
/// kategoriya bo'yicha filtr chiplari turadi.
class PurchaseHistoryScreen extends StatefulWidget {
  final List<TransactionItem> transactions;
  const PurchaseHistoryScreen({super.key, required this.transactions});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  String? _category; // null = hammasi

  List<String> get _categories {
    final set = <String>{};
    for (final t in widget.transactions) {
      if (t.categoryName.isNotEmpty) set.add(t.categoryName);
    }
    return set.toList()..sort();
  }

  List<TransactionItem> get _visible {
    final list = _category == null
        ? [...widget.transactions]
        : widget.transactions.where((t) => t.categoryName == _category).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  String _fmt(num v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final left = s.length - i - 1;
      if (left > 0 && left % 3 == 0) buf.write(' ');
    }
    return buf.toString();
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Bugun';
    if (diff == 1) return 'Kecha';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    final som = AppLocale.instance.t('wallet_som');

    // Kunlar bo'yicha guruhlash
    final groups = <String, List<TransactionItem>>{};
    for (final t in items) {
      final key = _dayLabel(t.createdAt.toLocal());
      groups.putIfAbsent(key, () => []).add(t);
    }

    final monthTotal = widget.transactions
        .where((t) {
          final d = t.createdAt.toLocal();
          final now = DateTime.now();
          return d.year == now.year && d.month == now.month;
        })
        .fold<int>(0, (s, t) => s + t.savedAmount);
    final monthVisits = widget.transactions.where((t) {
      final d = t.createdAt.toLocal();
      final now = DateTime.now();
      return d.year == now.year && d.month == now.month;
    }).length;

    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(loc.t('wallet_history_title')),
        ),
        body: SafeArea(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(loc.t('chart_no_data'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13.5, color: AppColors.textSecondary)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Kategoriya filtri
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _chip(null, loc.t('notif_tab_all'),
                              widget.transactions.length),
                          for (final c in _categories)
                            _chip(
                              c,
                              c,
                              widget.transactions
                                  .where((t) => t.categoryName == c)
                                  .length,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Oylik jami
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Bu oy jami',
                                    style: TextStyle(
                                        color: Colors.white60, fontSize: 11.5)),
                                Text('$monthVisits ta tashrif',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Tejagan',
                                  style: TextStyle(
                                      color: Colors.white60, fontSize: 11.5)),
                              Text('${_fmt(monthTotal)} $som',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key,
                                style: const TextStyle(
                                    fontSize: 12.5, fontWeight: FontWeight.w700)),
                            Text('${entry.value.length} ta',
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      for (var i = 0; i < entry.value.length; i++)
                        FadeSlideIn(
                          key: ValueKey(entry.value[i].id),
                          delay: Duration(milliseconds: i * 40),
                          child: _row(entry.value[i], som),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _chip(String? value, String label, int count) {
    final selected = _category == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _category = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text('$label $count',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _row(TransactionItem t, String som) {
    final local = t.createdAt.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(categoryIconFor(t.categoryName),
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13.5)),
                Text(
                  '${t.categoryName.isEmpty ? '—' : t.categoryName} · $time',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${_fmt(t.savedAmount)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: AppColors.primary)),
              Text('-${t.discountPercent}%',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
