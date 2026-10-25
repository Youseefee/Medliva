import 'package:supabase_flutter/supabase_flutter.dart';

class TokenStorage {
  TokenStorage({required SupabaseClient supabaseClient})
    : _supabaseClient = supabaseClient;

  final SupabaseClient _supabaseClient;

  Future<String?> getAccessToken() async =>
      _supabaseClient.auth.currentSession?.accessToken;

  Future<String?> refreshAccessToken() async {
    final response = await _supabaseClient.auth.refreshSession();
    return response.session?.accessToken;
  }

  Future<void> clearTokens() =>
      _supabaseClient.auth.signOut(scope: SignOutScope.local);
}
