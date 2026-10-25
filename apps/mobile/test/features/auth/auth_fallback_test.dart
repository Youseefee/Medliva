import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/core/storage/token_storage.dart';
import 'package:medliva/features/auth/data/auth_repository.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/auth/presentation/screens/email_password_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockApiClient extends Mock implements ApiClient;

class MockDio extends Mock implements Dio;

class MockTokenStorage extends Mock implements TokenStorage;

class MockSupabaseClient extends Mock implements SupabaseClient;

class MockGoTrueClient extends Mock implements GoTrueClient;

class MockAuthRepository extends Mock implements AuthRepository;

void main() {
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late MockTokenStorage mockTokenStorage;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    mockTokenStorage = MockTokenStorage();
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();

    when(() => mockApiClient.dio).thenReturn(mockDio);
    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
  });

  group('AuthRepository Fallback', () {
    test('getMe falls back to Supabase auth user when Dio throws connection error',
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

      when(() => mockGoTrueClient.currentUser).thenReturn(testAuthUser);

      // Simulate connection error to 10.0.2.2:8000
      when(() => mockDio.get<Map<String, dynamic>>('/me')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/me'),
          type: DioExceptionType.connectionError,
          error: ApiException(message: 'تعذر الاتصال بالسيرفر'),
        ),
      );

      final repo = AuthRepository(
        apiClient: mockApiClient,
        tokenStorage: mockTokenStorage,
        supabaseClient: mockSupabaseClient,
      );

      final user = await repo.getMe(currentUser: testAuthUser);

      expect(user.id, authUserId);
      expect(user.name, 'مستخدم تجريبي');
      expect(user.role, 'caregiver');
      expect(user.isCaregiver, isTrue);
      expect(user.email, 'test@example.com');
    });

    test('getMe rethrows 401 Unauthorized so invalid session can be cleared',
        () async {
      when(() => mockDio.get<Map<String, dynamic>>('/me')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/me'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/me'),
          ),
          error: ApiException(message: 'رمز الدخول غير صالح', statusCode: 401),
        ),
      );

      final repo = AuthRepository(
        apiClient: mockApiClient,
        tokenStorage: mockTokenStorage,
        supabaseClient: mockSupabaseClient,
      );

      expect(
        repo.getMe,
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });
  });

  group('EmailPasswordScreen Error Mapping', () {
    testWidgets('Shows friendly message when email is already registered',
        (tester) async {
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
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
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
        find.text('البريد الإلكتروني مسجل مسبقاً، يرجى تسجيل الدخول بدلاً من ذلك'),
        findsOneWidget,
      );
    });

    testWidgets('Shows friendly message when login credentials are invalid',
        (tester) async {
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
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
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
