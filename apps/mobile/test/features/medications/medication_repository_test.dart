import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient;

class MockDio extends Mock implements Dio;

void main() {
  late MockApiClient apiClient;
  late MockDio dio;
  late MedicationRepository repository;

  setUp(() {
    apiClient = MockApiClient();
    dio = MockDio();
    when(() => apiClient.dio).thenReturn(dio);
    repository = MedicationRepository(apiClient: apiClient);
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

  group('MedicationRepository', () {
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
}
