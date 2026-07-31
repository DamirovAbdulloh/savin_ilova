import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/constants.dart';

/// Bitta tranzaksiya (chegirmadan foydalanish yozuvi).
class TransactionItem {
  final String id;
  final String businessName;
  final String categoryName;
  final String district;
  final int discountPercent;
  final int originalAmount;
  final int savedAmount;
  final DateTime createdAt;

  const TransactionItem({
    required this.id,
    required this.businessName,
    required this.categoryName,
    this.district = '',
    required this.discountPercent,
    required this.originalAmount,
    required this.savedAmount,
    required this.createdAt,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
        id: json['id']?.toString() ?? '',
        businessName: json['business_name'] as String? ?? '',
        categoryName: json['category_name'] as String? ?? '',
        district: json['district'] as String? ?? '',
        discountPercent: json['discount_percent'] as int? ?? 0,
        originalAmount: json['original_amount'] as int? ?? 0,
        savedAmount: json['saved_amount'] as int? ?? 0,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Hamyon statistikasi — backenddagi /transactions/stats/ dan keladi.
/// MUHIM: bu raqamlar endi HAQIQIY — foydalanuvchining o'zi hali birorta
/// ham chegirmadan foydalanmagan bo'lsa, hammasi 0 bo'ladi (ilgari bu
/// yerda doim "18 ta tashrif / 1.4M so'm" kabi qattiq yozilgan soxta
/// raqamlar ko'rsatilardi).
class WalletStats {
  final int visits;
  final double avgDiscountPercent;
  final int savedThisMonth;
  final int savedThisYear;
  final int savedAllTime;
  final Map<String, int> byCategory;

  const WalletStats({
    this.visits = 0,
    this.avgDiscountPercent = 0,
    this.savedThisMonth = 0,
    this.savedThisYear = 0,
    this.savedAllTime = 0,
    this.byCategory = const {},
  });

  factory WalletStats.fromJson(Map<String, dynamic> json) => WalletStats(
        visits: json['visits'] as int? ?? 0,
        avgDiscountPercent: (json['avg_discount_percent'] as num?)?.toDouble() ?? 0,
        savedThisMonth: json['saved_this_month'] as int? ?? 0,
        savedThisYear: json['saved_this_year'] as int? ?? 0,
        savedAllTime: json['saved_all_time'] as int? ?? 0,
        byCategory: (json['by_category'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
      );
}

class WalletService {
  WalletService._internal();
  static final WalletService instance = WalletService._internal();

  final Dio _dio = ApiClient.instance.dio;

  Future<List<TransactionItem>> fetchTransactions() async {
    final response = await _dio.get(ApiConstants.transactions);
    final data = response.data;
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => TransactionItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<WalletStats> fetchStats() async {
    final response = await _dio.get(ApiConstants.transactionStats);
    return WalletStats.fromJson(response.data as Map<String, dynamic>);
  }

  /// QR kassada tasdiqlanganda (yoki demo namunasida) yangi tranzaksiya
  /// yaratadi. `businessId` bo'lmasa ham ishlaydi (demo/kassa integratsiyasi
  /// hali yo'q holatlar uchun) — faqat nom/toifa/summani saqlaydi.
  Future<TransactionItem> redeem({
    String? businessId,
    required String businessName,
    required String categoryName,
    String district = '',
    required int discountPercent,
    required int originalAmount,
  }) async {
    final response = await _dio.post(ApiConstants.transactions, data: {
      if (businessId != null) 'business': businessId,
      'business_name': businessName,
      'category_name': categoryName,
      'district': district,
      'discount_percent': discountPercent,
      'original_amount': originalAmount,
    });
    return TransactionItem.fromJson(response.data as Map<String, dynamic>);
  }
}
