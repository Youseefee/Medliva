import 'package:careelder/core/config/app_config.dart';
import 'package:careelder/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException({required this.message, this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required TokenStorage tokenStorage, Dio? dio})
      : _tokenStorage = tokenStorage,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Content-Type': 'application/json'},
              ),
            ) {
    _setupInterceptors();
  }

  final TokenStorage _tokenStorage;
  final Dio _dio;

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Attempt refresh on 401
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/')) {
            final refreshToken = await _tokenStorage.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                // Call refresh with a plain Dio instance to prevent infinite loop
                final refreshDio = Dio(
                  BaseOptions(baseUrl: AppConfig.apiBaseUrl),
                );
                final res = await refreshDio.post<Map<String, dynamic>>(
                  '/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );

                if (res.statusCode == 200 && res.data != null) {
                  final newAccess = res.data!['access_token'] as String;
                  final newRefresh = res.data!['refresh_token'] as String;

                  await _tokenStorage.saveTokens(
                    accessToken: newAccess,
                    refreshToken: newRefresh,
                  );

                  // Retry original request with new token
                  final retryOptions = error.requestOptions;
                  retryOptions.headers['Authorization'] = 'Bearer $newAccess';
                  final retryRes = await _dio.fetch<dynamic>(retryOptions);
                  return handler.resolve(retryRes);
                }
              } catch (_) {
                await _tokenStorage.clearTokens();
              }
            }
          }

          // Extract standard error envelope
          final data = error.response?.data;
          String message = 'تعذر الاتصال بالسيرفر';
          String? code;

          if (data is Map<String, dynamic> && data.containsKey('error')) {
            final errObj = data['error'];
            if (errObj is Map<String, dynamic>) {
              message = errObj['message'] as String? ?? message;
              code = errObj['code'] as String?;
            }
          }

          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              error: ApiException(
                message: message,
                code: code,
                statusCode: error.response?.statusCode,
              ),
            ),
          );
        },
      ),
    );
  }
}
