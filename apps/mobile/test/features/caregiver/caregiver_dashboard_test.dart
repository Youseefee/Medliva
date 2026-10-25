import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/auth/domain/models/user.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/caregiver/data/caregiver_repository.dart';
import 'package:medliva/features/caregiver/domain/models/caregiver.dart';
import 'package:medliva/features/caregiver/presentation/screens/caregiver_dashboard_screen.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockCaregiverRepository extends Mock implements CaregiverRepository;

class MockMedicationRepository extends Mock implements MedicationRepository;

class _FakeCaregiverAuthNotifier extends AuthNotifier {
  @override
  Future<UserModel?> build() async => const UserModel(
        id: 'caregiver-1',
        phone: '+201088882222',
        role: 'caregiver',
        name: 'سارة',
      );
}

void main() {
  late MockCaregiverRepository caregiverRepository;
  late MockMedicationRepository medicationRepository;

  setUp(() {
    caregiverRepository = MockCaregiverRepository();
    medicationRepository = MockMedicationRepository();
  });

  testWidgets(
      'CaregiverDashboardScreen renders patients with counts and opens read-only Today on tap',
      (tester) async {
    when(() => caregiverRepository.listLinkedPatients()).thenAnswer(
      (_) async => const [
        LinkedPatientModel(
          patientId: 'patient-99',
          phone: '+201099991111',
          name: 'عم أحمد',
          status: 'active',
          todayTakenCount: 2,
          todayMissedCount: 1,
          activeAlertsCount: 1,
        ),
      ],
    );

    when(() => medicationRepository.getTodayDoses('patient-99')).thenAnswer(
      (_) async => const [
        TodayDoseModel(
          scheduleId: 'sched-1',
          medicationId: 'med-1',
          medicationName: 'Concor 5mg',
          timeOfDay: '08:00',
          doseAmount: 1,
          mealRelation: 'after_meal',
          status: 'pending',
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(_FakeCaregiverAuthNotifier.new),
        caregiverRepositoryProvider.overrideWithValue(caregiverRepository),
        medicationRepositoryProvider.overrideWithValue(medicationRepository),
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
          home: Scaffold(body: CaregiverDashboardScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('عم أحمد'), findsOneWidget);
    expect(find.text('تم تناول 2 • فائتة 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('alert_badge_patient-99')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('patient_card_patient-99')));
    await tester.pumpAndSettle();

    expect(container.read(currentPatientIdProvider), 'patient-99');
    expect(find.text('Concor 5mg'), findsOneWidget);
    // Read-only TodayScreen does not show Taken/Skip buttons
    expect(find.byKey(const ValueKey('take_btn_sched-1')), findsNothing);
  });
}
