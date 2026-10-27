import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/core/storage/token_storage.dart';
import 'package:medliva/features/auth/data/auth_repository.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/auth/presentation/screens/email_password_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockTokenStorage extends Mock implements TokenStorage;

class MockSupabaseClient extends Mock implements SupabaseClient;

class MockGoTrueClient extends Mock implements GoTrueClient;

class MockAuthRepository extends Mock implements AuthRepository;

class FakeTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  FakeTransformBuilder(this._data);

  final dynamic _data;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() =>
      FakeTransformBuilder<Map<String, dynamic>>(_oneRow(_data));

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() =>
      FakeTransformBuilder<Map<String, dynamic>?>(_optionalOneRow(_data));

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
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) => FakeTransformBuilder<List<Map<String, dynamic>>>(_rows(_data));

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() =>
      FakeTransformBuilder<Map<String, dynamic>>(_oneRow(_data));

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() =>
      FakeTransformBuilder<Map<String, dynamic>?>(_optionalOneRow(_data));

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return Future.value(_data as T).then(onValue, onError: onError);
  }
}

class FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  FakeQueryBuilder(this.rows);

  final List<Map<String, dynamic>> rows;
  final _updates = <Map<String, dynamic>>[];

  Map<String, dynamic>? get lastUpdate =>
      _updates.isEmpty ? null : _updates.last;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) => FakeFilterBuilder<List<Map<String, dynamic>>>(rows);

  @override
  PostgrestFilterBuilder<dynamic> update(
    Map<dynamic, dynamic> values, {
    bool defaultToNull = true,
  }) {
    _updates.add(Map<String, dynamic>.from(values));
    if (rows.isEmpty) return FakeFilterBuilder<dynamic>(null);
    final updated = {...rows.first, ..._updates.last};
    rows[0] = updated;
    return FakeFilterBuilder<dynamic>(updated);
  }
}

List<Map<String, dynamic>> _rows(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }
  return [Map<String, dynamic>.from(value as Map)];
}

Map<String, dynamic> _oneRow(dynamic value) {
  if (value is List) return Map<String, dynamic>.from(value.first as Map);
  return Map<String, dynamic>.from(value as Map);
}

Map<String, dynamic>? _optionalOneRow(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value.isEmpty ? null : Map<String, dynamic>.from(value.first as Map);
  }
  return Map<String, dynamic>.from(value as Map);
}

