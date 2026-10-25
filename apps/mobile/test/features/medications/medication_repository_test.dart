import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockApiClient extends Mock implements ApiClient;

class MockDio extends Mock implements Dio;

class MockSupabaseClient extends Mock implements SupabaseClient;

class FakeTransformBuilder<T> extends Fake implements PostgrestTransformBuilder<T> {
  FakeTransformBuilder(this._data);
  final dynamic _data;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() =>
      FakeTransformBuilder<Map<String, dynamic>>(
        _data is List
            ? _data.first as Map<String, dynamic>
            : _data as Map<String, dynamic>,
      );

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() =>
      FakeTransformBuilder<Map<String, dynamic>?>(
        _data is List
            ? (_data.isEmpty ? null : _data.first as Map<String, dynamic>)
            : _data as Map<String, dynamic>?,
      );

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) {
    return Future.value(_data as T).then(onValue, onError: onError);
  }
}

class FakeFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  FakeFilterBuilder(this._data);
  final dynamic _data;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> select([String columns = '*']) =>
      FakeTransformBuilder<List<Map<String, dynamic>>>(
        _data is List
            ? List<Map<String, dynamic>>.from(_data)
            : [_data as Map<String, dynamic>],
      );

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<T> order(String column,
          {bool ascending = false,
          bool nullsFirst = false,
          String? referencedTable}) =>
      this;

  @override
  PostgrestFilterBuilder<T> gte(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<T> lte(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() =>
      FakeTransformBuilder<Map<String, dynamic>>(
        _data is List
            ? _data.first as Map<String, dynamic>
            : _data as Map<String, dynamic>,
      );

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() =>
      FakeTransformBuilder<Map<String, dynamic>?>(
        _data is List
            ? (_data.isEmpty ? null : _data.first as Map<String, dynamic>)
            : _data as Map<String, dynamic>?,
      );

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) {
    return Future.value(_data as T).then(onValue, onError: onError);
  }
}

class FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  FakeQueryBuilder(this._data);
  final dynamic _data;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) =>
      FakeFilterBuilder<List<Map<String, dynamic>>>(_data);

  @override
  PostgrestFilterBuilder<dynamic> insert(Object values, {bool defaultToNull = true}) =>
      FakeFilterBuilder<dynamic>(_data);

  @override
  // Match PostgrestQueryBuilder.update signature which uses raw Map parameter.
  // ignore: strict_raw_type
  PostgrestFilterBuilder<dynamic> update(Map values, {bool defaultToNull = true}) =>
      FakeFilterBuilder<dynamic>(_data);
}

