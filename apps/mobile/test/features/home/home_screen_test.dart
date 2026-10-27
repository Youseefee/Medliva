import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/auth/domain/models/user.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/caregiver/data/caregiver_repository.dart';
import 'package:medliva/features/home/presentation/screens/home_screen.dart';
import 'package:medliva/features/inventory/data/inventory_repository.dart';
import 'package:medliva/features/medications/data/medication_reminder_planner.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/notifications/data/alerts_repository.dart';
import 'package:medliva/features/vitals/data/vitals_repository.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockMedicationRepository extends Mock implements MedicationRepository;

class MockCaregiverRepository extends Mock implements CaregiverRepository;

class MockInventoryRepository extends Mock implements InventoryRepository;

class MockVitalsRepository extends Mock implements VitalsRepository;

class MockAlertsRepository extends Mock implements AlertsRepository;

class _FakePatientAuthNotifier extends AuthNotifier {
  @override
  Future<UserModel?> build() async => const UserModel(
    id: 'patient-test-1',
    name: 'عم أحمد',
    email: 'ahmed@test.com',
    role: 'patient',
    language: 'ar',
  );
}

class _FakeCaregiverAuthNotifier extends AuthNotifier {
  @override
  Future<UserModel?> build() async => const UserModel(
    id: 'caregiver-test-1',
    name: 'سارة',
    email: 'sara@test.com',
    role: 'caregiver',
    language: 'ar',
  );
}

class _PreselectedPatientNotifier extends SelectedPatientIdNotifier {
  @override
  String? build() => 'patient-test-1';
}

