import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/emergency/data/emergency_repository.dart';
import 'package:medliva/features/emergency/domain/models/emergency.dart';
import 'package:medliva/features/emergency/presentation/widgets/sos_button_widget.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockEmergencyRepository extends Mock implements EmergencyRepository;

class MockSosLocationService extends Mock implements SosLocationService;

void main() {
  late MockEmergencyRepository repository;
  late MockSosLocationService locationService;

  setUp(() {
    repository = MockEmergencyRepository();
    locationService = MockSosLocationService();
  });

  testWidgets('SOS button ignores accidental tap and calls API after confirmed long-press',
      (tester) async {
    when(() => locationService.tryGetCoordinates())
        .thenAnswer((_) async => (lat: 30.0444, lng: 31.2357));
    when(
      () => repository.triggerSos(
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
      ),
    ).thenAnswer(
      (_) async => const SosResponseModel(
        status: 'active',
        alertId: 'alert-1',
        notifiedContactsCount: 2,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emergencyRepositoryProvider.overrideWithValue(repository),
          sosLocationServiceProvider.overrideWithValue(locationService),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: SosButtonWidget())),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Accidental quick tap -> does nothing
    await tester.tap(find.byKey(const ValueKey('sos_trigger_btn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('sos_confirm_send_btn')), findsNothing);
    verifyNever(
      () => repository.triggerSos(
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
      ),
    );

    // 2. Long press -> opens confirm dialog -> confirm calls API with coordinates
    await tester.longPress(find.byKey(const ValueKey('sos_trigger_btn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('sos_confirm_send_btn')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sos_confirm_send_btn')));
    await tester.pumpAndSettle();

    verify(() => repository.triggerSos(lat: 30.0444, lng: 31.2357)).called(1);
    expect(find.text('تم إرسال نداء الاستغاثة بنجاح'), findsOneWidget);
  });
}