void main() {
  late MockApiClient apiClient;
  late MockDio dio;
  late MockSupabaseClient mockSupabase;
  late MedicationRepository repository;

  setUp(() {
    apiClient = MockApiClient();
    dio = MockDio();
    mockSupabase = MockSupabaseClient();
    when(() => apiClient.dio).thenReturn(dio);
    repository = MedicationRepository(
      apiClient: apiClient,
      supabaseClient: mockSupabase,
    );
  });

  final sampleMedicationJson = <String, dynamic>{
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
        'time_of_day': '08:00',
        'dose_amount': 1.0,
        'meal_relation': 'after_meal',
        'days_mask': 127,
        'instructions_ar': 'بعد الفطار',
        'is_active': true,
      },
    ],
  };

  group('MedicationRepository API Operations', () {
    test('listMedications calls GET /patients/{id}/medications', () async {
      when(
        () => dio.get<List<dynamic>>('/patients/patient-1/medications'),
      ).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions:
              RequestOptions(path: '/patients/patient-1/medications'),
          statusCode: 200,
          data: [sampleMedicationJson],
        ),
      );

      final result = await repository.listMedications('patient-1');
      expect(result, hasLength(1));
      expect(result.first.id, 'med-1');
      expect(result.first.name, 'Concor');
      expect(result.first.schedules, hasLength(1));
      expect(result.first.schedules.first.timeOfDay, '08:00');
    });

    test('createMedication calls POST /patients/{id}/medications', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/patients/patient-1/medications',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions:
              RequestOptions(path: '/patients/patient-1/medications'),
          statusCode: 201,
          data: sampleMedicationJson,
        ),
      );

      final created = await repository.createMedication(
        'patient-1',
        const MedicationCreateInput(
          name: 'Concor',
          strength: '5mg',
          stockCount: 30,
          schedules: [ScheduleCreateInput(timeOfDay: '08:00')],
        ),
      );

      expect(created.id, 'med-1');
      expect(created.stockCount, 30);
    });

    test('updateMedication calls PATCH /medications/{id}', () async {
      when(
        () => dio.patch<Map<String, dynamic>>(
          '/medications/med-1',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/medications/med-1'),
          statusCode: 200,
          data: {
            ...sampleMedicationJson,
            'name': 'Concor Updated',
            'stock_count': 20,
          },
        ),
      );

      final updated = await repository.updateMedication(
        'med-1',
        const MedicationUpdateInput(name: 'Concor Updated', stockCount: 20),
      );

      expect(updated.name, 'Concor Updated');
      expect(updated.stockCount, 20);
    });

    test('deleteMedication calls DELETE /medications/{id}', () async {
      when(
        () => dio.delete<Map<String, dynamic>>('/medications/med-1'),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/medications/med-1'),
          statusCode: 200,
          data: {'status': 'success'},
        ),
      );

      await repository.deleteMedication('med-1');
      verify(
        () => dio.delete<Map<String, dynamic>>('/medications/med-1'),
      ).called(1);
    });

    test('listSchedules calls GET /medications/{id}/schedules', () async {
      when(
        () => dio.get<List<dynamic>>('/medications/med-1/schedules'),
      ).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/medications/med-1/schedules'),
          statusCode: 200,
          data: [
            {
              'id': 'sched-1',
              'medication_id': 'med-1',
              'time_of_day': '08:00',
              'dose_amount': 1.0,
              'meal_relation': 'after_meal',
              'days_mask': 127,
              'instructions_ar': 'بعد الفطار',
              'is_active': true,
            },
          ],
        ),
      );

      final schedules = await repository.listSchedules('med-1');
      expect(schedules, hasLength(1));
      expect(schedules.first.id, 'sched-1');
      expect(schedules.first.timeOfDay, '08:00');
    });

    test('createSchedule calls POST /medications/{id}/schedules', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/medications/med-1/schedules',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/medications/med-1/schedules'),
          statusCode: 201,
          data: {
            'id': 'sched-2',
            'medication_id': 'med-1',
            'time_of_day': '20:00',
            'dose_amount': 1.0,
            'meal_relation': 'before_meal',
            'days_mask': 127,
            'instructions_ar': null,
            'is_active': true,
          },
        ),
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

    test('getTodayDoses calls GET /patients/{id}/today', () async {
      when(
        () => dio.get<List<dynamic>>('/patients/patient-1/today'),
      ).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/patients/patient-1/today'),
          statusCode: 200,
          data: [
            {
              'schedule_id': 'sched-1',
              'medication_id': 'med-1',
              'medication_name': 'Concor',
              'time_of_day': '08:00',
              'dose_amount': 1.0,
              'meal_relation': 'after_meal',
              'instructions_ar': 'بعد الفطار',
              'status': 'pending',
              'intake_log_id': null,
              'actual_time': null,
            },
          ],
        ),
      );

      final today = await repository.getTodayDoses('patient-1');
      expect(today, hasLength(1));
      expect(today.first.scheduleId, 'sched-1');
      expect(today.first.medicationName, 'Concor');
      expect(today.first.status, 'pending');
    });
  });

  group('MedicationRepository Supabase Fallback', () {
    test('listMedications falls back to Supabase on DioException', () async {
      when(() => dio.get<List<dynamic>>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/patients/p-1/medications'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final fakeData = [
        {
          'id': 'med-123',
          'patient_id': 'p-1',
          'name': 'Aspirin',
          'is_active': true,
          'schedules': [
            {
              'id': 'sched-1',
              'medication_id': 'med-123',
              'time_of_day': '08:00:00',
              'dose_amount': 1.0,
              'meal_relation': 'after_meal',
              'days_mask': 127,
              'is_active': true,
            }
          ]
        }
      ];

      when(() => mockSupabase.from('medications'))
          .thenAnswer((_) => FakeQueryBuilder(fakeData));

      final res = await repository.listMedications('p-1');
      expect(res, hasLength(1));
      expect(res.first.id, 'med-123');
      expect(res.first.name, 'Aspirin');
      expect(res.first.schedules.first.timeOfDay, '08:00');
    });

    test('createMedication falls back to Supabase on DioException', () async {
      when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')))
          .thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/patients/p-1/medications'),
          type: DioExceptionType.connectionError,
        ),
      );

      final medData = {
        'id': 'med-new',
        'patient_id': 'p-1',
        'name': 'Metformin',
        'form': 'قرص',
        'stock_count': 60,
        'alert_threshold_days': 5,
        'is_active': true,
      };

      final schedData = {
        'id': 'sched-new',
        'medication_id': 'med-new',
        'time_of_day': '09:00:00',
        'dose_amount': 1.0,
        'meal_relation': 'after_meal',
        'days_mask': 127,
        'is_active': true,
      };

      when(() => mockSupabase.from('medications'))
          .thenAnswer((_) => FakeQueryBuilder(medData));
      when(() => mockSupabase.from('schedules'))
          .thenAnswer((_) => FakeQueryBuilder(schedData));

      final created = await repository.createMedication(
        'p-1',
        const MedicationCreateInput(
          name: 'Metformin',
          stockCount: 60,
          schedules: [
            ScheduleCreateInput(timeOfDay: '09:00'),
          ],
        ),
      );

      expect(created.id, 'med-new');
      expect(created.name, 'Metformin');
      expect(created.schedules, hasLength(1));
      expect(created.schedules.first.id, 'sched-new');
      expect(created.schedules.first.timeOfDay, '09:00');
    });

    test('getTodayDoses falls back to Supabase on DioException', () async {
      when(() => dio.get<List<dynamic>>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/patients/p-1/today'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final medsData = [
        {
          'id': 'med-10',
          'name': 'Concor',
          'is_active': true,
          'schedules': [
            {
              'id': 'sched-10',
              'medication_id': 'med-10',
              'time_of_day': '08:00',
              'dose_amount': 1.0,
              'meal_relation': 'after_meal',
              'is_active': true,
            }
          ]
        }
      ];

      final logsData = [
        {
          'id': 'log-10',
          'schedule_id': 'sched-10',
          'status': 'taken',
          'actual_time': '2026-10-25T08:05:00Z',
        }
      ];

      when(() => mockSupabase.from('medications'))
          .thenAnswer((_) => FakeQueryBuilder(medsData));
      when(() => mockSupabase.from('intake_logs'))
          .thenAnswer((_) => FakeQueryBuilder(logsData));

      final doses = await repository.getTodayDoses('p-1');
      expect(doses, hasLength(1));
      expect(doses.first.medicationName, 'Concor');
      expect(doses.first.status, 'taken');
      expect(doses.first.intakeLogId, 'log-10');
    });

    test('logAdherence falls back to Supabase on DioException', () async {
      when(() => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')))
          .thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/adherence/log'),
          type: DioExceptionType.connectionError,
        ),
      );

      final logData = {
        'id': 'log-new',
        'client_uuid': 'uuid-1',
        'schedule_id': 'sched-10',
        'patient_id': 'p-1',
        'scheduled_time': '2026-10-25T08:00:00Z',
        'status': 'taken',
        'logged_offline': false,
      };

      final schedData = {
        'id': 'sched-10',
        'medication_id': 'med-1',
        'dose_amount': 1.0,
        'medications': {
          'id': 'med-1',
          'patient_id': 'p-1',
          'stock_count': 10,
        }
      };

      when(() => mockSupabase.from('intake_logs'))
          .thenAnswer((_) => FakeQueryBuilder(logData));
      when(() => mockSupabase.from('schedules'))
          .thenAnswer((_) => FakeQueryBuilder(schedData));
      when(() => mockSupabase.from('medications'))
          .thenAnswer((_) => FakeQueryBuilder({'stock_count': 9}));

      final logged = await repository.logAdherence(
        IntakeLogCreateInput(
          clientUuid: 'uuid-1',
          scheduleId: 'sched-10',
          scheduledTime: DateTime.parse('2026-10-25T08:00:00Z'),
          status: 'taken',
        ),
      );

      expect(logged.id, 'log-new');
      expect(logged.status, 'taken');
    });
  });
}
