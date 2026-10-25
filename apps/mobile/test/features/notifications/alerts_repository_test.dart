import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/notifications/data/alerts_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockApiClient extends Mock implements ApiClient;

class MockDio extends Mock implements Dio;

class MockSupabaseClient extends Mock implements SupabaseClient;

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder;

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  FakePostgrestFilterBuilder({
    List<Map<String, dynamic>>? listValue,
  }) : _listValue = listValue ?? const [];

  final List<Map<String, dynamic>> _listValue;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) =>
      this;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) =>
      FakePostgrestTransformBuilder<List<Map<String, dynamic>>>(_listValue);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) {
    return Future.value(_listValue).then(onValue, onError: onError);
  }
}

class FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  FakePostgrestTransformBuilder(this._value);
  final T _value;

  @override
  PostgrestTransformBuilder<T> limit(int count, {String? referencedTable}) =>
      this;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return Future.value(_value).then(onValue, onError: onError);
  }
}

void main() {
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late MockSupabaseClient mockSupabase;
  late AlertsRepository repo;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    mockSupabase = MockSupabaseClient();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    repo = AlertsRepository(
      apiClient: mockApiClient,
      supabaseClient: mockSupabase,
    );
  });

  group('AlertsRepository API tests', () {
    test('listAlerts returns alerts on API success', () async {
      when(
        () => mockDio.get<List<dynamic>>(
          '/patients/patient-1/alerts',
          queryParameters: {'limit': 50},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/patients/patient-1/alerts',
          ),
          data: [
            {
              'id': 'alert-1',
              'patient_id': 'patient-1',
              'type': 'sos',
              'tier': 3,
              'sent_at': '2026-10-25T12:00:00Z',
              'created_at': '2026-10-25T12:00:00Z',
              'payload': {'note': 'طوارئ'},
            },
            {
              'id': 'alert-2',
              'patient_id': 'patient-1',
              'type': 'low_stock',
              'tier': 1,
              'sent_at': '2026-10-25T10:00:00Z',
              'created_at': '2026-10-25T10:00:00Z',
              'payload': {'medication_name': 'Panadol'},
            },
          ],
        ),
      );

      final alerts = await repo.listAlerts('patient-1');
      expect(alerts, hasLength(2));
      expect(alerts.first.id, 'alert-1');
      expect(alerts.first.type, 'sos');
      expect(alerts.first.tier, 3);
      expect(alerts.first.note, 'طوارئ');
      expect(alerts.last.medicationName, 'Panadol');
    });

    test('rethrows 401 error', () async {
      when(
        () => mockDio.get<List<dynamic>>(
          '/patients/patient-1/alerts',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/patients/patient-1/alerts',
          ),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(
              path: '/patients/patient-1/alerts',
            ),
          ),
          error: ApiException(message: 'غير مصرح', statusCode: 401),
        ),
      );

      expect(
        () => repo.listAlerts('patient-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('AlertsRepository Supabase Fallback', () {
    test(
        'listAlerts fetches directly from alerts table in Supabase when API is unavailable',
        () async {
      when(
        () => mockDio.get<List<dynamic>>(
          '/patients/patient-1/alerts',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/patients/patient-1/alerts'),
          type: DioExceptionType.connectionError,
        ),
      );

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      when(() => mockSupabase.from('alerts'))
          .thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select).thenAnswer(
        (_) => FakePostgrestFilterBuilder(
          listValue: [
            {
              'id': 'sb-alert-1',
              'patient_id': 'patient-1',
              'type': 'sos',
              'tier': 3,
              'sent_at': '2026-10-25T14:00:00Z',
              'created_at': '2026-10-25T14:00:00Z',
              'payload_json': '{"note": "طوارئ من سوپابيس"}',
            },
            {
              'id': 'sb-alert-2',
              'patient_id': 'patient-1',
              'type': 'critical_vital',
              'tier': 2,
              'sent_at': '2026-10-25T13:00:00Z',
              'created_at': '2026-10-25T13:00:00Z',
              'payload': {
                'type': 'bp',
                'value_primary': 180,
                'value_secondary': 110,
              },
            },
          ],
        ),
      );

      final alerts = await repo.listAlerts('patient-1');

      expect(alerts, hasLength(2));
      expect(alerts[0].id, 'sb-alert-1');
      expect(alerts[0].type, 'sos');
      expect(alerts[0].note, 'طوارئ من سوپابيس');
      expect(alerts[1].id, 'sb-alert-2');
      expect(alerts[1].type, 'critical_vital');
      expect(alerts[1].vitalValuePrimary, 180.0);
    });
  });
}
