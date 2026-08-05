import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/category_icons.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_builder.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../services/catalog_service.dart';
import '../../services/favorites_service.dart';
import '../../services/providers.dart';
import '../map/map_screen.dart';

/// Biznes tafsiloti (dizayn: "Biznes karta — Detail").
///
/// Yuqorida yashil "hero" qism, chegirma belgisi, sevimlilar tugmasi;
/// pastda reyting/masofa/ish vaqti, tavsif, xizmatlar, manzil va
/// "QR ko'rsatish" tugmasi.
class BusinessDetailScreen extends ConsumerStatefulWidget {
  final BusinessItem business;
  const BusinessDetailScreen({super.key, required this.business});

  @override
  ConsumerState<BusinessDetailScreen> createState() =>
      _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends ConsumerState<BusinessDetailScreen> {
  final _fav = FavoritesService.instance;

  BusinessItem get b => widget.business;

  @override
  void initState() {
    super.initState();
    _fav.addListener(_onChanged);
  }

  @override
  void dispose() {
    _fav.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleFavorite() async {
    final added = await _fav.toggle(b.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocale.instance.t(added ? 'fav_added' : 'fav_removed')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openQr() {
    // QR tabga o'tamiz — mijoz kassirga shu kodni ko'rsatadi
    ref.read(mainShellIndexProvider.notifier).state = 2;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _openMap() {
    Navigator.of(context).push(AppPageRoute(page: MapScreen(focusBusiness: b)));
  }

  /// "Yo'l ko'rsatish" — dizayndagi tanlash oynasi (Google Maps / Yandex).
  void _openDirections() {
    if (!b.hasLocation) {
      _openMap();
      return;
    }
    final lat = b.latitude!;
    final lng = b.longitude!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DirectionsSheet(
        name: b.name,
        district: b.district,
        onGoogle: () => _launch('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
        onYandex: () => _launch('https://yandex.uz/maps/?rtext=~$lat,$lng&rtt=auto'),
        onCopy: () async {
          await Clipboard.setData(ClipboardData(text: '$lat, $lng'));
        },
        onInApp: _openMap,
      ),
    );
  }

  Future<void> _launch(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) _openMap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFav = _fav.isFavorite(b.id);

    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ---------------- Hero ----------------
            Stack(
              children: [
                Container(
                  height: 210,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, Color(0xFF2BA94A)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(categoryIconFor(b.categoryName),
                      size: 74, color: Colors.white.withValues(alpha: 0.9)),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          _circleButton(Icons.arrow_back,
                              onTap: () => Navigator.of(context).pop()),
                          const Spacer(),
                          _circleButton(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            onTap: _toggleFavorite,
                            color: isFav ? AppColors.danger : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          _circleButton(Icons.north_east, onTap: _openMap),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(14)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('-${b.discountPercent}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        const Text('CHEGIRMA',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                letterSpacing: 1)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeSlideIn(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(b.name,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                        ),
                        if (b.isPremium) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              size: 20, color: AppColors.primary),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${b.categoryName}${b.isPremium ? ' • Premium' : ''}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Reyting / masofa / ish vaqti
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _metric(Icons.star, b.rating.toStringAsFixed(1),
                              '127 ${loc.t('biz_reviews')}'),
                          _divider(),
                          _metric(Icons.place_outlined,
                              b.district.isEmpty ? '—' : b.district, ''),
                          _divider(),
                          _metric(Icons.schedule, loc.t('biz_open'),
                              '08:00—22:00'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(loc.t('biz_about'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    '${b.name} — ${b.categoryName.toLowerCase()} yo\'nalishidagi '
                    'Savin hamkori. Savin a\'zolari uchun doimiy '
                    '${b.discountPercent}% chegirma amal qiladi. Chegirmani '
                    'olish uchun kassirga ilovadagi QR kodni ko\'rsating.',
                    style: const TextStyle(
                        fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  Text(loc.t('biz_services'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final s in _sampleServices(b))
                        Expanded(child: _serviceCard(s.$1, s.$2)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Manzil
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: InkWell(
                      onTap: _openDirections,
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
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.navigation,
                                  size: 17, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.district.isEmpty
                                        ? loc.t('biz_on_map')
                                        : b.district,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5),
                                  ),
                                  Text(loc.t('biz_directions'),
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _toggleFavorite,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(56, 52),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? AppColors.danger : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openQr,
                          icon: const Icon(Icons.qr_code_2, size: 20),
                          label: Text(loc.t('biz_show_qr')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<(String, String)> _sampleServices(BusinessItem b) {
    // Xizmat katalogi mijoz API'sida hali yo'q — kategoriya bo'yicha
    // tushunarli namunalar ko'rsatiladi (narxlar biznesda aniqlanadi).
    return switch (b.categoryName.toLowerCase()) {
      'barber' => [('Soch', '80K'), ('Soqol', '40K'), ('Kombo', '100K')],
      'restoran' || 'kafe' => [
          ('Asosiy taom', '45K'),
          ('Ichimlik', '15K'),
          ('Shirinlik', '25K')
        ],
      'fitness' => [('1 kun', '30K'), ('Oylik', '350K'), ('Yillik', '3M')],
      'salon' => [('Soch', '120K'), ('Manikyur', '90K'), ('Makiyaj', '150K')],
      _ => [('Xizmat', '—'), ('Xizmat', '—'), ('Xizmat', '—')],
    };
  }

  Widget _serviceCard(String title, String price) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(price,
              style: const TextStyle(
                  fontSize: 11.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String value, String sub) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (sub.isNotEmpty)
            Text(sub,
                style: const TextStyle(
                    fontSize: 10.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 28, color: AppColors.border);

  Widget _circleButton(IconData icon,
      {required VoidCallback onTap, Color color = Colors.white}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 19, color: color),
      ),
    );
  }
}

/// "Yo'l ko'rsatish — qaysi ilovada ochishni tanlang" oynasi.
class _DirectionsSheet extends StatelessWidget {
  final String name;
  final String district;
  final VoidCallback onGoogle;
  final VoidCallback onYandex;
  final VoidCallback onInApp;
  final Future<void> Function() onCopy;

  const _DirectionsSheet({
    required this.name,
    required this.district,
    required this.onGoogle,
    required this.onYandex,
    required this.onInApp,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.instance;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(loc.t('biz_directions'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('$name${district.isEmpty ? '' : ' · $district'}',
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          _row(context, Icons.map_outlined, 'Savin xaritasi', 'Ilova ichida',
              onInApp),
          _row(context, Icons.travel_explore, 'Google Maps', 'Standart navigator',
              onGoogle),
          _row(context, Icons.navigation_outlined, 'Yandex Navi',
              "O'zbekiston uchun optimal", onYandex),
          _row(context, Icons.copy, 'Manzilni nusxalash', '', () async {
            await onCopy();
            if (context.mounted) Navigator.of(context).pop();
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bekor qilish'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String title, String sub,
      VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                  if (sub.isNotEmpty)
                    Text(sub,
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
