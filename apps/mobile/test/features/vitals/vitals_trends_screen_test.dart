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

  setUp(() {
    repository = MockVitalsRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        currentPatientIdProvider.overrideWithValue('patient-1'),
        vitalsRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: VitalsTrendsScreen()),
      ),
    );
  }

  testWidgets('VitalsTrendsScreen renders the blood pressure trend card',
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
      ],
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('trend_card_bp')), findsOneWidget);
    expect(find.byKey(const ValueKey('trend_card_glucose')), findsNothing);
    expect(find.text('ضغط الدم (آخر 7 أيام)'), findsOneWidget);

    // The triage counters use the real readings.
    expect(find.text('ضمن الطبيعي'), findsOneWidget);
    expect(find.text('مرتفع قليلاً'), findsOneWidget);
    expect(find.text('مرتفع'), findsOneWidget);
  });

  testWidgets('the glucose toggle switches the rendered trend card',
      (tester) async {
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

    await tester.tap(find.byKey(const ValueKey('trend_tab_bp')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('trend_card_bp')), findsOneWidget);
    expect(find.byKey(const ValueKey('trend_card_glucose')), findsNothing);
  });

  testWidgets('no readings shows an honest empty state instead of fake values',
      (tester) async {
    when(() => repository.listVitals(any())).thenAnswer((_) async => const []);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('لا توجد قياسات مسجلة بعد'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));
  });
}
