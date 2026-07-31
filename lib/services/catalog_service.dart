import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/constants.dart';

/// Katalog ma'lumotlari (kategoriyalar, bizneslar).
/// Server ishlamasa ham ilova chiroyli ko'rinishi uchun har bir metodda
/// zaxira (fallback) demo-ma'lumotlar bor.
class CategoryItem {
  final String id;
  final String name;
  final String icon; // emoji
  final int discountMin;
  final int discountMax;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    this.discountMin = 0,
    this.discountMax = 0,
  });

  String get discountLabel =>
      discountMax > 0 ? '$discountMin-$discountMax%' : '';

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        icon: json['icon'] as String? ?? '🏷️',
        discountMin: json['discount_min'] as int? ?? 0,
        discountMax: json['discount_max'] as int? ?? 0,
      );
}

class BusinessItem {
  final String id;
  final String name;
  final String categoryName;
  final int discountPercent;
  final double rating;
  final String district;
  final bool isPremium;
  final double? latitude;
  final double? longitude;

  const BusinessItem({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.discountPercent,
    this.rating = 4.5,
    this.district = '',
    this.isPremium = false,
    this.latitude,
    this.longitude,
  });

  /// Haqiqiy koordinatasi bormi (backend/demo ma'lumotida)?
  bool get hasLocation => latitude != null && longitude != null;

  factory BusinessItem.fromJson(Map<String, dynamic> json) => BusinessItem(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        categoryName: json['category_name'] as String? ?? '',
        discountPercent: json['discount_percent'] as int? ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
        district: json['district'] as String? ?? '',
        isPremium: json['is_premium'] as bool? ?? false,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}

class CatalogService {
  CatalogService._internal();
  static final CatalogService instance = CatalogService._internal();

  final Dio _dio = ApiClient.instance.dio;

  // Server ishlamay qolsa ko'rsatiladigan zaxira ma'lumotlar
  static const List<CategoryItem> fallbackCategories = [
    CategoryItem(id: '1', name: 'Restoran', icon: '🍽️', discountMin: 10, discountMax: 15),
    CategoryItem(id: '2', name: 'Kafe', icon: '☕', discountMin: 5, discountMax: 10),
    CategoryItem(id: '3', name: 'Barber', icon: '💈', discountMin: 20, discountMax: 40),
    CategoryItem(id: '4', name: 'Salon', icon: '💇‍♀️', discountMin: 15, discountMax: 30),
    CategoryItem(id: '5', name: 'Fitness', icon: '🏋️', discountMin: 10, discountMax: 25),
    CategoryItem(id: '6', name: 'Supermarket', icon: '🛒', discountMin: 5, discountMax: 10),
    CategoryItem(id: '7', name: 'Tibbiyot', icon: '🏥', discountMin: 10, discountMax: 20),
    CategoryItem(id: '8', name: 'Kiyim', icon: '👗', discountMin: 10, discountMax: 20),
    CategoryItem(id: '9', name: "Ta'lim", icon: '📚', discountMin: 10, discountMax: 15),
  ];

