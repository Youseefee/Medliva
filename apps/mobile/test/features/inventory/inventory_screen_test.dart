import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/inventory/data/inventory_repository.dart';
import 'package:medliva/features/inventory/domain/models/inventory.dart';
import 'package:medliva/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockInventoryRepository extends Mock implements InventoryRepository;

void main() {
  late MockInventoryRepository repository;

  setUp(() {
    repository = MockInventoryRepository();
  });

  testWidgets(
      'InventoryScreen shows warning under 7 days left and calls refill-order on button tap',
      (tester) async {
    when(() => repository.getForecast('patient-1')).thenAnswer(
      (_) async => const [
        MedicationForecastModel(
          medicationId: 'med-low',
          name: 'Concor 5mg',
          stockCount: 4,
          daysRemaining: 4,
          isLowStock: true,
        ),
      ],
    );
    when(
      () => repository.createRefillOrder(
        patientId: 'patient-1',
        medicationName: 'Concor 5mg',
      ),
    ).thenAnswer(
      (_) async => const RefillOrderResult(
        messageText: 'طلب إعادة تعبئة Concor 5mg',
        whatsappUrl: 'https://wa.me/20100000000',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentPatientIdProvider.overrideWithValue('patient-1'),
          inventoryRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InventoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Concor 5mg'), findsOneWidget);
    expect(find.text('متبقي 4 يوم'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('low_stock_warn_med-low')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('refill_btn_med-low')));
    await tester.pumpAndSettle();

    verify(
      () => repository.createRefillOrder(
        patientId: 'patient-1',
        medicationName: 'Concor 5mg',
      ),
    ).called(1);
    expect(find.text('طلب إعادة تعبئة Concor 5mg'), findsOneWidget);
    // Fake hardcoded grandchildren voice-message card is removed.
    expect(find.text('0:28'), findsNothing);
  });

  testWidgets('InventoryScreen shows empty state when no medications exist', (
    tester,
  ) async {
    when(() => repository.getForecast('patient-1'))
        .thenAnswer((_) async => const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentPatientIdProvider.overrideWithValue('patient-1'),
          inventoryRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InventoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('inventory_empty_card')), findsOneWidget);
    expect(find.text('No medications in inventory'), findsOneWidget);
  });

  testWidgets(
    'InventoryScreen shows expired badge and avoids 999 days for unscheduled meds',
    (tester) async {
      when(() => repository.getForecast('patient-1')).thenAnswer(
        (_) async => const [
          MedicationForecastModel(
            medicationId: 'med-unsched',
            name: 'Aspirin',
            stockCount: 15,
            daysRemaining: 999,
            isExpired: true,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentPatientIdProvider.overrideWithValue('patient-1'),
            inventoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: InventoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No schedule set'), findsOneWidget);
      expect(find.textContaining('999'), findsNothing);
      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('Stock: 15 pills'), findsOneWidget);
    },
  );
}
