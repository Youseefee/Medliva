import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/emergency/data/emergency_repository.dart';
import 'package:medliva/features/emergency/domain/models/emergency.dart';
import 'package:medliva/features/emergency/presentation/screens/sos_emergency_screen.dart';
import 'package:medliva/features/emergency/presentation/widgets/sos_button_widget.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockEmergencyRepository extends Mock implements EmergencyRepository;

class FakeLocationService implements SosLocationService {
  @override
  Future<({double lat, double lng})?> tryGetCoordinates() async {
    return (lat: 30.0444, lng: 31.2357);
  }
}

void main() {
  late MockEmergencyRepository repository;

  const contact = EmergencyContactModel(
    id: 'c-1',
    patientId: 'patient-1',
    name: 'سارة - الابنة',
    phone: '+201000000001',
    relationship: 'daughter',
    isPrimary: true,
  );

  setUp(() {
    repository = MockEmergencyRepository();
    when(() => repository.listContacts(any()))
        .thenAnswer((_) async => const [contact]);
    when(
      () => repository.triggerSos(
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
        note: any(named: 'note'),
      ),
    ).thenAnswer(
      (_) async => const SosResponseModel(
        status: 'sent',
        alertId: 'alert-1',
        notifiedContactsCount: 1,
      ),
    );
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        currentPatientIdProvider.overrideWithValue('patient-1'),
        emergencyRepositoryProvider.overrideWithValue(repository),
        sosLocationServiceProvider.overrideWithValue(FakeLocationService()),
      ],
      child: const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SosEmergencyScreen()),
      ),
    );
  }

  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('SosEmergencyScreen lists the real emergency contacts',
      (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('سارة - الابنة'), findsOneWidget);
    expect(find.byKey(const ValueKey('sos_no_contacts')), findsNothing);
  });

  testWidgets('no contacts shows an empty state instead of fake contacts',
      (tester) async {
    useTallSurface(tester);
    when(() => repository.listContacts(any()))
        .thenAnswer((_) async => const []);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('sos_no_contacts')), findsOneWidget);
    expect(find.textContaining('سارة - الابنة'), findsNothing);
  });

  testWidgets('the call now button triggers the SOS with the current location',
      (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sos_call_now_btn')));
    await tester.pumpAndSettle();

    verify(
      () => repository.triggerSos(lat: 30.0444, lng: 31.2357, note: null),
    ).called(1);

    expect(find.text('تم إرسال نداء الاستغاثة بنجاح'), findsOneWidget);
  });
}
