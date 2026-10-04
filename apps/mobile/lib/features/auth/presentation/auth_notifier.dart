import 'package:careelder/core/network/api_client.dart';
import 'package:careelder/core/storage/token_storage.dart';
import 'package:careelder/features/auth/data/auth_repository.dart';
import 'package:careelder/features/auth/domain/models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final tokenStorage = ref.watch(tokenStorageProvider);
    final token = await tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final repo = ref.watch(authRepositoryProvider);
      return await repo.getMe();
    } catch (_) {
      await tokenStorage.clearTokens();
      return null;
    }
  }

  Future<OtpRequestResult> requestOtp(String phone) async {
    final repo = ref.read(authRepositoryProvider);
    return await repo.requestOtp(phone);
  }

  Future<void> verifyOtp({
    required String phone,
    required String code,
    String? role,
    String? name,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.verifyOtp(
        phone: phone,
        code: code,
        role: role,
        name: name,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);
