import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/reports/data/reports_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient;

class MockPostgrestClient extends Mock implements PostgrestClient;

class FakeRpcBuilder extends Fake implements PostgrestFilterBuilder<dynamic> {
  FakeRpcBuilder(this.value);

  final dynamic value;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic value) onValue, {
    Function? onError,
  }) => Future.value(value).then(onValue, onError: onError);
}

void main() {
  test(
    'creates an expiring, opaque public-report link through Supabase',
    () async {
      final supabase = MockSupabaseClient();
      final rest = MockPostgrestClient();
      when(() => supabase.rest).thenReturn(rest);
      when(() => rest.url).thenReturn('https://example.supabase.co/rest/v1');
      when(
        () => supabase.rpc<dynamic>(
          'create_report_share',
          params: any(named: 'params'),
        ),
      ).thenAnswer(
        (_) => FakeRpcBuilder({
          'token': 'f'.padRight(42, 'a'),
          'expires_at': '2026-10-28T12:00:00Z',
        }),
      );

      final repository = ReportsRepository(supabaseClient: supabase);
      final share = await repository.createReportShare(
        patientId: 'patient-1',
        expiresInHours: 24,
      );

      expect(share.token, 'f'.padRight(42, 'a'));
      expect(
        share.url,
        'https://example.supabase.co/functions/v1/public-report?token='
        '${'f'.padRight(42, 'a')}',
      );
      expect(share.expiresAt, DateTime.utc(2026, 10, 28, 12));
      verify(
        () => supabase.rpc<dynamic>(
          'create_report_share',
          params: {
            'p_patient_id': 'patient-1',
            'p_expires_in_hours': 24,
            'p_scope': 'summary_30d',
          },
        ),
      ).called(1);
    },
  );
}
