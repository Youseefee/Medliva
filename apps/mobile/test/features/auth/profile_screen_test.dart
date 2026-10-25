import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/core/storage/token_storage.dart';
import 'package:medliva/features/auth/data/auth_repository.dart';
import 'package:medliva/features/auth/domain/models/user.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/main.dart';
import 'package:mocktail/mocktail.dart';

class MockTokenStorage extends Mock implements TokenStorage;

class MockAuthRepository extends Mock implements AuthRepository;

class MockMedicationRepository extends Mock implements MedicationRepository;

void main() {
  late MockTokenStorage tokenStorage;
  late MockAuthRepository authRepository;
  late MockMedicationRepository medicationRepository;

  setUp(() {
    tokenStorage = MockTokenStorage();
    authRepository = MockAuthRepository();
    medicationRepository = MockMedicationRepository();
    when(() => medicationRepository.getTodayDoses(any()))
        .thenAnswer((_) async => const []);
  });

  testWidgets('ProfileScreen updates name and language, switching app locale',
      (tester) async {
    when(() => tokenStorage.getAccessToken())
        .thenAnswer((_) async => 'valid_token');
    when(() => authRepository.getMe()).thenAnswer(
      (_) async => const UserModel(
        id: 'patient-1',
        phone: '+201012345678',
        role: 'patient',
        name: 'عم أحمد',
        language: 'ar',
      ),
    );
    when(
      () => authRepository.updateMe(
        name: any(named: 'name'),
        language: 'en',
      ),
    ).thenAnswer(
      (_) async => const UserModel(
        id: 'patient-1',
        phone: '+201012345678',
        role: 'patient',
        name: 'عم أحمد',
        language: 'en',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
        authRepositoryProvider.overrideWithValue(authRepository),
        medicationRepositoryProvider.overrideWithValue(medicationRepository),
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

    // Navigate to profile screen
    await tester.tap(find.byKey(const ValueKey('open_profile_button')));
    await tester.pumpAndSettle();

    // Verify Arabic titles initially
    expect(find.text('الملف الشخصي'), findsOneWidget);
    expect(find.text('حفظ التغييرات'), findsOneWidget);

    // Switch language to English
    await tester.tap(find.byKey(const ValueKey('lang_en_button')));
    await tester.pumpAndSettle();

    // Verify app locale switched to English
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    verify(
      () => authRepository.updateMe(
        name: 'عم أحمد',
        language: 'en',
      ),
    ).called(1);
  });
}
