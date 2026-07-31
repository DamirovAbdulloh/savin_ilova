import 'package:dio/dio.dart';
import 'constants.dart';
import 'storage/token_storage.dart';

/// Butun ilova bo'ylab ishlatiladigan yagona Dio instansi.
/// - Har bir so'rovga avtomatik `Authorization: Bearer <token>` qo'shadi
/// - 401 kelsa, refresh token bilan yangi access token oladi va so'rovni qayta yuboradi
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.instance.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isRetry = error.requestOptions.extra['retried'] == true;

          if (isUnauthorized && !isRetry) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              final opts = error.requestOptions;
              opts.extra['retried'] = true;
              final newToken = await TokenStorage.instance.getAccessToken();
              opts.headers['Authorization'] = 'Bearer $newToken';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Dio get dio => _dio;

  Future<bool> _tryRefreshToken() async {
    final refresh = await TokenStorage.instance.getRefreshToken();
    if (refresh == null) return false;
    try {
      final response = await _dio.post(
        ApiConstants.tokenRefresh,
        data: {'refresh': refresh},
      );
      final newAccess = response.data['access'] as String?;
      if (newAccess == null) return false;
      // Backendda ROTATE_REFRESH_TOKENS yoqilgan — server javobda YANGI refresh
      // token ham qaytaradi. Uni saqlamasak, eski token 14 kundan keyin
      // muddati tugab, faol foydalanuvchi ham tizimdan chiqib ketardi.
      final newRefresh = response.data['refresh'] as String? ?? refresh;
      await TokenStorage.instance.saveTokens(access: newAccess, refresh: newRefresh);
      return true;
    } catch (_) {
      await TokenStorage.instance.clear();
      return false;
    }
  }
}