void main() {
  late MockMedicationRepository medicationRepository;
  late MockCaregiverRepository caregiverRepository;
  late MockInventoryRepository inventoryRepository;
  late MockVitalsRepository vitalsRepository;
  late MockAlertsRepository alertsRepository;

  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  setUp(() {
    medicationRepository = MockMedicationRepository();
    caregiverRepository = MockCaregiverRepository();
    inventoryRepository = MockInventoryRepository();
    vitalsRepository = MockVitalsRepository();
    alertsRepository = MockAlertsRepository();

    when(() => medicationRepository.getTodayDoses(any())).thenAnswer(
      (_) async => const [
        TodayDoseModel(
          scheduleId: 'sched-1',
          medicationId: 'med-1',
          medicationName: 'Amlodipine 5mg',
          timeOfDay: '08:00',
          doseAmount: 1,
          mealRelation: 'after_meal',
          status: 'pending',
        ),
      ],
    );
    when(() => medicationRepository.listMedications(any()))
        .thenAnswer((_) async => const []);
    when(() => caregiverRepository.listLinkedPatients())
        .thenAnswer((_) async => const []);
    when(() => caregiverRepository.listPatientCaregivers(any()))
        .thenAnswer((_) async => const []);
    when(() => inventoryRepository.getForecast(any()))
        .thenAnswer((_) async => const []);
    when(() => vitalsRepository.listVitals(any()))
        .thenAnswer((_) async => const []);
    when(() => alertsRepository.listAlerts(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => const []);
  });

  Widget buildPatientShellApp() {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_FakePatientAuthNotifier.new),
        medicationRepositoryProvider.overrideWithValue(medicationRepository),
        caregiverRepositoryProvider.overrideWithValue(caregiverRepository),
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        vitalsRepositoryProvider.overrideWithValue(vitalsRepository),
        alertsRepositoryProvider.overrideWithValue(alertsRepository),
        localReminderServiceProvider.overrideWithValue(LocalReminderService()),
      ],
      child: const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(key: ValueKey('patient_shell')),
      ),
    );
  }

  Widget buildCaregiverShellApp() {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_FakeCaregiverAuthNotifier.new),
        selectedPatientIdProvider.overrideWith(_PreselectedPatientNotifier.new),
        medicationRepositoryProvider.overrideWithValue(medicationRepository),
        caregiverRepositoryProvider.overrideWithValue(caregiverRepository),
        inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
        vitalsRepositoryProvider.overrideWithValue(vitalsRepository),
        alertsRepositoryProvider.overrideWithValue(alertsRepository),
        localReminderServiceProvider.overrideWithValue(LocalReminderService()),
      ],
      child: const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(key: ValueKey('caregiver_shell')),
      ),
    );
  }

  testWidgets('HomeScreen renders patient shell and navigates across tabs', (
    tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(buildPatientShellApp());
    await tester.pumpAndSettle();

    // 1. Verify Patient Shell title and greeting card
    expect(find.text('واجهة المريض'), findsOneWidget);
    expect(find.textContaining('صباح الخير'), findsOneWidget);
    expect(find.textContaining('عم أحمد'), findsOneWidget);

    // 2. Bottom navigation bar has 4 patient destinations
    expect(find.byKey(const ValueKey('main_bottom_nav')), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('الأدوية'), findsOneWidget);
    expect(find.text('القياسات'), findsOneWidget);
    expect(find.text('المزيد'), findsOneWidget);

    // 3. Switch to Tab 1 (Medications)
    await tester.tap(find.text('الأدوية'));
    await tester.pumpAndSettle();
    expect(find.text('قائمة الأدوية'), findsOneWidget);

    // 4. Switch to Tab 2 (Vitals)
    await tester.tap(find.text('القياسات'));
    await tester.pumpAndSettle();
    expect(find.text('القياسات الحيوية'), findsOneWidget);

    // 5. Switch to Tab 3 (More Hub)
    await tester.tap(find.text('المزيد'));
    await tester.pumpAndSettle();
    expect(find.text('مسح الروشتة'), findsOneWidget);
    expect(find.text('المخزون والتواصل'), findsOneWidget);
    expect(find.text('تقرير الطبيب (PDF)'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);

    // 6. Switch back to Home Tab
    await tester.tap(find.text('الرئيسية'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('open_dose_reminder_card')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('sos_trigger_btn')), findsOneWidget);
  });

  testWidgets(
    'HomeScreen renders caregiver shell with action buttons and tabs',
    (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(buildCaregiverShellApp());
      await tester.pumpAndSettle();

      // 1. Verify Caregiver Shell title and greeting
      expect(find.text('لوحة متابعة المرافق'), findsOneWidget);
      expect(find.textContaining('سارة'), findsOneWidget);

      // 2. Action buttons (Link patient / Doctor report)
      expect(find.text('ربط حساب مريض'), findsOneWidget);
      expect(find.text('تقرير الطبيب (PDF)'), findsOneWidget);

      // 3. Bottom nav destinations for Caregiver
      expect(find.text('الرئيسية'), findsOneWidget);
      expect(find.text('الجدول الزمني'), findsOneWidget);
      expect(find.text('القياسات'), findsOneWidget);
      expect(find.text('المخزون والتواصل'), findsOneWidget);

      // 4. Switch to Timeline tab
      await tester.tap(find.text('الجدول الزمني'));
      await tester.pumpAndSettle();
      expect(find.text('Amlodipine 5mg'), findsOneWidget);

      // 5. Switch to Trends tab
      await tester.tap(find.text('القياسات'));
      await tester.pumpAndSettle();
      expect(find.text('اتجاهات القياسات'), findsOneWidget);

      // 6. Switch to Inventory tab
      await tester.tap(find.text('المخزون والتواصل'));
      await tester.pumpAndSettle();
      expect(find.text('المخزون الحالي'), findsOneWidget);
    },
  );

  testWidgets(
    'empty patient data does not show sample medication or adherence',
    (tester) async {
      useTallSurface(tester);
      when(() => medicationRepository.getTodayDoses(any()))
          .thenAnswer((_) async => const []);

      await tester.pumpWidget(buildPatientShellApp());
      await tester.pumpAndSettle();

      expect(find.text('لا توجد جرعات مجدولة لليوم'), findsWidgets);
      expect(find.text('لا توجد جرعة معلّقة الآن'), findsOneWidget);
      expect(find.text('Amlodipine 5mg'), findsNothing);
      expect(find.text('أملوديبين 5 مجم'), findsNothing);
      expect(find.text('6 من 7 جرعات'), findsNothing);
      expect(find.text('85%'), findsNothing);
    },
  );
}
