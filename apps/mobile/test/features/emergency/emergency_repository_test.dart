import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/emergency/data/emergency_repository.dart';
import 'package:medliva/features/emergency/domain/models/emergency.dart';
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
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) =>
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
  PostgrestTransformBuilder<T> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) =>
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
  late EmergencyRepository repo;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    mockSupabase = MockSupabaseClient();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    repo = EmergencyRepository(
      apiClient: mockApiClient,
      supabaseClient: mockSupabase,
    );
  });

  group('EmergencyRepository API tests', () {
    test('listContacts and getContacts return contacts on API success',
        () async {
      when(
        () => mockDio.get<List<dynamic>>('/patients/patient-1/contacts'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/patients/patient-1/contacts',
          ),
          data: [
            {
              'id': 'contact-1',
              'patient_id': 'patient-1',
              'name': 'أحمد',
              'phone': '01012345678',
              'relationship': 'ابن',
              'is_primary': true,
            },
          ],
        ),
      );

      final listResult = await repo.listContacts('patient-1');
      expect(listResult, hasLength(1));
      expect(listResult.first.id, 'contact-1');
      expect(listResult.first.name, 'أحمد');
      expect(listResult.first.isPrimary, isTrue);

      final getResult = await repo.getContacts('patient-1');
      expect(getResult, hasLength(1));
      expect(getResult.first.name, 'أحمد');
    });

    test('createContact and addContact create contact on API success',
        () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/patients/patient-1/contacts',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/patients/patient-1/contacts',
          ),
          data: {
            'id': 'contact-2',
            'patient_id': 'patient-1',
            'name': 'منى',
            'phone': '01123456789',
            'relationship': 'ابنة',
            'is_primary': false,
          },
        ),
      );

      const input = EmergencyContactCreateInput(
        name: 'منى',
        phone: '01123456789',
        relationship: 'ابنة',
      );

      final created = await repo.createContact('patient-1', input);
      expect(created.id, 'contact-2');
      expect(created.name, 'منى');

      final added = await repo.addContact('patient-1', input);
      expect(added.id, 'contact-2');
    });

    test('triggerSos sends SOS and returns SosResponseModel on API success',
        () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/emergency/sos',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/emergency/sos',
          ),
          data: {
            'status': 'active',
            'alert_id': 'alert-sos-1',
            'notified_contacts_count': 3,
          },
        ),
      );

      final res = await repo.triggerSos(
        lat: 30.0444,
        lng: 31.2357,
        note: 'طوارئ',
      );

      expect(res.status, 'active');
      expect(res.alertId, 'alert-sos-1');
      expect(res.notifiedContactsCount, 3);
    });

    test('rethrows 401 error', () async {
      when(
        () => mockDio.get<List<dynamic>>('/patients/patient-1/contacts'),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/patients/patient-1/contacts',
          ),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(
              path: '/patients/patient-1/contacts',
            ),
          ),
          error: ApiException(message: 'غير مصرح', statusCode: 401),
        ),
      );

      expect(
        () => repo.listContacts('patient-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('EmergencyRepository Supabase Fallback', () {
    test('getContacts fetches from emergency_contacts table in Supabase',
        () async {
      when(
        () => mockDio.get<List<dynamic>>('/patients/patient-1/contacts'),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/patients/patient-1/contacts'),
          type: DioExceptionType.connectionError,
        ),
      );

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      when(() => mockSupabase.from('emergency_contacts'))
          .thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select).thenAnswer(
        (_) => FakePostgrestFilterBuilder(
          listValue: [
            {
              'id': 'contact-sb-1',
              'patient_id': 'patient-1',
              'name': 'سارة',
              'phone': '01055555555',
              'relationship': 'زوجة',
              'is_primary': true,
            },
          ],
        ),
      );

      final contacts = await repo.getContacts('patient-1');
      expect(contacts, hasLength(1));
      expect(contacts.first.id, 'contact-sb-1');
      expect(contacts.first.name, 'سارة');
      expect(contacts.first.isPrimary, isTrue);
    });

    test('addContact inserts into emergency_contacts in Supabase', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/patients/patient-1/contacts',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/patients/patient-1/contacts'),
          type: DioExceptionType.connectionError,
        ),
      );

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      when(() => mockSupabase.from('emergency_contacts'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.insert(any())).thenAnswer(
        (_) => FakePostgrestFilterBuilder(
          singleValue: {
            'id': 'contact-sb-2',
            'patient_id': 'patient-1',
            'name': 'كريم',
            'phone': '01066666666',
            'relationship': 'ابن',
            'is_primary': false,
          },
        ),
      );

      final created = await repo.addContact(
        'patient-1',
        const EmergencyContactCreateInput(
          name: 'كريم',
          phone: '01066666666',
          relationship: 'ابن',
        ),
      );

      expect(created.id, 'contact-sb-2');
      expect(created.name, 'كريم');
      expect(created.phone, '01066666666');
    });

    test('triggerSos inserts SOS alert into alerts table in Supabase', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/emergency/sos',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/emergency/sos'),
          type: DioExceptionType.connectionError,
        ),
      );

      final mockQueryBuilderAlerts = MockSupabaseQueryBuilder();
      final mockQueryBuilderUsers = MockSupabaseQueryBuilder();
      final mockQueryBuilderContacts = MockSupabaseQueryBuilder();
      final mockQueryBuilderCaregivers = MockSupabaseQueryBuilder();

      when(() => mockSupabase.from('alerts'))
          .thenAnswer((_) => mockQueryBuilderAlerts);
      when(() => mockSupabase.from('users'))
          .thenAnswer((_) => mockQueryBuilderUsers);
      when(() => mockSupabase.from('emergency_contacts'))
          .thenAnswer((_) => mockQueryBuilderContacts);
      when(() => mockSupabase.from('caregiver_links'))
          .thenAnswer((_) => mockQueryBuilderCaregivers);

      when(() => mockQueryBuilderUsers.select('name, phone')).thenAnswer(
        (_) => FakePostgrestFilterBuilder(
          singleValue: {'name': 'المريض التجريبي', 'phone': '01011111111'},
        ),
      );

      when(() => mockQueryBuilderContacts.select('id')).thenAnswer(
        (_) => FakePostgrestFilterBuilder(listValue: [{'id': 'c1'}, {'id': 'c2'}]),
      );

      when(() => mockQueryBuilderCaregivers.select('id')).thenAnswer(
        (_) => FakePostgrestFilterBuilder(listValue: [{'id': 'cg1'}]),
      );

      when(() => mockQueryBuilderAlerts.insert(any())).thenAnswer(
        (_) => FakePostgrestFilterBuilder(
          singleValue: {'id': 'alert-sb-sos-99'},
        ),
      );

      final sos = await repo.triggerSos(
        patientId: 'patient-1',
        lat: 29.9792,
        lng: 31.1342,
        note: 'سقوط مفاجئ',
      );

      expect(sos.status, 'active');
      expect(sos.alertId, 'alert-sb-sos-99');
      // 2 contacts + 1 caregiver = 3
      expect(sos.notifiedContactsCount, 3);
    });
  });
}
