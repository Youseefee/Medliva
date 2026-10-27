import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceRepository {
  DeviceRepository({SupabaseClient? supabaseClient})
    : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabaseClient;

  Future<void> registerDevice({
    required String fcmToken,
    required String platform,
    String? appVersion,
  }) async {
    await _supabaseClient.rpc<dynamic>(
      'register_device',
      params: {
        'p_fcm_token': fcmToken,
        'p_platform': platform,
        'p_app_version': appVersion,
      },
    );
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(supabaseClient: ref.watch(supabaseClientProvider));
});
