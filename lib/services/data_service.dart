import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/category.dart';
import '../models/business.dart';

class DataService {
  DataService._internal();
  static final DataService instance = DataService._internal();

  final Dio _dio = ApiClient.instance.dio;

  Future<List<AppCategory>> getCategories() async {
    try {
      final response = await _dio.get(ApiConstants.categories);
      final List data = response.data;
      return data.map((e) => AppCategory.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Business>> getBusinesses() async {
    try {
      final response = await _dio.get(ApiConstants.businesses);
      final List data = response.data;
      return data.map((e) => Business.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
