import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/caregiver/data/caregiver_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockApiClient extends Mock implements ApiClient;

class MockDio extends Mock implements Dio;

class MockSupabaseClient extends Mock implements SupabaseClient;

class MockGoTrueClient extends Mock implements GoTrueClient;

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
  PostgrestFilterBuilder<List<Map<String, dynamic>>> filter(
    String column,
    String operator,
    Object? value,
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
  late MockGoTrueClient mockAuth;
  late CaregiverRepository repo;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    when(() => mockSupabase.auth).thenReturn(mockAuth);

    const mockUser = User(
      id: 'current-user-id',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-10-25T12:00:00Z',
    );
    when(() => mockAuth.currentUser).thenReturn(mockUser);

    repo = CaregiverRepository(
      apiClient: mockApiClient,
      supabaseClient: mockSupabase,
    );
  });

  group('CaregiverRepository API tests', () {
    test('generatePairingCode returns code and expiration on API success',
        () async {
      when(
        () => mockDio.post<Map<String, dynamic>>('/caregiver/pairing-code'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/caregiver/pairing-code'),
          data: {
            'code': '123456',
            'expires_at': '2026-10-25T12:10:00Z',
          },
        ),
      );

      final result = await repo.generatePairingCode();
      expect(result.code, '123456');
      expect(result.expiresAt.isUtc, isTrue);
    });

    test('pairWithPatient pairs and returns linked patient on API success',
        () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/caregiver/pair',
          data: {'code': '123456'},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/caregiver/pair'),
          data: {
            'patient_id': 'patient-1',
            'name': 'الوالد',
            'phone': '01012345678',
            'status': 'active',
            'linked_at': '2026-10-25T12:00:00Z',
          },
        ),
      );

      final patient = await repo.pairWithPatient('123456');
      expect(patient.patientId, 'patient-1');
      expect(patient.name, 'الوالد');
      expect(patient.status, 'active');
    });

    test('listLinkedPatients returns linked patients on API success', () async {
      when(
        () => mockDio.get<List<dynamic>>('/caregiver/patients'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/caregiver/patients'),
          data: [
            {
              'patient_id': 'patient-1',
              'name': 'الوالد',
              'phone': '01012345678',
              'status': 'active',
              'today_taken_count': 2,
              'today_missed_count': 0,
              'active_alerts_count': 0,
            },
          ],
        ),
      );

      final patients = await repo.listLinkedPatients();
      expect(patients, hasLength(1));
      expect(patients.first.patientId, 'patient-1');
      expect(patients.first.todayTakenCount, 2);
    });

    test('listPatientCaregivers returns caregivers on API success', () async {
      when(
        () => mockDio.get<List<dynamic>>('/patients/patient-1/caregivers'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/patients/patient-1/caregivers',
          ),
          data: [
            {
              'caregiver_id': 'caregiver-1',
              'name': 'أحمد',
              'phone': '01098765432',
              'status': 'active',
            },
          ],
        ),
      );

      final caregivers = await repo.listPatientCaregivers('patient-1');
      expect(caregivers, hasLength(1));
      expect(caregivers.first.caregiverId, 'caregiver-1');
      expect(caregivers.first.displayName, 'أحمد');
    });

    test('rethrows 401 error', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>('/caregiver/pairing-code'),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/caregiver/pairing-code'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/caregiver/pairing-code'),
          ),
          error: ApiException(message: 'غير مصرح', statusCode: 401),
        ),
      );

      expect(
        repo.generatePairingCode,
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('CaregiverRepository Supabase Fallback', () {
    test('generatePairingCode inserts or updates pending code in caregiver_links',
        () async {
      when(
        () => mockDio.post<Map<String, dynamic>>('/caregiver/pairing-code'),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/caregiver/pairing-code'),
          type: DioExceptionType.connectionError,
        ),
      );

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      when(() => mockSupabase.from('caregiver_links'))
          .thenAnswer((_) => mockQueryBuilder);

      when(() => mockQueryBuilder.select('id')).thenAnswer(
        (_) => FakePostgrestFilterBuilder(singleValue: null),
      );
      when(() => mockQueryBuilder.insert(any())).thenAnswer(
        (_) => FakePostgrestFilterBuilder(),
      );

      final result = await repo.generatePairingCode();
      expect(result.code, hasLength(6));
      expect(result.expiresAt.isAfter(DateTime.now()), isTrue);
    });

    test('pairWithPatient updates caregiver_links and returns linked patient via Supabase',
        () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/caregiver/pair',
          data: {'code': '654321'},
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/caregiver/pair'),
          type: DioExceptionType.connectionError,
        ),
      );

      final mockQueryBuilderLinks = MockSupabaseQueryBuilder();
      final mockQueryBuilderUsers = MockSupabaseQueryBuilder();

      when(() => mockSupabase.from('caregiver_links'))
          .thenAnswer((_) => mockQueryBuilderLinks);
      when(() => mockSupabase.from('users'))
          .thenAnswer((_) => mockQueryBuilderUsers);

      final futureExpiry = DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 5))
          .toIso8601String();

      when(mockQueryBuilderLinks.select).thenAnswer(
        (_) => FakePostgrestFilterBuilder(
          singleValue: {
            'id': 'link-id-1',
            'patient_id': 'other-patient-id',
            'pairing_code': '654321',
            'pairing_code_expires_at': futureExpiry,
            'status': 'pending',
          },
        ),
      );

      when(() => mockQueryBuilderLinks.update(any())).thenAnswer(
        (_) => FakePostgrestFilterBuilder(),
      );

      when(() => mockQueryBuilderUsers.select('name, phone')).thenAnswer(
        (_) => FakePostgrestFilterBuilder(
          singleValue: {'name': 'الحاج محمد', 'phone': '01000000000'},
        ),
      );

      final patient = await repo.pairWithPatient('654321');

      expect(patient.patientId, 'other-patient-id');
      expect(patient.name, 'الحاج محمد');
      expect(patient.phone, '01000000000');
      expect(patient.status, 'active');
    });

    test('listLinkedPatients joins patients from users table via Supabase',
        () async {
      when(() => mockDio.get<List<dynamic>>('/caregiver/patients')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/caregiver/patients'),
          type: DioExceptionType.connectionError,
        ),
      );

      final mockQueryBuilderLinks = MockSupabaseQueryBuilder();
      final mockQueryBuilderUsers = MockSupabaseQueryBuilder();

      when(() => mockSupabase.from('caregiver_links'))
          .thenAnswer((_) => mockQueryBuilderLinks);
      when(() => mockSupabase.from('users'))
          .thenAnswer((_) => mockQueryBuilderUsers);

      when(mockQueryBuilderLinks.select).thenAnswer(
        (_) => FakePostgrestFilterBuilder(
          listValue: [
            {
              'id': 'link-101',
              'patient_id': 'patient-101',
              'caregiver_id': 'current-user-id',
              'status': 'active',
              'linked_at': '2026-10-25T10:00:00Z',
            },
          ],
        ),
      );

      when(() => mockQueryBuilderUsers.select('id, name, phone')).thenAnswer(
        (_) => FakePostgrestFilterBuilder(
          listValue: [
            {
              'id': 'patient-101',
              'name': 'فاطمة',
              'phone': '01222222222',
            },
          ],
        ),
      );

      final patients = await repo.listLinkedPatients();
      expect(patients, hasLength(1));
      expect(patients.first.patientId, 'patient-101');
      expect(patients.first.name, 'فاطمة');
      expect(patients.first.phone, '01222222222');
    });
  });
}
