import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient;

class FakeTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  FakeTransformBuilder(this._data);

  final dynamic _data;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() =>
      FakeTransformBuilder<Map<String, dynamic>>(_oneRow(_data));

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() =>
      FakeTransformBuilder<Map<String, dynamic>?>(_optionalOneRow(_data));

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return Future.value(_data as T).then(onValue, onError: onError);
  }
}

class FakeFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  FakeFilterBuilder(this._data);

  final dynamic _data;

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<T> gte(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<T> lt(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<T> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) => this;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) => FakeTransformBuilder<List<Map<String, dynamic>>>(_rows(_data));

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() =>
      FakeTransformBuilder<Map<String, dynamic>>(_oneRow(_data));

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() =>
      FakeTransformBuilder<Map<String, dynamic>?>(_optionalOneRow(_data));

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return Future.value(_data as T).then(onValue, onError: onError);
  }
}

class FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  FakeQueryBuilder(this._data);

  final dynamic _data;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) => FakeFilterBuilder<List<Map<String, dynamic>>>(_rows(_data));

  @override
  PostgrestFilterBuilder<dynamic> insert(
    Object values, {
    bool defaultToNull = true,
  }) => FakeFilterBuilder<dynamic>(_data);

  @override
  PostgrestFilterBuilder<dynamic> update(
    Map<dynamic, dynamic> values, {
    bool defaultToNull = true,
  }) => FakeFilterBuilder<dynamic>(_data);
}

class FakeRpcBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  FakeRpcBuilder(this._data);

  final dynamic _data;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return Future.value(_data as T).then(onValue, onError: onError);
  }
}

List<Map<String, dynamic>> _rows(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }
  return [Map<String, dynamic>.from(value as Map)];
}

Map<String, dynamic> _oneRow(dynamic value) {
  if (value is List) return Map<String, dynamic>.from(value.first as Map);
  return Map<String, dynamic>.from(value as Map);
}

Map<String, dynamic>? _optionalOneRow(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value.isEmpty ? null : Map<String, dynamic>.from(value.first as Map);
  }
  return Map<String, dynamic>.from(value as Map);
}

