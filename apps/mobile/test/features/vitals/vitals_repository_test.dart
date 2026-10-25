import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/vitals/data/vitals_repository.dart';
import 'package:medliva/features/vitals/domain/models/vital.dart';
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
  PostgrestTransformBuilder<Map<String, dynamic>> single() =>
      FakeTransformBuilder<Map<String, dynamic>>(
        _data is List
            ? _data.first as Map<String, dynamic>
            : _data as Map<String, dynamic>,
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
}

void main() {
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late MockSupabaseClient mockSupabase;
  late VitalsRepository repository;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    mockSupabase = MockSupabaseClient();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    repository = VitalsRepository(
      apiClient: mockApiClient,
      supabaseClient: mockSupabase,
    );
  });

  group('VitalsRepository API Operations', () {
    test('listVitals calls GET /patients/{id}/vitals', () async {
      when(() => mockDio.get<List<dynamic>>('/patients/patient-1/vitals'))
          .thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/patients/patient-1/vitals'),
          statusCode: 200,
          data: [
            {
              'id': 'v-1',
              'patient_id': 'patient-1',
              'type': 'bp',
              'value_primary': 120,
              'value_secondary': 80,
              'band': 'normal',
              'recorded_at': '2026-10-25T10:00:00Z',
            }
          ],
        ),
      );

      final res = await repository.listVitals('patient-1');
      expect(res, hasLength(1));
      expect(res.first.id, 'v-1');
      expect(res.first.type, 'bp');
      expect(res.first.valuePrimary, 120.0);
      expect(res.first.band, 'normal');
    });

    test('createVital calls POST /patients/{id}/vitals', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/patients/patient-1/vitals',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/patients/patient-1/vitals'),
          statusCode: 201,
          data: {
            'id': 'v-2',
            'patient_id': 'patient-1',
            'type': 'glucose',
            'value_primary': 115,
            'band': 'borderline',
            'meal_context': 'fasting',
            'recorded_at': '2026-10-25T10:00:00Z',
          },
        ),
      );

      final res = await repository.createVital(
        'patient-1',
        const VitalCreateInput(
          type: 'glucose',
          valuePrimary: 115,
          mealContext: 'fasting',
        ),
      );

      expect(res.id, 'v-2');
      expect(res.band, 'borderline');
    });
  });

  group('VitalsRepository Supabase Fallback', () {
    test('listVitals falls back to Supabase on DioException', () async {
      when(() => mockDio.get<List<dynamic>>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/patients/p-1/vitals'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final fakeData = [
        {
          'id': 'v-sup-1',
          'patient_id': 'p-1',
          'type': 'pulse',
          'value_primary': 72,
          'band': 'normal',
          'recorded_at': '2026-10-25T12:00:00Z',
        }
      ];

      when(() => mockSupabase.from('vitals_logs'))
          .thenAnswer((_) => FakeQueryBuilder(fakeData));

      final res = await repository.listVitals('p-1');
      expect(res, hasLength(1));
      expect(res.first.id, 'v-sup-1');
      expect(res.first.type, 'pulse');
      expect(res.first.valuePrimary, 72.0);
    });

    test('createVital falls back to Supabase with local triage band calculation', () async {
      when(() => mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')))
          .thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/patients/p-1/vitals'),
          type: DioExceptionType.connectionError,
        ),
      );

      final insertedData = {
        'id': 'v-sup-new',
        'patient_id': 'p-1',
        'type': 'bp',
        'value_primary': 185,
        'value_secondary': 125,
        'band': 'critical',
        'recorded_at': '2026-10-25T12:00:00Z',
      };

      when(() => mockSupabase.from('vitals_logs'))
          .thenAnswer((_) => FakeQueryBuilder(insertedData));

      final res = await repository.createVital(
        'p-1',
        const VitalCreateInput(
          type: 'bp',
          valuePrimary: 185,
          valueSecondary: 125,
        ),
      );

      expect(res.id, 'v-sup-new');
      expect(res.band, 'critical');
    });

    test('parseVoiceVitals falls back to local parsing on DioException', () async {
      when(() => mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')))
          .thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/ai/parse-voice-vitals'),
          type: DioExceptionType.connectionError,
        ),
      );

      final parsed = await repository.parseVoiceVitals('الضغط ١٣٥ على ٨٥');
      expect(parsed.type, 'bp');
      expect(parsed.valuePrimary, 135.0);
      expect(parsed.valueSecondary, 85.0);
      expect(parsed.band, 'borderline');
    });
  });

  group('VitalsRepository Triage Logic', () {
    test('triage BP correctly', () {
      expect(VitalsRepository.computeTriageBand(type: 'bp', valuePrimary: 120, valueSecondary: 80), 'normal');
      expect(VitalsRepository.computeTriageBand(type: 'bp', valuePrimary: 135, valueSecondary: 85), 'borderline');
      expect(VitalsRepository.computeTriageBand(type: 'bp', valuePrimary: 190, valueSecondary: 110), 'critical');
      expect(VitalsRepository.computeTriageBand(type: 'bp', valuePrimary: 85, valueSecondary: 55), 'critical');
    });

    test('triage glucose correctly', () {
      expect(VitalsRepository.computeTriageBand(type: 'glucose', valuePrimary: 95, mealContext: 'fasting'), 'normal');
      expect(VitalsRepository.computeTriageBand(type: 'glucose', valuePrimary: 125, mealContext: 'fasting'), 'borderline');
      expect(VitalsRepository.computeTriageBand(type: 'glucose', valuePrimary: 260, mealContext: 'fasting'), 'critical');
      expect(VitalsRepository.computeTriageBand(type: 'glucose', valuePrimary: 60, mealContext: 'fasting'), 'critical');

      expect(VitalsRepository.computeTriageBand(type: 'glucose', valuePrimary: 130, mealContext: 'post_prandial'), 'normal');
      expect(VitalsRepository.computeTriageBand(type: 'glucose', valuePrimary: 160, mealContext: 'post_prandial'), 'borderline');
      expect(VitalsRepository.computeTriageBand(type: 'glucose', valuePrimary: 310, mealContext: 'post_prandial'), 'critical');
    });

    test('triage pulse correctly', () {
      expect(VitalsRepository.computeTriageBand(type: 'pulse', valuePrimary: 75), 'normal');
      expect(VitalsRepository.computeTriageBand(type: 'pulse', valuePrimary: 105), 'borderline');
      expect(VitalsRepository.computeTriageBand(type: 'pulse', valuePrimary: 45), 'critical');
      expect(VitalsRepository.computeTriageBand(type: 'pulse', valuePrimary: 130), 'critical');
    });
  });
}