  // QO'QON bo'ylab haqiqiy koordinatalar bilan — xaritada to'g'ri joylashadi.
  static const List<BusinessItem> fallbackBusinesses = [
    BusinessItem(id: '1', name: 'Fresh Cut Barber', categoryName: 'Barber',
        discountPercent: 35, rating: 4.9, district: "Qo'qon markaz", isPremium: true,
        latitude: 40.5290, longitude: 70.9420),
    BusinessItem(id: '2', name: "Korzinka Qo'qon", categoryName: 'Supermarket',
        discountPercent: 10, rating: 4.5, district: 'Istiqlol',
        latitude: 40.5312, longitude: 70.9451),
    BusinessItem(id: '3', name: 'Milano Restoran', categoryName: 'Restoran',
        discountPercent: 15, rating: 4.8, district: "Qo'qon markaz",
        latitude: 40.5266, longitude: 70.9438),
    BusinessItem(id: '4', name: 'Glow Beauty Salon', categoryName: 'Salon',
        discountPercent: 30, rating: 4.6, district: "Do'stlik", isPremium: true,
        latitude: 40.5341, longitude: 70.9392),
    BusinessItem(id: '5', name: 'Power Gym', categoryName: 'Fitness',
        discountPercent: 20, rating: 4.7, district: 'Furqat',
        latitude: 40.5231, longitude: 70.9481),
    BusinessItem(id: '6', name: 'Shifo Klinika', categoryName: 'Tibbiyot',
        discountPercent: 20, rating: 4.8, district: 'Turon', isPremium: true,
        latitude: 40.5352, longitude: 70.9502),
    BusinessItem(id: '7', name: 'Zara Style', categoryName: 'Kiyim',
        discountPercent: 18, rating: 4.6, district: 'Markaz',
        latitude: 40.5281, longitude: 70.9411),
    BusinessItem(id: '8', name: 'FitZone', categoryName: 'Fitness',
        discountPercent: 25, rating: 4.7, district: 'Amir Temur',
        latitude: 40.5252, longitude: 70.9522),
    BusinessItem(id: '9', name: "Evos Qo'qon", categoryName: 'Restoran',
        discountPercent: 15, rating: 4.5, district: 'Istiqlol',
        latitude: 40.5301, longitude: 70.9432),
    BusinessItem(id: '10', name: 'Choco Cafe', categoryName: 'Kafe',
        discountPercent: 10, rating: 4.7, district: 'Markaz',
        latitude: 40.5276, longitude: 70.9456),
    BusinessItem(id: '11', name: 'MediPlus', categoryName: 'Tibbiyot',
        discountPercent: 12, rating: 4.6, district: 'Furqat',
        latitude: 40.5221, longitude: 70.9401),
    BusinessItem(id: '12', name: "Makro Qo'qon", categoryName: 'Supermarket',
        discountPercent: 8, rating: 4.4, district: 'Turon',
        latitude: 40.5361, longitude: 70.9471),
    BusinessItem(id: '13', name: 'Denim House', categoryName: 'Kiyim',
        discountPercent: 15, rating: 4.5, district: "Do'stlik",
        latitude: 40.5331, longitude: 70.9521),
    BusinessItem(id: '14', name: 'Beauty Lab', categoryName: 'Salon',
        discountPercent: 30, rating: 4.8, district: 'Markaz', isPremium: true,
        latitude: 40.5286, longitude: 70.9445),
  ];

  Future<List<CategoryItem>> fetchCategories() async {
    try {
      final response = await _dio.get(ApiConstants.categories);
      final data = response.data;
      final list = data is List ? data : (data['results'] as List? ?? []);
      final items = list
          .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return items.isEmpty ? fallbackCategories : items;
    } catch (_) {
      return fallbackCategories;
    }
  }

  Future<List<BusinessItem>> fetchBusinesses({String? categoryId, String? search}) async {
    final hasFilter = categoryId != null || (search != null && search.trim().isNotEmpty);
    try {
      final params = <String, dynamic>{};
      if (categoryId != null) params['category'] = categoryId;
      if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
      final response = await _dio.get(
        ApiConstants.businesses,
        queryParameters: params.isEmpty ? null : params,
      );
      final data = response.data;
      final list = data is List ? data : (data['results'] as List? ?? []);
      final items = list
          .map((e) => BusinessItem.fromJson(e as Map<String, dynamic>))
          .toList();
      // MUHIM: filtr/qidiruv qo'llanilganda bo'sh natija ham HAQIQIY
      // natija — bunda zaxira (fallback) ro'yxatga qaytilmaydi, aks holda
      // "hech narsa topilmadi" holati noto'g'ri ravishda to'liq demo
      // ro'yxat bilan almashtirilib, qidiruv ishlamayotgandek ko'rinardi.
      if (items.isEmpty && !hasFilter) return fallbackBusinesses;
      return items;
    } catch (_) {
      return hasFilter ? const [] : fallbackBusinesses;
    }
  }
}