void main() {
  late MockSupabaseClient supabase;
  late MedicationRepository repository;

  final medicationRow = <String, dynamic>{
    'id': 'med-1',
    'patient_id': 'patient-1',
    'name': 'Concor',
    'trade_name': 'Concor 5mg',
    'active_ingredient': 'Bisoprolol',
    'form': 'قرص',
    'strength': '5mg',
    'stock_count': 30,
    'alert_threshold_days': 5,
    'expiry_date': '2027-01-01',
    'is_active': true,
    'schedules': [
      {
        'id': 'sched-1',
        'medication_id': 'med-1',
        'time_of_day': '08:00:00',
        'dose_amount': 1.0,
        'meal_relation': 'after_meal',
        'days_mask': 127,
        'instructions_ar': 'بعد الفطار',
        'is_active': true,
      },
      {
        'id': 'sched-inactive',
        'medication_id': 'med-1',
        'time_of_day': '20:00:00',
        'dose_amount': 1.0,
        'meal_relation': 'before_meal',
        'days_mask': 127,
        'is_active': false,
      },
    ],
  };

  setUp(() {
    supabase = MockSupabaseClient();
    repository = MedicationRepository(supabaseClient: supabase);
  });

  group('MedicationRepository Supabase operations', () {
    test('listMedications reads active medications and schedules', () async {
      when(() => supabase.from('medications'))
          .thenAnswer((_) => FakeQueryBuilder([medicationRow]));

      final medications = await repository.listMedications('patient-1');

      expect(medications, hasLength(1));
      expect(medications.first.id, 'med-1');
      expect(medications.first.schedules, hasLength(1));
      expect(medications.first.schedules.first.timeOfDay, '08:00');
      verify(() => supabase.from('medications')).called(1);
    });

    test('createMedication uses one transaction-safe database RPC', () async {
      Map<String, dynamic>? rpcParams;
      when(
        () => supabase.rpc<Map<String, dynamic>>(
          'create_medication_with_schedules',
          params: any(named: 'params'),
        ),
      ).thenAnswer((invocation) {
        rpcParams = Map<String, dynamic>.from(
          invocation.namedArguments[#params] as Map,
        );
        return FakeRpcBuilder<Map<String, dynamic>>(medicationRow);
      });

      final medication = await repository.createMedication(
        'patient-1',
        const MedicationCreateInput(
          name: 'Concor',
          tradeName: 'Concor 5mg',
          stockCount: 30,
          schedules: [ScheduleCreateInput(timeOfDay: '08:00')],
        ),
      );

      expect(medication.id, 'med-1');
      expect(rpcParams?['p_patient_id'], 'patient-1');
      expect((rpcParams?['p_medication'] as Map)['name'], 'Concor');
      expect(rpcParams?['p_schedules'], [
        {
          'time_of_day': '08:00',
          'dose_amount': 1.0,
          'meal_relation': 'after_meal',
          'days_mask': 127,
        },
      ]);
    });

    test('updateMedication changes only supplied fields in Supabase', () async {
      when(() => supabase.from('medications')).thenAnswer(
        (_) => FakeQueryBuilder({
          ...medicationRow,
          'name': 'Concor Updated',
          'stock_count': 20,
        }),
      );

      final medication = await repository.updateMedication(
        'med-1',
        const MedicationUpdateInput(name: 'Concor Updated', stockCount: 20),
      );

      expect(medication.name, 'Concor Updated');
      expect(medication.stockCount, 20);
    });

    test('deleteMedication deactivates the row in Supabase', () async {
      when(() => supabase.from('medications'))
          .thenAnswer((_) => FakeQueryBuilder({'id': 'med-1'}));

      await repository.deleteMedication('med-1');

      verify(() => supabase.from('medications')).called(1);
    });

    test(
      'listSchedules includes the medication schedules from Supabase',
      () async {
        when(() => supabase.from('schedules')).thenAnswer(
          (_) => FakeQueryBuilder([
            {
              'id': 'sched-1',
              'medication_id': 'med-1',
              'time_of_day': '08:00:00',
              'dose_amount': 1.0,
              'meal_relation': 'after_meal',
              'days_mask': 127,
              'is_active': true,
            },
          ]),
        );

        final schedules = await repository.listSchedules('med-1');

        expect(schedules, hasLength(1));
        expect(schedules.first.id, 'sched-1');
        expect(schedules.first.timeOfDay, '08:00');
      },
    );

    test('createSchedule inserts a schedule through PostgREST', () async {
      when(() => supabase.from('schedules')).thenAnswer(
        (_) => FakeQueryBuilder({
          'id': 'sched-2',
          'medication_id': 'med-1',
          'time_of_day': '20:00:00',
          'dose_amount': 1.0,
          'meal_relation': 'before_meal',
          'days_mask': 127,
          'is_active': true,
        }),
      );

      final schedule = await repository.createSchedule(
        'med-1',
        const ScheduleCreateInput(
          timeOfDay: '20:00',
          mealRelation: 'before_meal',
        ),
      );

      expect(schedule.id, 'sched-2');
      expect(schedule.timeOfDay, '20:00');
      expect(schedule.mealRelation, 'before_meal');
    });

    test(
      'getTodayDoses joins active schedules with their intake logs',
      () async {
        when(() => supabase.from('medications')).thenAnswer(
          (_) => FakeQueryBuilder([
            {
              'id': 'med-1',
              'name': 'Concor',
              'schedules': [
                (medicationRow['schedules'] as List<dynamic>).first,
              ],
            },
          ]),
        );
        when(() => supabase.from('intake_logs')).thenAnswer(
          (_) => FakeQueryBuilder([
            {
              'id': 'log-1',
              'schedule_id': 'sched-1',
              'status': 'taken',
              'actual_time': '2026-10-27T08:05:00Z',
            },
          ]),
        );

        final doses = await repository.getTodayDoses('patient-1');

        expect(doses, hasLength(1));
        expect(doses.first.scheduleId, 'sched-1');
        expect(doses.first.medicationName, 'Concor');
        expect(doses.first.status, 'taken');
        expect(doses.first.intakeLogId, 'log-1');
      },
    );

    test('logAdherence uses an atomic idempotent database function', () async {
      Map<String, dynamic>? rpcParams;
      when(
        () => supabase.rpc<Map<String, dynamic>>(
          'record_intake_log',
          params: any(named: 'params'),
        ),
      ).thenAnswer((invocation) {
        rpcParams = Map<String, dynamic>.from(
          invocation.namedArguments[#params] as Map,
        );
        return FakeRpcBuilder<Map<String, dynamic>>({
          'id': 'log-1',
          'client_uuid': 'uuid-1',
          'schedule_id': 'sched-1',
          'patient_id': 'patient-1',
          'scheduled_time': '2026-10-27T08:00:00Z',
          'actual_time': '2026-10-27T08:00:00Z',
          'status': 'taken',
          'logged_offline': false,
        });
      });

      final log = await repository.logAdherence(
        IntakeLogCreateInput(
          clientUuid: 'uuid-1',
          scheduleId: 'sched-1',
          scheduledTime: DateTime.utc(2026, 10, 27, 8),
          status: 'taken',
        ),
      );

      expect(log.id, 'log-1');
      expect(rpcParams?['p_client_uuid'], 'uuid-1');
      expect(rpcParams?['p_status'], 'taken');
      expect(rpcParams?['p_logged_offline'], false);
    });

    test(
      'syncBatch retries each offline intake through the same RPC',
      () async {
        final received = <Map<String, dynamic>>[];
        when(
          () => supabase.rpc<Map<String, dynamic>>(
            'record_intake_log',
            params: any(named: 'params'),
          ),
        ).thenAnswer((invocation) {
          final params = Map<String, dynamic>.from(
            invocation.namedArguments[#params] as Map,
          );
          received.add(params);
          return FakeRpcBuilder<Map<String, dynamic>>({
            'id': 'log-${params['p_client_uuid']}',
            'client_uuid': params['p_client_uuid'],
            'schedule_id': params['p_schedule_id'],
            'patient_id': 'patient-1',
            'scheduled_time': params['p_scheduled_time'],
            'actual_time': params['p_actual_time'],
            'status': params['p_status'],
            'logged_offline': true,
          });
        });

        final synced = await repository.syncBatch([
          {
            'client_uuid': 'offline-uuid',
            'entity': 'intake_log',
            'op': 'create',
            'payload': {
              'schedule_id': 'sched-1',
              'scheduled_time': '2026-10-27T08:00:00Z',
              'status': 'taken',
            },
          },
          {
            'client_uuid': 'vital-uuid',
            'entity': 'vitals_log',
            'op': 'create',
            'payload': const <String, dynamic>{},
          },
        ]);

        expect(synced, ['offline-uuid']);
        expect(received, hasLength(1));
        expect(received.single['p_logged_offline'], true);
      },
    );
  });
}
