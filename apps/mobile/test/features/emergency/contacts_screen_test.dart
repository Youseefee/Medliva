import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/emergency/data/emergency_repository.dart';
import 'package:medliva/features/emergency/domain/models/emergency.dart';
import 'package:medliva/features/emergency/presentation/screens/contacts_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockEmergencyRepository extends Mock implements EmergencyRepository;

void main() {
  late MockEmergencyRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const EmergencyContactCreateInput(name: 'سارة', phone: '01012345678'),
    );
  });

  setUp(() {
    repository = MockEmergencyRepository();
  });

  testWidgets('EmergencyContactsScreen lists and adds an emergency contact',
      (tester) async {
    when(() => repository.listContacts('patient-1')).thenAnswer(
      (_) async => const [
        EmergencyContactModel(
          id: 'c-1',
          patientId: 'patient-1',
          name: 'محمد أحمد',
          phone: '+201011112222',
          relationship: 'الابن',
        ),
      ],
    );
    when(() => repository.createContact('patient-1', any())).thenAnswer(
      (_) async => const EmergencyContactModel(
        id: 'c-2',
        patientId: 'patient-1',
        name: 'سارة أحمد',
        phone: '+201033334444',
        relationship: 'الابنة',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentPatientIdProvider.overrideWithValue('patient-1'),
          emergencyRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: EmergencyContactsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('محمد أحمد'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('contact_name_field')),
      'سارة أحمد',
    );
    await tester.enterText(
      find.byKey(const ValueKey('contact_phone_field')),
      '+201033334444',
    );
    await tester.tap(find.byKey(const ValueKey('add_contact_btn')));
    await tester.pumpAndSettle();

    expect(find.text('سارة أحمد'), findsOneWidget);
    verify(() => repository.createContact('patient-1', any())).called(1);
  });
}
