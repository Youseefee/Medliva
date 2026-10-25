import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/reports/data/reports_repository.dart';
import 'package:medliva/features/reports/domain/models/report_summary.dart';
import 'package:medliva/features/reports/presentation/screens/doctor_report_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockReportsRepository extends Mock implements ReportsRepository;

void main() {
  const sampleSummary = ReportSummaryModel(
    patientId: 'patient-1',
    patientName: 'عم أحمد',
    patientPhone: '+201012345678',
    fromDate: '2026-09-23',
    toDate: '2026-10-23',
    adherenceRatePct: 90,
    totalDoses: 10,
    takenDoses: 9,
    skippedDoses: 0,
    missedDosesCount: 1,
    activeMedications: [
      {
        'name': 'Concor 5mg',
        'strength': '5mg',
        'dose_form': 'Tablet',
        'times': ['08:00'],
      },
    ],
    adherenceHistory: [
      {
        'medication_name': 'Concor 5mg',
        'scheduled_time': '2026-10-23T08:00:00Z',
        'actual_time': '2026-10-23T08:03:00Z',
        'status': 'taken',
      },
    ],
    vitalsHistory: [
      {
        'type': 'bp',
        'value_primary': 185,
        'value_secondary': 115,
        'band': 'critical',
        'recorded_at': '2026-10-23T10:00:00Z',
      },
    ],
  );

  test('DoctorReportPdfBuilder builds PDF bytes from sample data without error',
      () async {
    const builder = DoctorReportPdfBuilder();
    final bytes = await builder.buildPdf(
      summary: sampleSummary,
    );

    expect(bytes, isNotEmpty);
    // Verify PDF magic header "%PDF"
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  testWidgets('DoctorReportScreen opens and displays report summary',
      (tester) async {
    final repository = MockReportsRepository();
    when(
      () => repository.getReportSummary(patientId: 'patient-1'),
    ).thenAnswer((_) async => sampleSummary);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentPatientIdProvider.overrideWithValue('patient-1'),
          reportsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DoctorReportScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('تقرير الطبيب (PDF)'), findsOneWidget);
    expect(find.text('عم أحمد'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('report_adherence_summary')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('share_pdf_report_btn')), findsOneWidget);
  });

  testWidgets('the range selector reloads the summary for 7 and 90 days',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MockReportsRepository();
    var callCount = 0;
    when(
      () => repository.getReportSummary(patientId: 'patient-1'),
    ).thenAnswer((_) async {
      callCount++;
      return sampleSummary;
    });
    when(
      () => repository.getReportSummary(
        patientId: 'patient-1',
        fromDate: any(named: 'fromDate'),
        toDate: any(named: 'toDate'),
      ),
    ).thenAnswer((_) async {
      callCount++;
      return sampleSummary;
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentPatientIdProvider.overrideWithValue('patient-1'),
          reportsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DoctorReportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The default range (30 days) loads the summary once.
    expect(callCount, 1);

    await tester.tap(find.byKey(const ValueKey('report_range_7d')));
    await tester.pumpAndSettle();
    expect(callCount, 2);

    await tester.tap(find.byKey(const ValueKey('report_range_90d')));
    await tester.pumpAndSettle();
    expect(callCount, 3);

    // The 90 day window starts clearly earlier than the 7 day one.
    final captured = verify(
      () => repository.getReportSummary(
        patientId: 'patient-1',
        fromDate: captureAny(named: 'fromDate'),
        toDate: captureAny(named: 'toDate'),
      ),
    ).captured;
    final dates = captured.whereType<String>().toList();
    expect(dates, hasLength(4));

    final from7 = DateTime.parse(dates[0]);
    final from90 = DateTime.parse(dates[2]);
    expect(from7.difference(from90).inDays, closeTo(83, 1));
  });

  testWidgets('generate_share_link_btn requests a link and shows the URL',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MockReportsRepository();
    when(
      () => repository.getReportSummary(patientId: 'patient-1'),
    ).thenAnswer((_) async => sampleSummary);
    when(
      () => repository.createReportShare(patientId: 'patient-1'),
    ).thenAnswer(
      (_) async => (
        token: 'tok-123',
        url: 'https://medliva.app/r/tok-123',
        expiresAt: DateTime.utc(2026, 10, 24),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentPatientIdProvider.overrideWithValue('patient-1'),
          reportsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DoctorReportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('generate_share_link_btn')));
    await tester.pumpAndSettle();

    verify(() => repository.createReportShare(patientId: 'patient-1')).called(1);
    expect(
      find.textContaining('https://medliva.app/r/tok-123'),
      findsWidgets,
    );
  });
}
