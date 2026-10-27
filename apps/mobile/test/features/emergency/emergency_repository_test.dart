import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/emergency/data/emergency_repository.dart';
import 'package:medliva/features/emergency/domain/models/emergency.dart';
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
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) => this;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) => FakePostgrestTransformBuilder<List<Map<String, dynamic>>>(_rows);

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() =>
      FakePostgrestTransformBuilder<Map<String, dynamic>>(
        _row ?? (_rows.isNotEmpty ? _rows.first : const {}),
      );

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
  PostgrestTransformBuilder<T> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) => this;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) => Future.value(_value).then(onValue, onError: onError);
}

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
  late MockSupabaseQueryBuilder query;
  late EmergencyRepository repository;

  setUp(() {
    supabase = MockSupabaseClient();
    query = MockSupabaseQueryBuilder();
    repository = EmergencyRepository(supabaseClient: supabase);
  });

  test('loads contacts directly from the RLS-protected table', () async {
    when(() => supabase.from('emergency_contacts')).thenAnswer((_) => query);
    when(() => query.select()).thenAnswer(
      (_) => FakePostgrestFilterBuilder(
        rows: [
          {
            'id': 'contact-1',
            'patient_id': 'patient-1',
            'name': 'منى',
            'phone': '01012345678',
            'relationship': 'ابنة',
            'is_primary': true,
          },
        ],
      ),
    );

    final contacts = await repository.listContacts('patient-1');
    expect(contacts, hasLength(1));
    expect(contacts.single.name, 'منى');
    expect(contacts.single.isPrimary, isTrue);
  });

  test('creates an emergency contact through PostgREST', () async {
    when(() => supabase.from('emergency_contacts')).thenAnswer((_) => query);
    when(() => query.insert(any())).thenAnswer(
      (_) => FakePostgrestFilterBuilder(
        row: {
          'id': 'contact-2',
          'patient_id': 'patient-1',
          'name': 'كريم',
          'phone': '01066666666',
          'relationship': 'ابن',
          'is_primary': false,
        },
      ),
    );

    final contact = await repository.addContact(
      'patient-1',
      const EmergencyContactCreateInput(
        name: 'كريم',
        phone: '01066666666',
        relationship: 'ابن',
      ),
    );
    expect(contact.id, 'contact-2');
    expect(contact.patientId, 'patient-1');
  });

  test('triggers SOS through the restricted database function', () async {
    when(
      () => supabase.rpc<dynamic>('trigger_sos', params: any(named: 'params')),
    ).thenAnswer(
      (_) => FakeRpcBuilder({
        'status': 'active',
        'alert_id': 'alert-1',
        'notified_contacts_count': 3,
      }),
    );

    final result = await repository.triggerSos(
      lat: 30.04,
      lng: 31.23,
      note: 'حالة طارئة',
    );
    expect(result.status, 'active');
    expect(result.alertId, 'alert-1');
    expect(result.notifiedContactsCount, 3);
    verify(
      () => supabase.rpc<dynamic>(
        'trigger_sos',
        params: {'p_lat': 30.04, 'p_lng': 31.23, 'p_note': 'حالة طارئة'},
      ),
    ).called(1);
  });
}
