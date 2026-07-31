import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/storage/token_storage.dart';
import '../models/user.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Auth bilan bog'liq barcha tarmoq amallari shu yerda jamlangan.
/// Har bir metod xatolikni AuthException ko'rinishida qaytaradi,
/// shunda UI qatlamida foydalanuvchiga tushunarli xabar ko'rsatish oson bo'ladi.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final Dio _dio = ApiClient.instance.dio;

  /// Ro'yxatdan o'tish (ism, familiya, telefon).
  /// Server javobini qaytaradi — dev rejimda unda `dev_otp` (test SMS kodi) bo'ladi.
  Future<Map<String, dynamic>> register({
    required String firstName,
    String? lastName,
    required String phoneNumber,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.register, data: {
        'first_name': firstName,
        if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        'phone_number': phoneNumber,
      });
      return (response.data as Map<String, dynamic>?) ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw AuthException(_extractError(e));
    }
  }

  /// Login — SMS kod tasdiqlangandan keyin.
  /// Backend javobi: { access, refresh, user: {...} }
  Future<AppUser> login({required String phoneNumber, String? otpCode, String? password}) async {
    try {
      final response = await _dio.post(ApiConstants.login, data: {
        'phone_number': phoneNumber,
        if (otpCode != null) 'otp_code': otpCode,
        if (password != null) 'password': password,
      });

      final access = response.data['access'] as String;
      final refresh = response.data['refresh'] as String;
      await TokenStorage.instance.saveTokens(access: access, refresh: refresh);

      return AppUser.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(_extractError(e));
    }
  }

  Future<AppUser> fetchMe() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(_extractError(e));
    }
  }

  Future<void> logout() async {
    await TokenStorage.instance.clear();
  }

  /// Premium a'zolikni faollashtirish/uzaytirish (TEST/DEMO — haqiqiy to'lov
  /// hali ulanmagan). Backend: POST /membership/activate/ → yangilangan user.
  Future<AppUser> activateMembership({int months = 1}) async {
    try {
      final response = await _dio.post(ApiConstants.membershipActivate, data: {
        'plan_months': months,
      });
      final data = response.data as Map<String, dynamic>;
      return AppUser.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(_extractError(e));
    }
  }

  /// Profilni tahrirlash (ism, familiya, email). Backend: PATCH /me/
  Future<AppUser> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      final response = await _dio.patch(ApiConstants.me, data: {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (email != null) 'email': email,
      });
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(_extractError(e));
    }
  }

  /// Profil rasmini yuklash/almashtirish. Backend: PATCH /me/ (multipart).
  /// DIQQAT: Render kabi bepul hostinglarda fayl tizimi vaqtinchalik
  /// bo'lishi mumkin — server qayta ishga tushganda (redeploy) yuklangan
  /// rasm o'chib ketishi mumkin. Doimiy saqlash uchun kelajakda S3/Cloudinary
  /// kabi tashqi saqlash ulash tavsiya etiladi.
  Future<AppUser> updateAvatar(File file) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });
      final response = await _dio.patch(
        ApiConstants.me,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(_extractError(e));
    }
  }

  /// Akkountni o'chirish. Backend: DELETE /me/ (xavfsizlik uchun
  /// jismonan o'chirish o'rniga deaktivatsiya qiladi). Natijada
  /// mahalliy seans (tokenlar) ham tozalanadi.
  Future<void> deleteAccount() async {
    try {
      await _dio.delete(ApiConstants.me);
    } on DioException catch (e) {
      throw AuthException(_extractError(e));
    } finally {
      await TokenStorage.instance.clear();
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    if (data is Map && data.isNotEmpty) {
      // DRF validation errors: {"phone_number": ["..."]}
      final firstKey = data.keys.first;
      final firstVal = data[firstKey];
      if (firstVal is List && firstVal.isNotEmpty) return firstVal.first.toString();
    }
    return 'Xatolik yuz berdi. Internet aloqasini tekshirib, qayta urinib ko\'ring.';
  }
}
