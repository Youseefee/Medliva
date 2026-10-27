import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/caregiver/data/caregiver_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient;

class MockGoTrueClient extends Mock implements GoTrueClient;

class FakeRpcBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  FakeRpcBuilder(this._value);

  final T _value;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return Future<T>.value(_value).then(onValue, onError: onError);
  }
}

void main() {
  late MockSupabaseClient supabase;
  late MockGoTrueClient auth;
  late CaregiverRepository repository;

  setUp(() {
    supabase = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => supabase.auth).thenReturn(auth);

    const user = User(
      id: 'current-user-id',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-10-27T12:00:00Z',
    );
    when(() => auth.currentUser).thenReturn(user);
    repository = CaregiverRepository(supabaseClient: supabase);
  });

  test(
    'generates a pairing code with the authenticated Supabase RPC',
    () async {
      when(
        () => supabase.rpc<Map<String, dynamic>>(
          'generate_caregiver_pairing_code',
          params: any(named: 'params'),
        ),
      ).thenAnswer(
        (_) => FakeRpcBuilder<Map<String, dynamic>>({
          'code': '123456',
          'expires_at': '2026-10-27T12:10:00Z',
        }),
      );

      final result = await repository.generatePairingCode();

      expect(result.code, '123456');
      expect(result.expiresAt, DateTime.utc(2026, 10, 27, 12, 10));
      verify(
        () => supabase.rpc<Map<String, dynamic>>(
          'generate_caregiver_pairing_code',
          params: any(named: 'params'),
        ),
      ).called(1);
    },
  );

  test('consumes a trimmed code atomically through Supabase', () async {
    when(
      () => supabase.rpc<Map<String, dynamic>>(
        'consume_caregiver_pairing_code',
        params: any(named: 'params'),
      ),
    ).thenAnswer(
      (_) => FakeRpcBuilder<Map<String, dynamic>>({
        'patient_id': 'patient-1',
        'name': 'الوالد',
        'phone': '01012345678',
        'status': 'active',
        'linked_at': '2026-10-27T12:00:00Z',
      }),
    );

    final patient = await repository.pairWithPatient(' 654321 ');

    expect(patient.patientId, 'patient-1');
    expect(patient.name, 'الوالد');
    expect(patient.status, 'active');
    final params =
        verify(
              () => supabase.rpc<Map<String, dynamic>>(
                'consume_caregiver_pairing_code',
                params: captureAny(named: 'params'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(params, {'p_code': '654321'});
  });

  test(
    'loads linked patient summaries and missed doses from dashboard RPC',
    () async {
      when(
        () => supabase.rpc<List<dynamic>>(
          'get_caregiver_dashboard',
          params: any(named: 'params'),
        ),
      ).thenAnswer(
        (_) => FakeRpcBuilder<List<dynamic>>([
          {
            'patient_id': 'patient-1',
            'name': 'فاطمة',
            'phone': '01222222222',
            'status': 'active',
            'linked_at': '2026-10-25T10:00:00Z',
            'today_taken_count': 2,
            'today_missed_count': 1,
            'active_alerts_count': 1,
            'missed_doses': [
              {
                'schedule_id': 'schedule-1',
                'medication_id': 'medication-1',
                'medication_name': 'دواء القلب',
                'time_of_day': '08:00',
                'scheduled_time': '2026-10-27T08:00:00Z',
              },
            ],
          },
        ]),
      );

      final patients = await repository.listLinkedPatients(
        now: DateTime.utc(2026, 10, 27, 8, 16),
      );

      expect(patients, hasLength(1));
      expect(patients.single.patientId, 'patient-1');
      expect(patients.single.todayTakenCount, 2);
      expect(patients.single.todayMissedCount, 1);
      expect(patients.single.missedDoses.single.medicationName, 'دواء القلب');
      final params =
          verify(
                () => supabase.rpc<List<dynamic>>(
                  'get_caregiver_dashboard',
                  params: captureAny(named: 'params'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(params['p_now'], '2026-10-27T08:16:00.000Z');
    },
  );

  test('lists all missed dose alerts from linked patient summaries', () async {
    when(
      () => supabase.rpc<List<dynamic>>(
        'get_caregiver_dashboard',
        params: any(named: 'params'),
      ),
    ).thenAnswer(
      (_) => FakeRpcBuilder<List<dynamic>>([
        {
          'patient_id': 'patient-1',
          'missed_doses': [
            {
              'schedule_id': 'schedule-1',
              'medication_id': 'medication-1',
              'medication_name': 'دواء القلب',
              'time_of_day': '08:00',
              'scheduled_time': '2026-10-27T08:00:00Z',
            },
          ],
        },
        {'patient_id': 'patient-2', 'missed_doses': <dynamic>[]},
      ]),
    );

    final alerts = await repository.listCaregiverAlerts();

    expect(alerts, hasLength(1));
    expect(alerts.single.scheduleId, 'schedule-1');
    expect(alerts.single.timeOfDay, '08:00');
  });

  test('lists patient caregivers through a scoped Supabase RPC', () async {
    when(
      () => supabase.rpc<List<dynamic>>(
        'list_patient_caregivers',
        params: any(named: 'params'),
      ),
    ).thenAnswer(
      (_) => FakeRpcBuilder<List<dynamic>>([
        {
          'caregiver_id': 'caregiver-1',
          'name': 'أحمد',
          'phone': '01098765432',
          'status': 'active',
          'linked_at': '2026-10-25T10:00:00Z',
        },
      ]),
    );

    final caregivers = await repository.listPatientCaregivers('patient-1');

    expect(caregivers, hasLength(1));
    expect(caregivers.single.caregiverId, 'caregiver-1');
    expect(caregivers.single.displayName, 'أحمد');
    verify(
      () => supabase.rpc<List<dynamic>>(
        'list_patient_caregivers',
        params: {'p_patient_id': 'patient-1'},
      ),
    ).called(1);
  });

  test('maps an invalid pairing code error to an Arabic message', () async {
    when(
      () => supabase.rpc<Map<String, dynamic>>(
        'consume_caregiver_pairing_code',
        params: any(named: 'params'),
      ),
    ).thenThrow(
      const PostgrestException(message: 'INVALID_CODE', code: 'P0001'),
    );

    await expectLater(
      repository.pairWithPatient('111111'),
      throwsA(
        isA<CaregiverRepositoryException>()
            .having((error) => error.code, 'code', 'INVALID_CODE')
            .having(
              (error) => error.message,
              'message',
              'رمز الاقتران غير صحيح أو منتهي الصلاحية',
            ),
      ),
    );
  });
}
