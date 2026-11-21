import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/core/router/app_router.dart';
import 'package:medliva/core/storage/token_storage.dart';
import 'package:medliva/features/auth/data/auth_repository.dart';
import 'package:medliva/features/auth/domain/models/user.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/caregiver/data/caregiver_repository.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/presentation/screens/dose_reminder_screen.dart';
import 'package:medliva/main.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockTokenStorage extends Mock implements TokenStorage;

class MockAuthRepository extends Mock implements AuthRepository;

class MockMedicationRepository extends Mock implements MedicationRepository;

class MockCaregiverRepository extends Mock implements CaregiverRepository;

void main() {
  late MockTokenStorage tokenStorage;
  late MockAuthRepository authRepository;
  late MockMedicationRepository medicationRepository;
  late MockCaregiverRepository caregiverRepository;

  setUp(() {
    tokenStorage = MockTokenStorage();
    authRepository = MockAuthRepository();
    medicationRepository = MockMedicationRepository();
    caregiverRepository = MockCaregiverRepository();
    when(() => medicationRepository.getTodayDoses(any()))
        .thenAnswer((_) async => const []);
    when(() => caregiverRepository.listLinkedPatients())
        .thenAnswer((_) async => const []);
  });

  testWidgets('Patient user lands on /patient shell and sets currentPatientIdProvider',
      (tester) async {
    when(() => tokenStorage.getAccessToken())
        .thenAnswer((_) async => 'patient_token');
    when(() => authRepository.getMe()).thenAnswer(
      (_) async => const UserModel(
        id: 'patient-123',
        phone: '+201012345678',
        role: 'patient',
        name: 'عم أحمد',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
        authRepositoryProvider.overrideWithValue(authRepository),
        medicationRepositoryProvider.overrideWithValue(medicationRepository),
        caregiverRepositoryProvider.overrideWithValue(caregiverRepository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MedlivaApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('patient_shell')), findsOneWidget);
    expect(find.text('واجهة المريض'), findsOneWidget);
    expect(container.read(currentPatientIdProvider), 'patient-123');
  });

  testWidgets('Caregiver user lands on /caregiver shell and reads selected patient id',
      (tester) async {
    when(() => tokenStorage.getAccessToken())
        .thenAnswer((_) async => 'caregiver_token');
    when(() => authRepository.getMe()).thenAnswer(
      (_) async => const UserModel(
        id: 'caregiver-456',
        phone: '+201098765432',
        role: 'caregiver',
        name: 'سارة',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
        authRepositoryProvider.overrideWithValue(authRepository),
        medicationRepositoryProvider.overrideWithValue(medicationRepository),
        caregiverRepositoryProvider.overrideWithValue(caregiverRepository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MedlivaApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('caregiver_shell')), findsOneWidget);
    expect(find.text('لوحة متابعة المرافق'), findsOneWidget);
    expect(container.read(currentPatientIdProvider), isNull);

    container.read(selectedPatientIdProvider.notifier).selectPatient('patient-123');
    expect(container.read(currentPatientIdProvider), 'patient-123');
  });

  testWidgets(
      'Invalid login with GoRouter preserves form state and shows error SnackBar',
      (tester) async {
    when(() => tokenStorage.getAccessToken()).thenAnswer((_) async => null);
    when(
      () => authRepository.signIn(
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
        tokenStorageProvider.overrideWithValue(tokenStorage),
        authRepositoryProvider.overrideWithValue(authRepository),
        medicationRepositoryProvider.overrideWithValue(medicationRepository),
        caregiverRepositoryProvider.overrideWithValue(caregiverRepository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MedlivaApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'البريد الإلكتروني'),
      'senior@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'كلمة المرور'),
      'wrongpass',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(
      find.text('البريد الإلكتروني أو كلمة المرور غير صحيحة'),
      findsOneWidget,
    );
    expect(find.text('senior@example.com'), findsOneWidget);
  });

  testWidgets('/medications/reminder resolves to DoseReminderScreen before :id',
      (tester) async {
    when(() => tokenStorage.getAccessToken())
        .thenAnswer((_) async => 'patient_token');
    when(() => authRepository.getMe()).thenAnswer(
      (_) async => const UserModel(
        id: 'patient-123',
        phone: '+201012345678',
        role: 'patient',
        name: 'عم أحمد',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
        authRepositoryProvider.overrideWithValue(authRepository),
        medicationRepositoryProvider.overrideWithValue(medicationRepository),
        caregiverRepositoryProvider.overrideWithValue(caregiverRepository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MedlivaApp(),
      ),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/medications/reminder');
    await tester.pumpAndSettle();

    expect(find.byType(DoseReminderScreen), findsOneWidget);
  });
}
