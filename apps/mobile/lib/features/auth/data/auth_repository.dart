import 'package:careelder/core/network/api_client.dart';
import 'package:careelder/core/storage/token_storage.dart';
import 'package:careelder/features/auth/domain/models/user.dart';
import 'package:dio/dio.dart';

class OtpRequestResult {
  const OtpRequestResult({
    required this.phone,
    required this.expiresIn,
    this.devCode,
  });

  final String phone;
  final int expiresIn;
  final String? devCode;
}

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<OtpRequestResult> requestOtp(String phone) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/otp/request',
        data: {'phone': phone},
      );
      final data = res.data!;
      return OtpRequestResult(
        phone: data['phone'] as String,
        expiresIn: data['expires_in'] as int,
        devCode: data['dev_code'] as String?,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<UserModel> verifyOtp({
    required String phone,
    required String code,
    String? role,
    String? name,
  }) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/otp/verify',
        data: {
          'phone': phone,
          'code': code,
          if (role != null) 'role': role,
          if (name != null && name.isNotEmpty) 'name': name,
        },
      );
      final data = res.data!;
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      return user;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<UserModel> getMe() async {
    try {
      final res = await _apiClient.dio.get<Map<String, dynamic>>('/me');
      return UserModel.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }
}
