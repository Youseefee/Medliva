import 'package:dio/dio.dart';
import 'package:medliva/core/config/app_config.dart';
import 'package:medliva/core/storage/token_storage.dart';

class ApiException implements Exception {
  ApiException({required this.message, this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    Dio? dio,
    Future<void> Function()? onUnauthorized,
  }) : _tokenStorage = tokenStorage,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: AppConfig.apiBaseUrl,
               connectTimeout: const Duration(seconds: 5),
               receiveTimeout: const Duration(seconds: 8),
               headers: {'Content-Type': 'application/json'},
             ),
           ),
       _onUnauthorized = onUnauthorized {
    _setupInterceptors();
  }

  final TokenStorage _tokenStorage;
  final Dio _dio;
  final Future<void> Function()? _onUnauthorized;

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final alreadyRetried = error.requestOptions.extra['_retried'] == true;
          if (error.response?.statusCode == 401 && !alreadyRetried) {
            try {
              final newAccess = await _tokenStorage.refreshAccessToken();
              if (newAccess != null && newAccess.isNotEmpty) {
                final retryOptions = error.requestOptions
                  ..extra['_retried'] = true
                  ..headers['Authorization'] = 'Bearer $newAccess';
                final retryResponse = await _dio.fetch<dynamic>(retryOptions);
                return handler.resolve(retryResponse);
              }
            } catch (_) {
              // A failed refresh ends the local Supabase session below.
            }
            await _tokenStorage.clearTokens();
            await _onUnauthorized?.call();
          }

          final data = error.response?.data;
          String message = 'تعذر الاتصال بالسيرفر';
          String? code;
          if (data is Map<String, dynamic> &&
              data['error'] is Map<String, dynamic>) {
            final err = data['error'] as Map<String, dynamic>;
            message = err['message'] as String? ?? message;
            code = err['code'] as String?;
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
