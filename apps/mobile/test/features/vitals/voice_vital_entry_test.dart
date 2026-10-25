import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/vitals/data/vitals_repository.dart';
import 'package:medliva/features/vitals/domain/models/vital.dart';
import 'package:medliva/features/vitals/presentation/screens/vitals_screen.dart';
import 'package:medliva/features/vitals/presentation/screens/voice_vital_entry.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockVitalsRepository extends Mock implements VitalsRepository;

class MockSpeechCaptureService extends Mock implements SpeechCaptureService;

void main() {
  late MockVitalsRepository repository;
  late MockSpeechCaptureService speechService;

  setUpAll(() {
    registerFallbackValue(
      const VitalCreateInput(type: 'bp', valuePrimary: 135),
    );
  });

  setUp(() {
    repository = MockVitalsRepository();
    speechService = MockSpeechCaptureService();
  });

  testWidgets(
      'Voice entry shows editable confirm screen and saves nothing unless confirmed',
      (tester) async {
    when(() => repository.listVitals('patient-1'))
        .thenAnswer((_) async => const []);
    when(
      () => speechService.captureTranscript(
        localeId: any(named: 'localeId'),
      ),
    ).thenAnswer((_) async => 'الضغط النهارده 135 على 85');

    when(
      () => repository.parseVoiceVitals('الضغط النهارده 135 على 85'),
    ).thenAnswer(
      (_) async => const VoiceVitalsParseResult(
        transcript: 'الضغط النهارده 135 على 85',
        type: 'bp',
        valuePrimary: 135,
        valueSecondary: 85,
        band: 'borderline',
        messageAr: 'الضغط مرتفع قليلاً',
      ),
    );

    when(() => repository.createVital('patient-1', any())).thenAnswer(
      (_) async => VitalReadingModel(
        id: 'vital-voice-1',
        patientId: 'patient-1',
        type: 'bp',
        valuePrimary: 140,
        valueSecondary: 85,
        band: 'borderline',
        recordedAt: DateTime.utc(2026, 10, 23, 13),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentPatientIdProvider.overrideWithValue('patient-1'),
          vitalsRepositoryProvider.overrideWithValue(repository),
          speechCaptureServiceProvider.overrideWithValue(speechService),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VitalsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Tap voice entry -> shows confirm dialog; nothing saved yet
    await tester.tap(find.byKey(const ValueKey('voice_vital_btn')));
    await tester.pumpAndSettle();

    expect(find.text('تأكيد القراءة الصوتية'), findsOneWidget);
    expect(find.text('الضغط النهارده 135 على 85'), findsOneWidget);
    verifyNever(() => repository.createVital(any(), any()));

    // 2. Tap cancel -> dialog closes and nothing is saved
    await tester.tap(find.byKey(const ValueKey('voice_confirm_cancel_btn')));
    await tester.pumpAndSettle();

    verifyNever(() => repository.createVital(any(), any()));

    // 3. Tap voice entry again -> edit primary value -> confirm -> saves
    await tester.tap(find.byKey(const ValueKey('voice_vital_btn')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('voice_confirm_primary_field')),
      '140',
    );
    await tester.tap(find.byKey(const ValueKey('voice_confirm_save_btn')));
    await tester.pumpAndSettle();

    verify(() => repository.createVital('patient-1', any())).called(1);
    expect(find.byKey(const ValueKey('vital_card_vital-voice-1')), findsOneWidget);
  });
}
