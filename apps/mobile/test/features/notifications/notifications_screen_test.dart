import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/caregiver/data/caregiver_repository.dart';
import 'package:medliva/features/caregiver/domain/models/caregiver.dart';
import 'package:medliva/features/inventory/data/inventory_repository.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/notifications/data/alerts_repository.dart';
import 'package:medliva/features/notifications/domain/models/alert.dart';
import 'package:medliva/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:medliva/features/vitals/data/vitals_repository.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockAlertsRepository extends Mock implements AlertsRepository;

class MockMedicationRepository extends Mock implements MedicationRepository;

class MockCaregiverRepository extends Mock implements CaregiverRepository;

class MockInventoryRepository extends Mock implements InventoryRepository;

class MockVitalsRepository extends Mock implements VitalsRepository;

void main() {
  late MockAlertsRepository alertsRepository;
  late MockMedicationRepository medicationRepository;
  late MockCaregiverRepository caregiverRepository;
  late MockInventoryRepository inventoryRepository;
  late MockVitalsRepository vitalsRepository;

  final now = DateTime.now();

  final alerts = [
    AlertModel(
      id: 'alert-sos',
      patientId: 'patient-1',
      type: 'sos',
      tier: 3,
      payload: {'note': 'دوران مفاجئ'},
      sentAt: now.subtract(const Duration(minutes: 5)),
      createdAt: now.subtract(const Duration(minutes: 5)),
    ),
    AlertModel(
      id: 'alert-stock',
      patientId: 'patient-1',
      type: 'low_stock',
      tier: 1,
      payload: {'medication_name': 'Concor 5mg'},
      sentAt: now.subtract(const Duration(hours: 2)),
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
  ];

  setUp(() {
    alertsRepository = MockAlertsRepository();
    medicationRepository = MockMedicationRepository();
    caregiverRepository = MockCaregiverRepository();
    inventoryRepository = MockInventoryRepository();
    vitalsRepository = MockVitalsRepository();

    when(() => alertsRepository.listAlerts(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => alerts);
    when(() => medicationRepository.getTodayDoses(any()))
        .thenAnswer((_) async => const []);
    when(() => caregiverRepository.listPatientCaregivers(any())).thenAnswer(
      (_) async => const [
        LinkedCaregiverModel(
          caregiverId: 'cg-1',
          name: 'سارة',
          phone: '+201000000000',
          status: 'active',
        ),
      ],
    );
    when(() => inventoryRepository.getForecast(any())).thenAnswer(
      (_) async => const [],
    );
    when(() => vitalsRepository.listVitals(any())).thenAnswer(
      (_) async => const [],
    );
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        currentPatientIdProvider.overrideWithValue('patient-1'),
        alertsRepositoryProvider.overrideWithValue(alertsRepository),
        medicationRepositoryProvider.overrideWithValue(medicationRepository),
        caregiverRepositoryProvider.overrideWithValue(caregiverRepository),
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        vitalsRepositoryProvider.overrideWithValue(vitalsRepository),
      ],
      child: const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: NotificationsScreen()),
      ),
    );
  }

  testWidgets('NotificationsScreen shows the alerts returned by the API',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('نداء استغاثة'), findsOneWidget);
    expect(find.text('انخفاض كمية الدواء'), findsOneWidget);
    expect(find.textContaining('دوران مفاجئ'), findsOneWidget);
  });

  testWidgets('filter chips split the notifications by category', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // All: two alerts + the caregivers card.
    expect(find.byKey(const ValueKey('notif_card_alert_alert-sos')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('notif_card_alert_alert-stock')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('notif_card_caregivers')), findsOneWidget);

    // Medications: only the low stock alert.
    await tester.tap(find.byKey(const ValueKey('notif_filter_medications')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('notif_card_alert_alert-stock')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('notif_card_alert_alert-sos')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('notif_card_caregivers')), findsNothing);

    // Caregivers: only the caregivers card.
    await tester.tap(find.byKey(const ValueKey('notif_filter_caregivers')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notif_card_caregivers')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('notif_card_alert_alert-sos')),
      findsNothing,
    );

    // Alerts: only the SOS alert.
    await tester.tap(find.byKey(const ValueKey('notif_filter_alerts')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('notif_card_alert_alert-sos')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('notif_card_alert_alert-stock')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('notif_card_caregivers')), findsNothing);

    // Back to all.
    await tester.tap(find.byKey(const ValueKey('notif_filter_all')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('notif_card_alert_alert-sos')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('notif_card_caregivers')), findsOneWidget);
  });

  testWidgets('an empty feed shows the empty state instead of fake cards',
      (tester) async {
    when(() => alertsRepository.listAlerts(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => const []);
    when(() => caregiverRepository.listPatientCaregivers(any()))
        .thenAnswer((_) async => const []);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('لا توجد إشعارات'), findsOneWidget);
    expect(find.byKey(const ValueKey('notif_card_alert_alert-sos')), findsNothing);
  });
}
