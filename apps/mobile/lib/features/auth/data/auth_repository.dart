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

  UserModel getUserFromAuth(User user, [Map<String, dynamic>? dbRow]) =>
      _userFromAuth(user, dbRow);

  UserModel _userFromAuth(User user, [Map<String, dynamic>? dbRow]) {
    final meta = user.userMetadata ?? {};
    final id = user.id;
    final email = user.email;
    final phone = user.phone ?? (dbRow?['phone'] as String?);
    final name = (dbRow?['name'] as String?) ??
        (meta['full_name'] as String?) ??
        (meta['name'] as String?) ??
        email?.split('@').first ??
        '';
    final rawRole =
        (dbRow?['role'] as String?) ?? (meta['role'] as String?) ?? 'patient';
    final role = rawRole.toLowerCase() == 'caregiver' ? 'caregiver' : 'patient';
    final language =
        (dbRow?['language'] as String?) ??
        (meta['language'] as String?) ??
        'ar';
    final timezone =
        (dbRow?['timezone'] as String?) ??
        (meta['timezone'] as String?) ??
        'Africa/Cairo';

    return UserModel(
      id: id,
      email: email,
      phone: phone,
      name: name,
      role: role,
      language: language,
      timezone: timezone,
    );
  }

  Future<UserModel> _fetchFromSupabaseDirect(User user) async {
    Map<String, dynamic>? row;
    try {
      final res = await _supabaseClient
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (res != null) {
        row = Map<String, dynamic>.from(res);
      }
    } catch (_) {
      // Ignored if PostgREST request fails
    }

    if (row != null) {
      return UserModel.fromJson(row);
    }

    final userModel = _userFromAuth(user);
    try {
      await _supabaseClient.from('users').upsert({
        'id': userModel.id,
        'email': userModel.email,
        'phone': userModel.phone,
        'name': userModel.name,
        'role': userModel.role,
        'language': userModel.language,
        'timezone': userModel.timezone,
      });
    } catch (_) {
      // Ignored
    }

    return userModel;
  }

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
        'language': 'ar',
      },
    );

    final user = response.user;
    if (user != null && response.session != null) {
      try {
        await _supabaseClient.from('users').upsert({
          'id': user.id,
          'email': user.email,
          'phone': user.phone,
          'name': name.trim(),
          'role': role,
          'language': 'ar',
          'timezone': 'Africa/Cairo',
        });
      } catch (_) {
        // Trigger on auth.users also takes care of this
      }
    }

    return response.session != null;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _supabaseClient.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return await getMe(currentUser: res.user);
  }

  Future<UserModel> getMe({User? currentUser}) async {
    try {
      final res = await _apiClient.dio.get<Map<String, dynamic>>('/me');
      return UserModel.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }

      final authUser = currentUser ?? _supabaseClient.auth.currentUser;
      if (authUser != null) {
        return await _fetchFromSupabaseDirect(authUser);
      }

      if (e.error is ApiException) throw e.error!;
      rethrow;
    } catch (_) {
      final authUser = currentUser ?? _supabaseClient.auth.currentUser;
      if (authUser != null) {
        return await _fetchFromSupabaseDirect(authUser);
      }
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
    } catch (e) {
      final authUser = _supabaseClient.auth.currentUser;
      if (authUser == null) {
        if (e is DioException && e.error is ApiException) throw e.error!;
        rethrow;
      }

      final metaUpdates = <String, dynamic>{
        if (name != null) 'full_name': name,
        if (language != null) 'language': language,
        if (role != null) 'role': role,
      };
      if (metaUpdates.isNotEmpty) {
        try {
          await _supabaseClient.auth.updateUser(
            UserAttributes(data: metaUpdates),
          );
        } catch (_) {}
      }

      final dbUpdates = <String, dynamic>{
        if (name != null) 'name': name,
        if (language != null) 'language': language,
        if (role != null) 'role': role,
        'updated_at': DateTime.now().toIso8601String(),
      };
      try {
        await _supabaseClient
            .from('users')
            .update(dbUpdates)
            .eq('id', authUser.id);
      } catch (_) {}

      return await _fetchFromSupabaseDirect(
        _supabaseClient.auth.currentUser ?? authUser,
      );
    }
  }

  Future<void> logout() => _tokenStorage.clearTokens();
}
