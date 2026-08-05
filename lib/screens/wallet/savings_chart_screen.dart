import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_builder.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../services/wallet_service.dart';

/// "Tejash grafigi" (dizayn: Hamyon — Tejash grafigi).
///
/// Hafta / Oy / 6 oy / Yil kesimida tejalgan summa ustunli diagrammada
/// ko'rsatiladi. Ma'lumot mijozning HAQIQIY tranzaksiyalaridan olinadi.
class SavingsChartScreen extends StatefulWidget {
  final List<TransactionItem> transactions;
  const SavingsChartScreen({super.key, required this.transactions});

  @override
  State<SavingsChartScreen> createState() => _SavingsChartScreenState();
}

enum _Range { week, month, halfYear, year }

class _SavingsChartScreenState extends State<SavingsChartScreen> {
  _Range _range = _Range.month;

  /// Tanlangan davr uchun (yorliq, summa) juftliklari.
  List<(String, int)> get _buckets {
    final now = DateTime.now();
    final tx = widget.transactions;

    switch (_range) {
      case _Range.week:
        return List.generate(7, (i) {
          final day = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: 6 - i));
          final sum = tx
              .where((t) => _sameDay(t.createdAt.toLocal(), day))
              .fold<int>(0, (s, t) => s + t.savedAmount);
          return ('${day.day}', sum);
        });
      case _Range.month:
        final days = DateTime(now.year, now.month + 1, 0).day;
        return List.generate(days, (i) {
          final day = DateTime(now.year, now.month, i + 1);
          final sum = tx
              .where((t) => _sameDay(t.createdAt.toLocal(), day))
              .fold<int>(0, (s, t) => s + t.savedAmount);
          return ('${i + 1}', sum);
        });
      case _Range.halfYear:
        return List.generate(6, (i) {
          final m = DateTime(now.year, now.month - 5 + i);
          final sum = tx
              .where((t) =>
                  t.createdAt.toLocal().year == m.year &&
                  t.createdAt.toLocal().month == m.month)
              .fold<int>(0, (s, t) => s + t.savedAmount);
          return (_monthShort(m.month), sum);
        });
      case _Range.year:
        return List.generate(12, (i) {
          final sum = tx
              .where((t) =>
                  t.createdAt.toLocal().year == now.year &&
                  t.createdAt.toLocal().month == i + 1)
              .fold<int>(0, (s, t) => s + t.savedAmount);
          return (_monthShort(i + 1), sum);
        });
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthShort(int m) {
    const names = [
      'yan', 'fev', 'mar', 'apr', 'may', 'iyn',
      'iyl', 'avg', 'sen', 'okt', 'noy', 'dek',
    ];
    final index = ((m - 1) % 12 + 12) % 12;
    return names[index];
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

  @override
  Widget build(BuildContext context) {
    final buckets = _buckets;
    final total = buckets.fold<int>(0, (s, b) => s + b.$2);
    final activeDays = buckets.where((b) => b.$2 > 0).length;
    final best = buckets.isEmpty
        ? 0
        : buckets.map((b) => b.$2).reduce((a, b) => a > b ? a : b);
    final avg = activeDays == 0 ? 0 : (total / activeDays).round();
    final maxY = (best == 0 ? 1 : best).toDouble();

    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(loc.t('wallet_chart_title')),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              FadeSlideIn(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _rangeTab(_Range.week, loc.t('range_week')),
                      _rangeTab(_Range.month, loc.t('range_month')),
                      _rangeTab(_Range.halfYear, loc.t('range_6m')),
                      _rangeTab(_Range.year, loc.t('range_year')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_rangeLabel(loc).toUpperCase(),
                          style: const TextStyle(
                              fontSize: 10.5,
                              letterSpacing: 0.6,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(_fmt(total),
                              style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 6),
                          Text(AppLocale.instance.t('wallet_som'),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: total == 0
                            ? Center(
                                child: Text(loc.t('chart_no_data'),
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary)),
                              )
                            : BarChart(
                                BarChartData(
                                  maxY: maxY * 1.15,
                                  alignment: BarChartAlignment.spaceAround,
                                  borderData: FlBorderData(show: false),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: maxY / 2,
                                    getDrawingHorizontalLine: (_) => const FlLine(
                                        color: AppColors.border, strokeWidth: 1),
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 22,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          final i = value.toInt();
                                          if (i < 0 || i >= buckets.length) {
                                            return const SizedBox.shrink();
                                          }
                                          // Kunlar ko'p bo'lsa har 5-chisi
                                          final step =
                                              buckets.length > 12 ? 5 : 1;
                                          if (i % step != 0) {
                                            return const SizedBox.shrink();
                                          }
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(buckets[i].$1,
                                                style: const TextStyle(
                                                    fontSize: 9.5,
                                                    color: AppColors
                                                        .textSecondary)),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem: (group, _, rod, __) =>
                                          BarTooltipItem(
                                        '${_fmt(rod.toY)} ${AppLocale.instance.t('wallet_som')}',
                                        const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                  barGroups: [
                                    for (var i = 0; i < buckets.length; i++)
                                      BarChartGroupData(
                                        x: i,
                                        barRods: [
                                          BarChartRodData(
                                            toY: buckets[i].$2.toDouble(),
                                            width: buckets.length > 12 ? 5 : 12,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: Row(
                  children: [
                    _metric(_fmt(avg), loc.t('chart_avg_day')),
                    _metric(_fmt(best), loc.t('chart_best_day')),
                    _metric('$activeDays', loc.t('chart_active_days')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _rangeLabel(dynamic loc) => switch (_range) {
        _Range.week => loc.t('range_week'),
        _Range.month => loc.t('range_month'),
        _Range.halfYear => loc.t('range_6m'),
        _Range.year => loc.t('range_year'),
      };

  Widget _rangeTab(_Range value, String label) {
    final selected = _range == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _range = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      selected ? AppColors.textPrimary : AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
