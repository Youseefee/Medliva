import 'package:medliva/core/storage/token_storage.dart';
import 'package:medliva/features/auth/domain/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({
    required TokenStorage tokenStorage,
    required SupabaseClient supabaseClient,
  }) : _tokenStorage = tokenStorage,
       _supabaseClient = supabaseClient;

  final TokenStorage _tokenStorage;
  final SupabaseClient _supabaseClient;

  UserModel getUserFromAuth(User user, [Map<String, dynamic>? dbRow]) =>
      _userFromAuth(user, dbRow);

  UserModel _userFromAuth(User user, [Map<String, dynamic>? dbRow]) {
    final meta = user.userMetadata ?? {};
    final phone = user.phone ?? (dbRow?['phone'] as String?);
    final name =
        (dbRow?['name'] as String?) ??
        (meta['full_name'] as String?) ??
        (meta['name'] as String?) ??
        user.email?.split('@').first ??
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
      id: user.id,
      email: user.email,
      phone: phone,
      name: name,
      role: role,
      language: language,
      timezone: timezone,
    );
  }

  Future<UserModel> _fetchFromSupabase(User user) async {
    final response = await _supabaseClient
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return _userFromAuth(user);
    return UserModel.fromJson(Map<String, dynamic>.from(response));
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
      data: {'full_name': name.trim(), 'role': role, 'language': 'ar'},
    );

    // The auth.users trigger creates the corresponding public.users row.
    return response.session != null;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabaseClient.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return await getMe(currentUser: response.user);
  }

  Future<UserModel> getMe({User? currentUser}) async {
    final authUser = currentUser ?? _supabaseClient.auth.currentUser;
    if (authUser == null) {
      throw StateError(
        'A signed-in Supabase user is required to load a profile.',
      );
    }
    return await _fetchFromSupabase(authUser);
  }

  Future<UserModel> updateMe({
    String? name,
    String? language,
    String? role,
  }) async {
    if (name != null && name.length > 100) {
      throw ArgumentError.value(
        name,
        'name',
        'Must be 100 characters or fewer.',
      );
    }
    if (language != null && language.length > 10) {
      throw ArgumentError.value(
        language,
        'language',
        'Must be 10 characters or fewer.',
      );
    }
    final normalizedRole = role?.trim().toLowerCase();
    if (normalizedRole != null &&
        normalizedRole != 'patient' &&
        normalizedRole != 'caregiver') {
      throw ArgumentError.value(
        role,
        'role',
        'Only patient and caregiver roles can be selected.',
      );
    }

    final authUser = _supabaseClient.auth.currentUser;
    if (authUser == null) {
      throw StateError(
        'A signed-in Supabase user is required to update a profile.',
      );
    }

    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (language != null) 'language': language,
      if (normalizedRole != null) 'role': normalizedRole,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await _supabaseClient
        .from('users')
        .update(updates)
        .eq('id', authUser.id)
        .select()
        .maybeSingle();

    if (response == null) {
      throw StateError(
        'The signed-in user profile does not exist in Supabase.',
      );
    }
    return UserModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> logout() => _tokenStorage.clearTokens();
}
