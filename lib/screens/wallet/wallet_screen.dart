import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../services/wallet_service.dart';
import 'purchase_history_screen.dart';
import 'savings_chart_screen.dart';

/// Hamyon burger menyusidagi bitta variant (grafik / tarix).
class _WalletMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _WalletMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 21, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

const _uzMonths = [
  'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun',
  'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr',
];
const _ruMonths = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];
const _enMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  final code = AppLocale.instance.code;
  final months = code == 'ru' ? _ruMonths : (code == 'en' ? _enMonths : _uzMonths);
  return '${local.day} ${months[local.month - 1]}, $hh:$mm';
}

String _formatSum(num v) {
  final s = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    buf.write(s[i]);
    final left = s.length - i - 1;
    if (left > 0 && left % 3 == 0) buf.write(' ');
  }
  return "${buf.toString()} ${AppLocale.instance.t('wallet_som')}";
}

/// Hamyon — endi HAQIQIY ma'lumot bilan ishlaydi: statistika va tranzaksiya
/// tarixi backenddagi /transactions/ va /transactions/stats/ dan keladi.
/// Ilgari bu ekrandagi barcha raqamlar (18 ta tashrif, 22%, 1.4M va h.k.)
/// frontendda qattiq yozilgan (fake) edi.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _loading = true;
  bool _error = false;
  WalletStats _stats = const WalletStats();
  List<TransactionItem> _transactions = const [];

  @override
  void initState() {
    super.initState();
    // Til o'zgarganda ekran darhol qayta chizilishi uchun
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
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final results = await Future.wait([
        WalletService.instance.fetchStats(),
        WalletService.instance.fetchTransactions(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as WalletStats;
        _transactions = results[1] as List<TransactionItem>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  /// Hamyon menyusi (dizayn: sarlavhaning o'ng burchagidagi burger).
  /// Ikkitadan biri tanlanadi: tejash grafigi yoki xarid tarixi.
  void _openWalletMenu() {
    final loc = AppLocale.instance;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(loc.t('wallet_menu_title'),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              _WalletMenuTile(
                icon: Icons.bar_chart_rounded,
                title: loc.t('wallet_chart_title'),
                subtitle: loc.t('wallet_chart_sub'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    AppPageRoute(
                      page: SavingsChartScreen(transactions: _transactions),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _WalletMenuTile(
                icon: Icons.receipt_long_outlined,
                title: loc.t('wallet_history_title'),
                subtitle: loc.t('wallet_history_sub'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    AppPageRoute(
                      page: PurchaseHistoryScreen(transactions: _transactions),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(loc.t('common_cancel'),
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(String title, List<TransactionItem> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TransactionDetailSheet(title: title, items: items),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.instance;
    final hasData = !_loading && !_error;
    final byCategoryEntries = _stats.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
                    child: Text(loc.t('wallet_title'),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                  // Dizayndagi burger ikonka: bosilganda "Tejash grafigi" yoki
                  // "Xarid tarixi" tanlanadigan oyna ochiladi.
                  IconButton(
                    tooltip: loc.t('wallet_menu_title'),
                    onPressed: _openWalletMenu,
                    icon: const Icon(Icons.menu_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, Color(0xFF14522F)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withAlpha(77),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.t('wallet_saved_month'),
                        style: const TextStyle(color: Colors.white60, fontSize: 13)),
                    const SizedBox(height: 6),
                    _loading
                        ? const SizedBox(
                            height: 36, width: 36,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white54))
                        : CountUpText(
                            value: _stats.savedThisMonth.toDouble(),
                            formatter: _formatSum,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700),
                          ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined,
                              color: AppColors.primary, size: 15),
                          const SizedBox(width: 4),
                          Text(
                              "${loc.t('wallet_saved_total')}: ${_formatSum(_stats.savedAllTime)}",
                              style: const TextStyle(
                                  color: AppColors.primary, fontSize: 11.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: Row(
                children: [
                  _StatBox(
                    value: _loading ? '—' : '${_stats.visits}',
                    label: loc.t('wallet_visits'),
                    onTap: hasData
                        ? () => _openDetail(loc.t('wallet_visits'), _transactions)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  _StatBox(
                    value: _loading ? '—' : '${_stats.avgDiscountPercent.toStringAsFixed(0)}%',
                    label: loc.t('wallet_avg_percent'),
                    onTap: hasData
                        ? () => _openDetail(loc.t('wallet_avg_percent'), _transactions)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  _StatBox(
                    value: _loading ? '—' : _formatSum(_stats.savedThisYear).replaceAll(" so'm", ''),
                    label: loc.t('wallet_saved_year'),
                    onTap: hasData
                        ? () => _openDetail(
                            loc.t('wallet_saved_year'),
                            _transactions
                                .where((t) => t.createdAt.year == DateTime.now().year)
                                .toList())
                        : null,
                  ),
                ],
              ),
            ),
            if (_error) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: AppColors.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          loc.t('wallet_error'),
                          style: const TextStyle(color: AppColors.warning, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
            if (hasData && _transactions.isEmpty) ...[
              const SizedBox(height: 32),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: const BoxDecoration(
                            color: AppColors.surface, shape: BoxShape.circle),
                        child: const Icon(Icons.receipt_long_outlined,
                            color: AppColors.textSecondary, size: 28),
                      ),
                      const SizedBox(height: 14),
                      Text(loc.t('wallet_no_history'),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                            loc.t('wallet_no_history_sub'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (hasData && byCategoryEntries.isNotEmpty) ...[
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 220),
                child: Text(loc.t('wallet_by_category'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              const SizedBox(height: 12),
              // Dizayn (photo_14): kategoriyalar bo'yicha halqali (donut)
              // diagramma — markazda jami summa, yonida rangli legenda.
              FadeSlideIn(
                delay: const Duration(milliseconds: 280),
                child: _CategoryDonut(entries: byCategoryEntries),
              ),
            ],
            if (hasData && _transactions.isNotEmpty) ...[
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 340),
                child: Text(loc.t('wallet_recent_tx'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 400),
                child: Column(
                  children: _transactions.take(8).map((t) {
                    return _TxRow(
                      tx: t,
                      onTap: () => _openDetail(t.businessName, [t]),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;
  const _StatBox({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PressableScale(
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dizayndagi (photo_14, 2-kadr) kabi kategoriyalar bo'yicha halqali
/// diagramma: markazda jami summa, o'ng tomonda rangli legenda (nom + %).
class _CategoryDonut extends StatelessWidget {
  final List<MapEntry<String, int>> entries;
  const _CategoryDonut({required this.entries});

  static const _palette = [
    AppColors.primary,      // yashil
    Color(0xFFF5A623),      // to'q sariq
    Color(0xFF4A90D9),      // ko'k
    Color(0xFF9B59B6),      // binafsha
    Color(0xFF9AA0A6),      // kulrang (boshqalar)
  ];

  String _short(num v) {
    if (v >= 1000000) {
      final m = v / 1000000;
      return '${m.toStringAsFixed(m >= 10 ? 0 : 1)}M';
    }
    if (v >= 1000) return '${(v / 1000).round()}K';
    return v.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);
    if (total <= 0) return const SizedBox.shrink();
    final shown = entries.take(_palette.length).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    startDegreeOffset: -90,
                    sections: [
                      for (var i = 0; i < shown.length; i++)
                        PieChartSectionData(
                          value: shown[i].value.toDouble(),
                          color: _palette[i],
                          radius: 16,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_short(total),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18)),
                    Text(AppLocale.instance.t('wallet_som'),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < shown.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: _palette[i], shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(shown[i].key,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5)),
                        ),
                        Text('${(shown[i].value * 100 / total).round()}%',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final TransactionItem tx;
  final VoidCallback? onTap;
  const _TxRow({required this.tx, this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap ?? () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(
                tx.businessName.isNotEmpty ? tx.businessName[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.businessName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(
                      '${tx.categoryName} · ${_formatDateTime(tx.createdAt)}'
                      '${tx.district.isNotEmpty ? ' · ${tx.district}' : ''}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("+${_formatSum(tx.savedAmount)}",
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
                Text('-${tx.discountPercent}%',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Statistik kartani (Tashriflar / O'rtacha % / Jami) bosganda ochiladigan
/// tafsilot ro'yxati — "necha so'm, qachon, qayerda" savoliga javob beradi.
class _TransactionDetailSheet extends StatelessWidget {
  final String title;
  final List<TransactionItem> items;
  const _TransactionDetailSheet({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text("Bu bo'yicha ma'lumot topilmadi",
                    style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 20),
                  itemBuilder: (context, i) {
                    final t = items[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(t.businessName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 14)),
                            ),
                            Text('-${t.discountPercent}%',
                                style: const TextStyle(
                                    color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.category_outlined,
                                    size: 13, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(t.categoryName.isEmpty ? 'Boshqa' : t.categoryName,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule,
                                    size: 13, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(_formatDateTime(t.createdAt),
                                    style: const TextStyle(
                                        color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                            if (t.district.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.place_outlined,
                                      size: 13, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(t.district,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                            "Asl narx: ${_formatSum(t.originalAmount)}  ·  Tejaldi: ${_formatSum(t.savedAmount)}",
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
