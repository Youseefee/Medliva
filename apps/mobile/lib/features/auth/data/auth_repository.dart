import 'package:dio/dio.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/core/storage/token_storage.dart';
import 'package:medliva/features/auth/domain/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    required SupabaseClient supabaseClient,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage,
       _supabaseClient = supabaseClient;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final SupabaseClient _supabaseClient;

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String role = 'patient',
  }) async {
    final response = await _supabaseClient.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': name.trim(),
        'role': role,
      },
    );
    return response.session != null;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await _supabaseClient.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return await getMe();
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

  Future<UserModel> updateMe({
    String? name,
    String? language,
    String? role,
  }) async {
    try {
      final res = await _apiClient.dio.patch<Map<String, dynamic>>(
        '/me',
        data: {
          if (name != null) 'name': name,
          if (language != null) 'language': language,
          if (role != null) 'role': role,
        },
      );
      return UserModel.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<void> logout() => _tokenStorage.clearTokens();
}
