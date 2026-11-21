import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/vitals/data/vitals_repository.dart';
import 'package:medliva/features/vitals/domain/models/vital.dart';
import 'package:medliva/features/vitals/presentation/screens/vitals_trends_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockVitalsRepository extends Mock implements VitalsRepository;

void main() {
  late MockVitalsRepository repository;
  final referenceDate = DateTime.utc(2026, 10, 23, 12);

  setUp(() {
    repository = MockVitalsRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        currentPatientIdProvider.overrideWithValue('patient-1'),
        vitalsRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: VitalsTrendsScreen(referenceDate: referenceDate),
        ),
      ),
    );
  }

  testWidgets(
    'VitalsTrendsScreen renders the blood pressure trend card and filters to last 7 days',
    (tester) async {
      when(() => repository.listVitals(any())).thenAnswer(
        (_) async => [
          VitalReadingModel(
            id: 'v1',
            patientId: 'patient-1',
            type: 'bp',
            valuePrimary: 120,
            valueSecondary: 80,
            band: 'normal',
            recordedAt: DateTime.utc(2026, 10, 20),
          ),
          VitalReadingModel(
            id: 'v2',
            patientId: 'patient-1',
            type: 'bp',
            valuePrimary: 135,
            valueSecondary: 85,
            band: 'borderline',
            recordedAt: DateTime.utc(2026, 10, 21),
          ),
          VitalReadingModel(
            id: 'v3',
            patientId: 'patient-1',
            type: 'bp',
            valuePrimary: 158,
            valueSecondary: 96,
            band: 'critical',
            recordedAt: DateTime.utc(2026, 10, 22),
          ),
          // Older than 7 days — must be excluded from 7-day counts.
          VitalReadingModel(
            id: 'v-old',
            patientId: 'patient-1',
            type: 'bp',
            valuePrimary: 190,
            valueSecondary: 120,
            band: 'critical',
            recordedAt: DateTime.utc(2026, 10, 1),
          ),
        ],
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('trend_card_bp')), findsOneWidget);
      expect(find.byKey(const ValueKey('trend_card_glucose')), findsNothing);
      expect(find.text('ضغط الدم (آخر 7 أيام)'), findsOneWidget);

      // The triage counters use only the last-7-days readings (1 normal, 1 borderline, 1 critical).
      expect(find.text('ضمن الطبيعي'), findsOneWidget);
      expect(find.text('مرتفع قليلاً'), findsOneWidget);
      expect(find.text('مرتفع'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(3));
    },
  );

  testWidgets('glucose and pulse toggles switch the rendered trend card', (
    tester,
  ) async {
    when(() => repository.listVitals(any())).thenAnswer(
      (_) async => [
        VitalReadingModel(
          id: 'v1',
          patientId: 'patient-1',
          type: 'glucose',
          valuePrimary: 110,
          band: 'normal',
          recordedAt: DateTime.utc(2026, 10, 21),
        ),
        VitalReadingModel(
          id: 'v2',
          patientId: 'patient-1',
          type: 'glucose',
          valuePrimary: 190,
          band: 'critical',
          recordedAt: DateTime.utc(2026, 10, 22),
        ),
        VitalReadingModel(
          id: 'v3',
          patientId: 'patient-1',
          type: 'pulse',
          valuePrimary: 76,
          band: 'normal',
          recordedAt: DateTime.utc(2026, 10, 22),
        ),
      ],
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('trend_card_bp')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('trend_tab_glucose')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('trend_card_glucose')), findsOneWidget);
    expect(find.byKey(const ValueKey('trend_card_bp')), findsNothing);
    expect(find.text('سكر الدم (آخر 7 أيام)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('trend_tab_pulse')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('trend_card_pulse')), findsOneWidget);
    expect(find.byKey(const ValueKey('trend_card_glucose')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('trend_tab_bp')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('trend_card_bp')), findsOneWidget);
    expect(find.byKey(const ValueKey('trend_card_pulse')), findsNothing);
  });

  testWidgets('no readings shows an honest empty state instead of fake values',
      (tester) async {
    when(() => repository.listVitals(any())).thenAnswer((_) async => const []);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('لا توجد قياسات مسجلة بعد'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));
  });

  testWidgets('shows error state with retry button when loading fails', (
    tester,
  ) async {
    when(() => repository.listVitals(any())).thenThrow(Exception('Offline'));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Offline'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
