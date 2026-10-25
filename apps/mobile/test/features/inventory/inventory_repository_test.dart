import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/inventory/data/inventory_repository.dart';
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
    Map<String, dynamic>? singleValue,
  })  : _listValue = listValue ?? const [],
        _singleValue = singleValue;

  final List<Map<String, dynamic>> _listValue;
  final Map<String, dynamic>? _singleValue;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) =>
      this;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() =>
      FakePostgrestTransformBuilder<Map<String, dynamic>?>(_singleValue);

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() =>
      FakePostgrestTransformBuilder<Map<String, dynamic>>(
        _singleValue ?? (_listValue.isNotEmpty ? _listValue.first : {}),
      );

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
  late InventoryRepository repo;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    mockSupabase = MockSupabaseClient();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    repo = InventoryRepository(
      apiClient: mockApiClient,
      supabaseClient: mockSupabase,
    );
  });

  group('InventoryRepository API tests', () {
    test('getForecast returns medications forecast on API success', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/patients/patient-1/inventory/forecast',
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/patients/patient-1/inventory/forecast',
          ),
          data: {
            'medications': [
              {
                'medication_id': 'med-1',
                'name': 'Panadol',
                'stock_count': 10,
                'days_remaining': 5,
                'is_low_stock': true,
              },
            ],
            'low_stock_count': 1,
            'expired_count': 0,
          },
        ),
      );

      final result = await repo.getForecast('patient-1');
      expect(result, hasLength(1));
      expect(result.first.medicationId, 'med-1');
      expect(result.first.name, 'Panadol');
      expect(result.first.stockCount, 10);
      expect(result.first.daysRemaining, 5);
      expect(result.first.isLowStock, isTrue);
    });

    test('createRefillOrder returns result on API success', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/patients/patient-1/inventory/refill-order',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/patients/patient-1/inventory/refill-order',
          ),
          data: {
            'message_text': 'طلب نواقص',
            'whatsapp_url': 'https://wa.me/201234567890?text=test',
          },
        ),
      );

      final result = await repo.createRefillOrder(
        patientId: 'patient-1',
        medicationName: 'Panadol',
        quantity: 2,
      );

      expect(result.messageText, 'طلب نواقص');
      expect(result.whatsappUrl, contains('wa.me'));
    });

    test('rethrows 401 DioException', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/patients/patient-1/inventory/forecast',
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/patients/patient-1/inventory/forecast',
          ),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(
              path: '/patients/patient-1/inventory/forecast',
            ),
          ),
          error: ApiException(message: 'غير مصرح', statusCode: 401),
        ),
      );

      expect(
        () => repo.getForecast('patient-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('InventoryRepository Supabase Fallback', () {
    test('getForecast computes remaining days from Supabase medications and schedules',
        () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/patients/patient-1/inventory/forecast',
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/patients/patient-1/inventory/forecast',
          ),
          type: DioExceptionType.connectionError,
        ),
      );

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      when(() => mockSupabase.from('medications'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select('*, schedules(*)')).thenAnswer(
        (_) => FakePostgrestFilterBuilder(
          listValue: [
            {
              'id': 'med-10',
              'name': 'Concor 5mg',
              'stock_count': 20,
              'alert_threshold_days': 5,
              'is_active': true,
              'schedules': [
                {
                  'id': 'sched-1',
                  'medication_id': 'med-10',
                  'dose_amount': 2.0,
                  'is_active': true,
                },
              ],
            },
            {
              'id': 'med-20',
              'name': 'Glucophage 1000mg',
              'stock_count': 6,
              'alert_threshold_days': 5,
              'is_active': true,
              'schedules': [
                {
                  'id': 'sched-2',
                  'medication_id': 'med-20',
                  'dose_amount': 2.0,
                  'is_active': true,
                },
              ],
            },
          ],
        ),
      );

      final forecasts = await repo.getForecast('patient-1');

      expect(forecasts, hasLength(2));
      // Concor: 20 pills / 2 pills per day = 10 days remaining (> threshold 5 => isLowStock false)
      expect(forecasts[0].medicationId, 'med-10');
      expect(forecasts[0].name, 'Concor 5mg');
      expect(forecasts[0].stockCount, 20);
      expect(forecasts[0].daysRemaining, 10);
      expect(forecasts[0].isLowStock, isFalse);

      // Glucophage: 6 pills / 2 pills per day = 3 days remaining (<= threshold 5 => isLowStock true)
      expect(forecasts[1].medicationId, 'med-20');
      expect(forecasts[1].name, 'Glucophage 1000mg');
      expect(forecasts[1].stockCount, 6);
      expect(forecasts[1].daysRemaining, 3);
      expect(forecasts[1].isLowStock, isTrue);
    });

    test('createRefillOrder generates WhatsApp refill order via fallback',
        () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/patients/patient-1/inventory/refill-order',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/patients/patient-1/inventory/refill-order',
          ),
          type: DioExceptionType.connectionError,
        ),
      );

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      when(() => mockSupabase.from('users'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select('name, address')).thenAnswer(
        (_) => FakePostgrestFilterBuilder(
          singleValue: {
            'name': 'محمود علي',
            'address': 'المعادي - القاهرة',
          },
        ),
      );

      final res = await repo.createRefillOrder(
        patientId: 'patient-1',
        medicationName: 'Concor 5mg',
        quantity: 2,
      );

      expect(res.messageText, contains('محمود علي'));
      expect(res.messageText, contains('Concor 5mg: 2 عبوة'));
      expect(res.messageText, contains('المعادي - القاهرة'));
      expect(res.whatsappUrl, contains('wa.me'));
    });
  });
}
