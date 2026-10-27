import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/notifications/data/device_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient;

class FakeRpcBuilder extends Fake implements PostgrestFilterBuilder<dynamic> {
  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic value) onValue, {
    Function? onError,
  }) => Future.value(null).then(onValue, onError: onError);
}

void main() {
  test('registers a device with the authenticated Supabase function', () async {
    final supabase = MockSupabaseClient();
    when(
      () => supabase.rpc<dynamic>(
        'register_device',
        params: any(named: 'params'),
      ),
    ).thenAnswer((_) => FakeRpcBuilder());

    final repository = DeviceRepository(supabaseClient: supabase);
    await repository.registerDevice(
      fcmToken: 'device-token-0123456789012345',
      platform: 'android',
      appVersion: '1.0.0',
    );

    verify(
      () => supabase.rpc<dynamic>(
        'register_device',
        params: {
          'p_fcm_token': 'device-token-0123456789012345',
          'p_platform': 'android',
          'p_app_version': '1.0.0',
        },
      ),
    ).called(1);
  });
}
