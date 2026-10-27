import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/notifications/data/alerts_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient;

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
  late MockSupabaseClient supabase;
  late AlertsRepository repository;

  setUp(() {
    supabase = MockSupabaseClient();
    repository = AlertsRepository(supabaseClient: supabase);
  });

  test('loads stored and derived missed-dose alerts through the RPC', () async {
    when(
      () => supabase.rpc<dynamic>(
        'list_patient_alerts',
        params: any(named: 'params'),
      ),
    ).thenAnswer(
      (_) => FakeRpcBuilder([
        {
          'id': 'sos-1',
          'patient_id': 'patient-1',
          'type': 'sos',
          'tier': 3,
          'sent_at': '2026-10-25T12:00:00Z',
          'created_at': '2026-10-25T12:00:00Z',
          'payload': {'note': 'حالة طارئة'},
        },
        {
          'id': 'missed-dose:sched-1:2026-10-25',
          'patient_id': 'patient-1',
          'type': 'missed_dose',
          'tier': 1,
          'sent_at': '2026-10-25T08:15:00Z',
          'created_at': '2026-10-25T08:15:00Z',
          'payload': {'medication_name': 'Concor', 'time_of_day': '08:00'},
        },
      ]),
    );

    final alerts = await repository.listAlerts(
      'patient-1',
      limit: 20,
      now: DateTime.utc(2026, 10, 25, 10),
    );
    expect(alerts, hasLength(2));
    expect(alerts.first.type, 'sos');
    expect(alerts.last.type, 'missed_dose');
    expect(alerts.last.medicationName, 'Concor');
    verify(
      () => supabase.rpc<dynamic>(
        'list_patient_alerts',
        params: {
          'p_patient_id': 'patient-1',
          'p_limit': 20,
          'p_now': '2026-10-25T10:00:00.000Z',
        },
      ),
    ).called(1);
  });

  test('rejects out-of-range limits before calling Supabase', () async {
    await expectLater(
      () => repository.listAlerts('patient-1', limit: 201),
      throwsArgumentError,
    );
    verifyNever(
      () => supabase.rpc<dynamic>(any(), params: any(named: 'params')),
    );
  });
}
