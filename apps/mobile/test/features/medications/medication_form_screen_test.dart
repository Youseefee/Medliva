import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/medication_form_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockMedicationRepository extends Mock implements MedicationRepository;

void main() {
  late MockMedicationRepository repository;

  setUpAll(() {
    registerFallbackValue(const MedicationCreateInput(name: 'fallback'));
  });

  setUp(() {
    repository = MockMedicationRepository();
  });

  testWidgets('MedicationFormScreen shows validation error on empty name and submits valid form',
      (tester) async {
    when(() => repository.listMedications('patient-1'))
        .thenAnswer((_) async => const []);
    when(
      () => repository.createMedication('patient-1', any()),
    ).thenAnswer(
      (_) async => const MedicationModel(
        id: 'med-new',
        patientId: 'patient-1',
        name: 'Concor',
        strength: '5mg',
        stockCount: 30,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentPatientIdProvider.overrideWithValue('patient-1'),
          medicationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MedicationFormScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Submit empty form -> should show error and not call repository
    await tester.tap(find.byKey(const ValueKey('submit_medication_form_btn')));
    await tester.pumpAndSettle();

    expect(find.text('يرجى إدخال اسم الدواء'), findsOneWidget);
    verifyNever(() => repository.createMedication(any(), any()));

    // Enter valid name & strength and submit
    await tester.enterText(
      find.byKey(const ValueKey('med_name_field')),
      'Concor',
    );
    await tester.enterText(
      find.byKey(const ValueKey('med_strength_field')),
      '5mg',
    );
    await tester.tap(find.byKey(const ValueKey('submit_medication_form_btn')));
    await tester.pumpAndSettle();

    verify(() => repository.createMedication('patient-1', any())).called(1);
  });
}
