import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import '../../core/category_icons.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../services/catalog_service.dart';
import '../../services/location_service.dart';

/// Xarita — OpenStreetMap tile'lari orqali HAQIQIY ko'chalar va bino
/// nomlarini ko'rsatadi (Google Maps API kaliti KERAK EMAS). Foydalanuvchi
/// o'z joylashuvini, atrofdagi bizneslarni va ulargacha bo'lgan masofani
/// ko'radi. Kategoriya, chegirma va masofa bo'yicha filtrlash mavjud.
class MapScreen extends StatefulWidget {
  /// Agar biror biznes ustiga bosib kelingan bo'lsa — xarita o'sha biznesga
  /// markazlashadi va uni belgilaydi (foydalanuvchi joylashuviga emas).
  final BusinessItem? focusBusiness;
  const MapScreen({super.key, this.focusBusiness});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapFilters {
  String? category;
  int minDiscount = 0;
  int maxDistanceKm = 5;
  bool openNow = false;
  bool premiumOnly = false;
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  List<CategoryItem> _categories = CatalogService.fallbackCategories;
  List<BusinessItem> _all = CatalogService.fallbackBusinesses;
  List<BusinessItem> _visible = CatalogService.fallbackBusinesses;
  final _filters = _MapFilters();
  final _searchController = TextEditingController();
  bool _searching = false;
  BusinessItem? _selected;

  double? _userLat;
  double? _userLng;
  bool _locatingUser = true;
  bool _locationDenied = false;

  final _recentSearches = <String>['Korzinka', 'Fresh Cut Barber', 'Evos'];

  // Qo'qon markazi — foydalanuvchi joylashuvi topilmaguncha boshlang'ich nuqta
  static const LatLng _defaultCenter = LatLng(40.5283, 70.9425);

  @override
  void initState() {
    super.initState();
    AppLocale.instance.addListener(_onLocaleChanged);
    // Biznes ustiga bosib kelingan bo'lsa — darhol o'sha biznesni belgilaymiz,
    // shunda xarita ochilishi bilan uning kartasi pastda ko'rinadi.
    _selected = widget.focusBusiness;
    _load();
    // Fokus rejimida boshlang'ich kamerani foydalanuvchiga surmaymiz — aks holda
    // bosilgan do'kon o'rniga foydalanuvchi joylashuvi ko'rsatilib qolardi.
    _loadLocation(moveCamera: widget.focusBusiness == null);
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
      // Faqat koordinatasi bor bizneslar xaritada ko'rsatiladi
      final withLoc = biz.where((b) => b.hasLocation).toList();
      _all = withLoc.isEmpty ? CatalogService.fallbackBusinesses : biz;
      _visible = _all;
    });
  }

  Future<void> _loadLocation({bool moveCamera = true}) async {
    setState(() => _locatingUser = true);
    final pos = await LocationService.instance.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _locatingUser = false;
      if (pos != null) {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
        _locationDenied = false;
      } else {
        _locationDenied = true;
      }
    });
    if (pos != null && moveCamera) {
      // Xaritani foydalanuvchi joylashuviga suramiz (ko'chalar ko'rinishi uchun
      // ko'chaga yaqin zoom — 16)
      _mapController.move(LatLng(pos.latitude, pos.longitude), 16);
    }
  }

  void _applyFilters() {
    setState(() {
      _visible = _all.where((b) {
        if (_filters.category != null && b.categoryName != _filters.category) return false;
        if (b.discountPercent < _filters.minDiscount) return false;
        if (_filters.premiumOnly && !b.isPremium) return false;
        if (_userLat != null && _userLng != null && b.hasLocation) {
          final km = LocationService.instance
              .distanceKm(_userLat!, _userLng!, b.latitude!, b.longitude!);
          if (km > _filters.maxDistanceKm) return false;
        }
        return true;
      }).toList();
    });
  }

  List<BusinessItem> get _displayed {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _visible;
    return _visible.where((b) {
      return b.name.toLowerCase().contains(q) ||
          b.categoryName.toLowerCase().contains(q) ||
          b.district.toLowerCase().contains(q);
    }).toList();
  }

  LatLng get _mapCenter {
    // Biznes ustiga bosib kelingan bo'lsa — o'sha do'kon markazda turadi.
    final f = widget.focusBusiness;
    if (f != null && f.hasLocation) {
      return LatLng(f.latitude!, f.longitude!);
    }
    if (_userLat != null && _userLng != null) {
      return LatLng(_userLat!, _userLng!);
    }
    final withLoc = _all.where((b) => b.hasLocation).toList();
    if (withLoc.isNotEmpty) {
      final avgLat = withLoc.map((b) => b.latitude!).reduce((a, b) => a + b) / withLoc.length;
      final avgLng = withLoc.map((b) => b.longitude!).reduce((a, b) => a + b) / withLoc.length;
      return LatLng(avgLat, avgLng);
    }
    return _defaultCenter;
  }

  /// Yagona xarita turi — Google "hybrid" (sun'iy yo'ldosh tasviri + ko'cha
  /// va joy nomlari). Rasmdagi Google Maps ko'rinishiga to'liq mos keladi.
  Widget _tileLayer() {
    return TileLayer(
      urlTemplate: 'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
      subdomains: const ['0', '1', '2', '3'],
      userAgentPackageName: 'com.iqbolmadaliyev.savin',
      maxNativeZoom: 20,
      maxZoom: 21,
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Bizneslar
    for (final b in _displayed.where((b) => b.hasLocation)) {
      final isSel = _selected?.id == b.id;
      markers.add(
        Marker(
          point: LatLng(b.latitude!, b.longitude!),
          width: isSel ? 78 : 66,
          height: isSel ? 60 : 52,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {
              setState(() => _selected = b);
              _mapController.move(
                  LatLng(b.latitude!, b.longitude!), _mapController.camera.zoom);
            },
            child: _BusinessPin(
              icon: categoryIconFor(b.categoryName),
              discount: b.discountPercent,
              selected: isSel,
              premium: b.isPremium,
            ),
          ),
        ),
      );
    }

    // Foydalanuvchi joylashuvi
    if (_userLat != null && _userLng != null) {
      markers.add(
        Marker(
          point: LatLng(_userLat!, _userLng!),
          width: 26,
          height: 26,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.5), blurRadius: 10),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  void _openFilterSheet() {
    final loc = AppLocale.instance;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.t('map_filter'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(loc.t('map_category'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(loc.t('common_all'), _filters.category == null, () {
                        setSheetState(() => _filters.category = null);
                      }),
                      for (final c in _categories.take(8))
                        _chip(
                          c.name,
                          _filters.category == c.name,
                          () => setSheetState(() => _filters.category = c.name),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(loc.t('map_discount'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _chip(loc.t('common_all'), _filters.minDiscount == 0,
                          () => setSheetState(() => _filters.minDiscount = 0)),
                      _chip('10%+', _filters.minDiscount == 10,
                          () => setSheetState(() => _filters.minDiscount = 10)),
                      _chip('20%+', _filters.minDiscount == 20,
                          () => setSheetState(() => _filters.minDiscount = 20)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(loc.t('map_distance'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final km in [1, 3, 5, 10])
                        _chip('$km km', _filters.maxDistanceKm == km,
                            () => setSheetState(() => _filters.maxDistanceKm = km)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primary,
                    title: Text(loc.t('map_open_now'), style: const TextStyle(fontSize: 14)),
                    value: _filters.openNow,
                    onChanged: (v) => setSheetState(() => _filters.openNow = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primary,
                    title: Text(loc.t('map_premium_only'), style: const TextStyle(fontSize: 14)),
                    value: _filters.premiumOnly,
                    onChanged: (v) => setSheetState(() => _filters.premiumOnly = v),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              _filters.category = null;
                              _filters.minDiscount = 0;
                              _filters.maxDistanceKm = 5;
                              _filters.openNow = false;
                              _filters.premiumOnly = false;
                            });
                          },
                          child: Text(loc.t('map_clear')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _applyFilters();
                          },
                          child: Text(loc.t('map_show')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }

  String _distanceLabel(BusinessItem b) {
    if (b.hasLocation && _userLat != null && _userLng != null) {
      final km = LocationService.instance
          .distanceKm(_userLat!, _userLng!, b.latitude!, b.longitude!);
      return LocationService.instance.formatDistance(km);
    }
    return b.district.isNotEmpty ? b.district : AppLocale.instance.t('map_no_location');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.instance;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              // Biznesga fokuslanganda ko'chaga yaqin (17), aks holda 15.5 —
              // ikkala holatda ham kichik ko'chalar va joy nomlari ko'rinadi.
              initialZoom: widget.focusBusiness != null ? 17 : 15.5,
              minZoom: 3,
              // maxNativeZoom 20 gacha — foydalanuvchi eng kichik ko'chalargacha
              // yaqinlashib ko'ra oladi (avval 18 da cheklangan edi).
              maxZoom: 20,
              onTap: (_, __) => setState(() => _selected = null),
            ),
            children: [
              _tileLayer(),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),

          // Yuqoridagi qidiruv paneli
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  FadeSlideIn(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back, size: 20),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onTap: () => setState(() => _searching = true),
                              onChanged: (v) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: loc.t('home_search_hint'),
                                border: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searching)
                            TextButton(
                              onPressed: () => setState(() {
                                _searching = false;
                                _searchController.clear();
                              }),
                              child: Text(loc.t('common_cancel')),
                            )
                          else if (_locatingUser)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.primary),
                              ),
                            )
                          else
                            IconButton(
                              onPressed: _openFilterSheet,
                              icon: const Icon(Icons.tune, size: 20, color: AppColors.primary),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_locationDenied && !_searching)
                    FadeSlideIn(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_off, color: AppColors.warning, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  loc.t('map_no_location'),
                                  style: const TextStyle(color: AppColors.warning, fontSize: 11.5)),
                            ),
                            TextButton(
                              onPressed: _loadLocation,
                              child: Text(loc.t('map_retry'), style: const TextStyle(fontSize: 11.5)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_searching)
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.t('map_recent_searches'),
                                style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 6),
                            for (final s in _recentSearches)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                leading: const Icon(Icons.history,
                                    size: 18, color: AppColors.textSecondary),
                                title: Text(s, style: const TextStyle(fontSize: 13.5)),
                                trailing: const Icon(Icons.north_west,
                                    size: 16, color: AppColors.textSecondary),
                                onTap: () => setState(() {
                                  _searchController.text = s;
                                  _searching = false;
                                }),
                              ),
                            const SizedBox(height: 8),
                            Text(loc.t('map_popular'),
                                style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final c in ['Barber', 'Restoran', 'Fitness', 'Tibbiyot', 'Kiyim'])
                                  _chip(c, false, () => setState(() {
                                        _searchController.text = c;
                                        _searching = false;
                                      })),
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

          // "Meni joylashtir" tugmasi
          if (!_searching)
            Positioned(
              right: 16,
              bottom: _selected != null ? 150 : 24,
              child: FloatingActionButton.small(
                heroTag: 'locate_me',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                onPressed: _loadLocation,
                child: const Icon(Icons.my_location),
              ),
            ),

          // OSM atribusiyasi (litsenziya talabi)
          Positioned(
            left: 8,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: Colors.white.withValues(alpha: 0.7),
              child: const Text('© Google',
                  style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
            ),
          ),

          // Tanlangan biznes kartasi
          if (_selected != null && !_searching)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: FadeSlideIn(
                offsetY: 30,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: Icon(categoryIconFor(_selected!.categoryName),
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selected!.name,
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                                '${_selected!.categoryName} · ${_distanceLabel(_selected!)}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.textSecondary, fontSize: 12)),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 12, color: AppColors.textSecondary),
                                Text(' ${_selected!.rating.toStringAsFixed(1)}',
                                    style: const TextStyle(fontSize: 11)),
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
                        child: Text('-${_selected!.discountPercent}%',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Xaritadagi biznes belgisi (pin) — kategoriya emoji + chegirma foizi.
class _BusinessPin extends StatelessWidget {
  final IconData icon;
  final int discount;
  final bool selected;
  final bool premium;
  const _BusinessPin({
    required this.icon,
    required this.discount,
    required this.selected,
    required this.premium,
  });

  @override
  Widget build(BuildContext context) {
    final color = premium ? AppColors.primaryDark : AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 13),
              const SizedBox(width: 3),
              Text('-$discount%',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        // Pastga qaragan uchburchak (pin uchi)
        CustomPaint(
          size: const Size(12, 7),
          painter: _PinTailPainter(color),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  _PinTailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) => oldDelegate.color != color;
}
