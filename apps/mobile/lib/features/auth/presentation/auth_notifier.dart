import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/core/storage/token_storage.dart';
import 'package:medliva/features/auth/data/auth_repository.dart';
import 'package:medliva/features/auth/domain/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(supabaseClient: ref.watch(supabaseClientProvider)),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    onUnauthorized: () async {
      ref.invalidate(authNotifierProvider);
    },
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final accessToken = await ref.watch(tokenStorageProvider).getAccessToken();
    if (accessToken == null || accessToken.isEmpty) return null;
    try {
      return await ref.watch(authRepositoryProvider).getMe();
    } catch (_) {
      try {
        final currentUser = ref.read(supabaseClientProvider).auth.currentUser;
        if (currentUser != null) {
          return ref.read(authRepositoryProvider).getUserFromAuth(currentUser);
        }
      } catch (_) {}
      await ref.read(tokenStorageProvider).clearTokens();
      return null;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String role = 'patient',
  }) async {
    state = const AsyncValue.loading();
    try {
      final hasSession = await ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: password, name: name, role: role);
      if (!hasSession) {
        state = const AsyncValue.data(null);
        return false;
      }
      final user = await ref.read(authRepositoryProvider).getMe();
      state = AsyncValue.data(user);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.read(selectedPatientIdProvider.notifier).clear();
    state = const AsyncValue.data(null);
  }

  Future<UserModel> updateProfile({
    String? name,
    String? language,
    String? role,
  }) async {
    final updated = await ref
        .read(authRepositoryProvider)
        .updateMe(name: name, language: language, role: role);
    state = AsyncValue.data(updated);
    return updated;
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);

class SelectedPatientIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  String? selectPatient(String patientId) => state = patientId;

  void clear() {
    state = null;
  }
}

final selectedPatientIdProvider =
    NotifierProvider<SelectedPatientIdNotifier, String?>(
      SelectedPatientIdNotifier.new,
    );

final currentPatientIdProvider = Provider<String?>((ref) {
  final user = ref.watch(authNotifierProvider).value;
  if (user == null) return null;
  if (user.isPatient) return user.id;
  return ref.watch(selectedPatientIdProvider);
});
