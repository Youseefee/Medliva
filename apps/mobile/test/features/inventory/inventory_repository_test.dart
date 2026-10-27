import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/inventory/data/inventory_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient;

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder;

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  FakePostgrestFilterBuilder({
    List<Map<String, dynamic>>? rows,
    Map<String, dynamic>? row,
  }) : _rows = rows ?? const [],
       _row = row;

  final List<Map<String, dynamic>> _rows;
  final Map<String, dynamic>? _row;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) => this;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() =>
      FakePostgrestTransformBuilder<Map<String, dynamic>?>(_row);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) => Future.value(_rows).then(onValue, onError: onError);
}

class FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  FakePostgrestTransformBuilder(this._value);

  final T _value;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) => Future.value(_value).then(onValue, onError: onError);
}

void main() {
  late MockSupabaseClient supabase;
  late MockSupabaseQueryBuilder query;
  late InventoryRepository repository;

  setUp(() {
    supabase = MockSupabaseClient();
    query = MockSupabaseQueryBuilder();
    repository = InventoryRepository(supabaseClient: supabase);
  });

  test('computes stock and expiry forecasts from Supabase rows', () async {
    when(() => supabase.from('medications')).thenAnswer((_) => query);
    when(
      () => query.select(
        'id, name, stock_count, alert_threshold_days, expiry_date, '
        'schedules(dose_amount, is_active)',
      ),
    ).thenAnswer(
      (_) => FakePostgrestFilterBuilder(
        rows: [
          {
            'id': 'med-1',
            'name': 'Concor 5mg',
            'stock_count': 20,
            'alert_threshold_days': 5,
            'expiry_date': null,
            'schedules': [
              {'dose_amount': 2, 'is_active': true},
            ],
          },
          {
            'id': 'med-2',
            'name': 'Glucophage',
            'stock_count': 6,
            'alert_threshold_days': 5,
            'expiry_date': '2020-01-01',
            'schedules': [
              {'dose_amount': 2, 'is_active': true},
            ],
          },
        ],
      ),
    );

    final forecasts = await repository.getForecast('patient-1');
    expect(forecasts, hasLength(2));
    expect(forecasts[0].daysRemaining, 10);
    expect(forecasts[0].isLowStock, isFalse);
    expect(forecasts[1].daysRemaining, 3);
    expect(forecasts[1].isLowStock, isTrue);
    expect(forecasts[1].isExpired, isTrue);
  });

  test('builds a refill WhatsApp message from the Supabase profile', () async {
    when(() => supabase.from('users')).thenAnswer((_) => query);
    when(() => query.select('name, address')).thenAnswer(
      (_) => FakePostgrestFilterBuilder(
        row: {'name': 'محمود علي', 'address': 'المعادي - القاهرة'},
      ),
    );

    final result = await repository.createRefillOrder(
      patientId: 'patient-1',
      medicationName: 'Concor 5mg',
      quantity: 2,
    );
    expect(result.messageText, contains('محمود علي'));
    expect(result.messageText, contains('Concor 5mg: 2 عبوة'));
    expect(result.messageText, contains('المعادي - القاهرة'));
    expect(result.whatsappUrl, startsWith('https://wa.me/?text='));
  });
}
