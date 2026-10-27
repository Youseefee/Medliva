import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/vitals/data/vitals_repository.dart';
import 'package:medliva/features/vitals/domain/models/vital.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient;

class FakeTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
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
  PostgrestTransformBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) => FakeTransformBuilder<List<Map<String, dynamic>>>(
    _data is List
        ? List<Map<String, dynamic>>.from(_data)
        : [_data as Map<String, dynamic>],
  );

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<T> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) => this;

  @override
  PostgrestTransformBuilder<T> limit(int count, {String? referencedTable}) =>
      this;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() =>
      FakeTransformBuilder<Map<String, dynamic>>(
        _data is List
            ? _data.first as Map<String, dynamic>
            : _data as Map<String, dynamic>,
      );

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
  ]) => FakeFilterBuilder<List<Map<String, dynamic>>>(_data);

  @override
  PostgrestFilterBuilder<dynamic> insert(
    Object values, {
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

void main() {
  late MockSupabaseClient mockSupabase;
  late VitalsRepository repository;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    repository = VitalsRepository(supabaseClient: mockSupabase);
  });

  group('VitalsRepository Supabase operations', () {
    test(
      'listVitals reads the newest patient readings from Supabase',
      () async {
        when(() => mockSupabase.from('vitals_logs')).thenAnswer(
          (_) => FakeQueryBuilder([
            {
              'id': 'v-1',
              'patient_id': 'patient-1',
              'type': 'bp',
              'value_primary': 120,
              'value_secondary': 80,
              'band': 'normal',
              'recorded_at': '2026-10-25T12:00:00Z',
            },
          ]),
        );

        final res = await repository.listVitals('patient-1');
        expect(res, hasLength(1));
        expect(res.first.id, 'v-1');
        expect(res.first.type, 'bp');
        expect(res.first.valuePrimary, 120.0);
      },
    );

    test(
      'createVital uses the database RPC for triage and alert creation',
      () async {
        when(
          () => mockSupabase.rpc<Map<String, dynamic>>(
            'record_vital',
            params: any(named: 'params'),
          ),
        ).thenAnswer(
          (_) => FakeRpcBuilder<Map<String, dynamic>>({
            'id': 'v-new',
            'patient_id': 'patient-1',
            'type': 'bp',
            'value_primary': 185,
            'value_secondary': 125,
            'band': 'critical',
            'recorded_at': '2026-10-25T12:00:00Z',
          }),
        );

        final res = await repository.createVital(
          'patient-1',
          const VitalCreateInput(
            type: 'bp',
            valuePrimary: 185,
            valueSecondary: 125,
          ),
        );

        expect(res.id, 'v-new');
        expect(res.band, 'critical');
        final captured =
            verify(
                  () => mockSupabase.rpc<Map<String, dynamic>>(
                    'record_vital',
                    params: captureAny(named: 'params'),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(captured['p_patient_id'], 'patient-1');
        expect(captured['p_type'], 'bp');
        expect(captured['p_value_primary'], 185);
      },
    );
  });

  group('VitalsRepository Triage Logic', () {
    test('triage BP correctly', () {
      expect(
        VitalsRepository.computeTriageBand(
          type: 'bp',
          valuePrimary: 120,
          valueSecondary: 80,
        ),
        'normal',
      );
      expect(
        VitalsRepository.computeTriageBand(
          type: 'bp',
          valuePrimary: 135,
          valueSecondary: 85,
        ),
        'borderline',
      );
      expect(
        VitalsRepository.computeTriageBand(
          type: 'bp',
          valuePrimary: 190,
          valueSecondary: 110,
        ),
        'critical',
      );
      expect(
        VitalsRepository.computeTriageBand(
          type: 'bp',
          valuePrimary: 85,
          valueSecondary: 55,
        ),
        'critical',
      );
    });

    test('triage glucose correctly', () {
      expect(
        VitalsRepository.computeTriageBand(
          type: 'glucose',
          valuePrimary: 95,
          mealContext: 'fasting',
        ),
        'normal',
      );
      expect(
        VitalsRepository.computeTriageBand(
          type: 'glucose',
          valuePrimary: 125,
          mealContext: 'fasting',
        ),
        'borderline',
      );
      expect(
        VitalsRepository.computeTriageBand(
          type: 'glucose',
          valuePrimary: 260,
          mealContext: 'fasting',
        ),
        'critical',
      );
      expect(
        VitalsRepository.computeTriageBand(
          type: 'glucose',
          valuePrimary: 60,
          mealContext: 'fasting',
        ),
        'critical',
      );

      expect(
        VitalsRepository.computeTriageBand(
          type: 'glucose',
          valuePrimary: 130,
          mealContext: 'post_prandial',
        ),
        'normal',
      );
      expect(
        VitalsRepository.computeTriageBand(
          type: 'glucose',
          valuePrimary: 160,
          mealContext: 'post_prandial',
        ),
        'borderline',
      );
      expect(
        VitalsRepository.computeTriageBand(
          type: 'glucose',
          valuePrimary: 310,
          mealContext: 'post_prandial',
        ),
        'critical',
      );
    });

    test('triage pulse correctly', () {
      expect(
        VitalsRepository.computeTriageBand(type: 'pulse', valuePrimary: 75),
        'normal',
      );
      expect(
        VitalsRepository.computeTriageBand(type: 'pulse', valuePrimary: 105),
        'borderline',
      );
      expect(
        VitalsRepository.computeTriageBand(type: 'pulse', valuePrimary: 45),
        'critical',
      );
      expect(
        VitalsRepository.computeTriageBand(type: 'pulse', valuePrimary: 130),
        'critical',
      );
    });
  });
}