void main() {
  late MockTokenStorage mockTokenStorage;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;

  setUp(() {
    mockTokenStorage = MockTokenStorage();
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();

    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
  });

  group('AuthRepository Supabase profiles', () {
    test('getMe reads the signed-in user row from Supabase', () async {
      const authUserId = '60347df9-dc78-4518-83d4-65b5fa70df6e';
      final testAuthUser = User(
        id: authUserId,
        appMetadata: const {'provider': 'email'},
        userMetadata: const {
          'full_name': 'مستخدم تجريبي',
          'role': 'caregiver',
          'language': 'ar',
        },
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'test@example.com',
      );

      when(() => mockGoTrueClient.currentUser).thenReturn(testAuthUser);
      when(() => mockSupabaseClient.from('users')).thenAnswer(
        (_) => FakeQueryBuilder([
          {
            'id': authUserId,
            'email': 'test@example.com',
            'name': 'اسم من قاعدة البيانات',
            'role': 'caregiver',
            'language': 'en',
            'timezone': 'Africa/Cairo',
          },
        ]),
      );

      final repo = AuthRepository(
        tokenStorage: mockTokenStorage,
        supabaseClient: mockSupabaseClient,
      );

      final user = await repo.getMe(currentUser: testAuthUser);

      expect(user.id, authUserId);
      expect(user.name, 'اسم من قاعدة البيانات');
      expect(user.role, 'caregiver');
      expect(user.isCaregiver, isTrue);
      expect(user.email, 'test@example.com');
      expect(user.language, 'en');
      verify(() => mockSupabaseClient.from('users')).called(1);
    });

    test(
      'getMe falls back to auth metadata if the profile row is missing',
      () async {
        const authUserId = '60347df9-dc78-4518-83d4-65b5fa70df6e';
        final testAuthUser = User(
          id: authUserId,
          appMetadata: const {'provider': 'email'},
          userMetadata: const {
            'full_name': 'مستخدم تجريبي',
            'role': 'caregiver',
            'language': 'ar',
          },
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: 'test@example.com',
        );
        when(() => mockSupabaseClient.from('users'))
            .thenAnswer((_) => FakeQueryBuilder([]));
        final repo = AuthRepository(
          tokenStorage: mockTokenStorage,
          supabaseClient: mockSupabaseClient,
        );

        final user = await repo.getMe(currentUser: testAuthUser);

        expect(user.id, authUserId);
        expect(user.name, 'مستخدم تجريبي');
        expect(user.role, 'caregiver');
      },
    );

    test('updateMe writes profile fields to the signed-in user row', () async {
      const authUserId = '60347df9-dc78-4518-83d4-65b5fa70df6e';
      final testAuthUser = User(
        id: authUserId,
        appMetadata: const {'provider': 'email'},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'test@example.com',
      );
      final query = FakeQueryBuilder([
        {
          'id': authUserId,
          'email': 'test@example.com',
          'name': 'مستخدم تجريبي',
          'role': 'patient',
          'language': 'ar',
          'timezone': 'Africa/Cairo',
        },
      ]);
      when(() => mockGoTrueClient.currentUser).thenReturn(testAuthUser);
      when(() => mockSupabaseClient.from('users')).thenAnswer((_) => query);

      final repo = AuthRepository(
        tokenStorage: mockTokenStorage,
        supabaseClient: mockSupabaseClient,
      );

      final user = await repo.updateMe(
        name: 'مستخدم جديد',
        language: 'en',
        role: 'caregiver',
      );

      expect(user.name, 'مستخدم جديد');
      expect(user.language, 'en');
      expect(user.role, 'caregiver');
      expect(query.lastUpdate?['name'], 'مستخدم جديد');
      expect(query.lastUpdate?['language'], 'en');
      expect(query.lastUpdate?['role'], 'caregiver');
      expect(query.lastUpdate?['updated_at'], isA<String>());
      verify(() => mockSupabaseClient.from('users')).called(1);
    });

    test(
      'updateMe does not allow clients to promote themselves to admin',
      () async {
        final repo = AuthRepository(
          tokenStorage: mockTokenStorage,
          supabaseClient: mockSupabaseClient,
        );

        await expectLater(
          repo.updateMe(role: 'admin'),
          throwsA(isA<ArgumentError>()),
        );
        verifyNever(() => mockSupabaseClient.from('users'));
      },
    );
  });

  group('EmailPasswordScreen Error Mapping', () {
    testWidgets('Shows friendly message when email is already registered', (
      tester,
    ) async {
      final mockAuthRepo = MockAuthRepository();
      when(
        () => mockAuthRepo.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          name: any(named: 'name'),
          role: any(named: 'role'),
        ),
      ).thenThrow(
        const AuthException(
          'User already registered',
          statusCode: '422',
          code: 'user_already_exists',
        ),
      );

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: EmailPasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to sign up
      await tester.tap(find.text('ليس لديك حساب؟ أنشئ حساباً'));
      await tester.pumpAndSettle();

      // Enter name, email, password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'الاسم بالكامل'),
        'أحمد',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'البريد الإلكتروني'),
        'existing@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'كلمة المرور'),
        'password123',
      );
      await tester.pumpAndSettle();

      // Submit
      final submitBtn = find.widgetWithText(ElevatedButton, 'إنشاء حساب');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify friendly message
      expect(
        find.text(
          'البريد الإلكتروني مسجل مسبقاً، يرجى تسجيل الدخول بدلاً من ذلك',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Shows friendly message when login credentials are invalid', (
      tester,
    ) async {
      final mockAuthRepo = MockAuthRepository();
      when(
        () => mockAuthRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const AuthException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
      );

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: EmailPasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter email and password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'البريد الإلكتروني'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'كلمة المرور'),
        'wrongpassword',
      );
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'));
      await tester.pumpAndSettle();

      // Verify friendly message
      expect(
        find.text('البريد الإلكتروني أو كلمة المرور غير صحيحة'),
        findsOneWidget,
      );
    });
  });
}
