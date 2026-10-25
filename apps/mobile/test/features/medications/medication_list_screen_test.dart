import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/medication_list_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockMedicationRepository extends Mock implements MedicationRepository;

void main() {
  late MockMedicationRepository repository;

  setUp(() {
    repository = MockMedicationRepository();
  });

  testWidgets('MedicationListScreen renders list and deletes item after confirmation',
      (tester) async {
    when(() => repository.listMedications('patient-1')).thenAnswer(
      (_) async => const [
        MedicationModel(
          id: 'med-1',
          patientId: 'patient-1',
          name: 'Concor',
          strength: '5mg',
          stockCount: 30,
        ),
        MedicationModel(
          id: 'med-2',
          patientId: 'patient-1',
          name: 'Glucophage',
          strength: '500mg',
          stockCount: 60,
        ),
      ],
    );
    when(() => repository.deleteMedication('med-1')).thenAnswer((_) async {});

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
          home: MedicationListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Concor'), findsOneWidget);
    expect(find.text('Glucophage'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('delete_med_btn_med-1')));
    await tester.pumpAndSettle();

    expect(find.text('هل أنت متأكد من حذف هذا الدواء؟'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('confirm_delete_med_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Concor'), findsNothing);
    expect(find.text('Glucophage'), findsOneWidget);
    verify(() => repository.deleteMedication('med-1')).called(1);
  });
}
