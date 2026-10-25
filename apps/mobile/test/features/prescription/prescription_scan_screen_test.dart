import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/prescription/data/prescription_repository.dart';
import 'package:medliva/features/prescription/domain/models/prescription.dart';
import 'package:medliva/features/prescription/presentation/screens/prescription_scan_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockPrescriptionImagePicker extends Mock
    implements PrescriptionImagePicker;

class MockPrescriptionRepository extends Mock implements PrescriptionRepository;

class MockMedicationRepository extends Mock implements MedicationRepository;

void main() {
  late MockPrescriptionImagePicker imagePicker;
  late MockPrescriptionRepository prescriptionRepository;
  late MockMedicationRepository medicationRepository;

  final fakeFile = XFile.fromData(
    Uint8List.fromList([1, 2, 3]),
    name: 'rx.jpg',
  );

  setUpAll(() {
    registerFallbackValue(ImageSource.camera);
    registerFallbackValue(fakeFile);
    registerFallbackValue(const MedicationCreateInput(name: 'fallback'));
  });

  setUp(() {
    imagePicker = MockPrescriptionImagePicker();
    prescriptionRepository = MockPrescriptionRepository();
    medicationRepository = MockMedicationRepository();

    when(() => medicationRepository.listMedications(any()))
        .thenAnswer((_) async => const []);
  });

  testWidgets(
      'PrescriptionScanScreen mocked scan -> edit -> confirm creates meds; cancel creates none',
      (tester) async {
    when(() => imagePicker.pickImage(any())).thenAnswer((_) async => fakeFile);
    when(() => prescriptionRepository.scanPrescription(any())).thenAnswer(
      (_) async => const PrescriptionScanResult(
        medications: [
          ExtractedDrugModel(
            drugTradeName: 'Concor 5mg',
            dosageMg: '5mg',
            times: ['08:00'],
          ),
        ],
      ),
    );
    when(() => medicationRepository.createMedication('patient-1', any()))
        .thenAnswer(
      (_) async => const MedicationModel(
        id: 'med-rx-1',
        patientId: 'patient-1',
        name: 'Concor 5mg Plus',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentPatientIdProvider.overrideWithValue('patient-1'),
          prescriptionImagePickerProvider.overrideWithValue(imagePicker),
          prescriptionRepositoryProvider
              .overrideWithValue(prescriptionRepository),
          medicationRepositoryProvider.overrideWithValue(medicationRepository),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PrescriptionScanScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Scan and cancel -> creates none
    await tester.tap(find.byKey(const ValueKey('scan_camera_btn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('scan_name_field_0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scan_cancel_btn')));
    await tester.pumpAndSettle();

    verifyNever(() => medicationRepository.createMedication(any(), any()));

    // 2. Scan -> edit name -> confirm -> creates medication
    await tester.tap(find.byKey(const ValueKey('scan_camera_btn')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('scan_name_field_0')),
      'Concor 5mg Plus',
    );
    await tester.tap(find.byKey(const ValueKey('scan_confirm_btn')));
    await tester.pumpAndSettle();

    verify(() => medicationRepository.createMedication('patient-1', any()))
        .called(1);
  });
}
