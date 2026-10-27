import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/medication_detail_screen.dart';
import 'package:medliva/features/storage/data/supabase_image_repository.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockMedicationRepository extends Mock implements MedicationRepository;

class _RecordingImageStorageGateway implements ImageStorageGateway {
  String? uploadedBucket;
  String? uploadedPath;
  bool exists = false;

  @override
  Future<void> uploadBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
    bool upsert = false,
  }) async {
    uploadedBucket = bucket;
    uploadedPath = path;
  }

  @override
  Future<bool> objectExists({
    required String bucket,
    required String path,
  }) async {
    return exists;
  }

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int expiresInSeconds,
  }) async {
    return 'https://storage.example/medication-image';
  }
}

class _FakeMediaImagePicker implements MediaImagePicker {
  _FakeMediaImagePicker(this.file);

  final XFile file;

  @override
  Future<XFile?> pickImage(ImageSource source) async => file;
}

void main() {
  late MockMedicationRepository repository;

  setUpAll(() {
    registerFallbackValue(const ScheduleCreateInput(timeOfDay: '08:00'));
  });

  setUp(() {
    repository = MockMedicationRepository();
  });

  testWidgets('MedicationDetailScreen adds a new schedule time', (
    tester,
  ) async {
    final imageGateway = _RecordingImageStorageGateway();
    when(() => repository.listMedications(any()))
        .thenAnswer((_) async => const []);
    when(() => repository.createSchedule('med-1', any())).thenAnswer(
      (_) async => const ScheduleModel(
        id: 'sched-new',
        medicationId: 'med-1',
        timeOfDay: '20:30',
      ),
    );

    const med = MedicationModel(
      id: 'med-1',
      patientId: 'patient-1',
      name: 'Concor 5mg',
      schedules: [
        ScheduleModel(id: 'sched-1', medicationId: 'med-1', timeOfDay: '08:00'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentPatientIdProvider.overrideWithValue('patient-1'),
          medicationRepositoryProvider.overrideWithValue(repository),
          supabaseImageRepositoryProvider.overrideWithValue(
            SupabaseImageRepository(gateway: imageGateway),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MedicationDetailScreen(medication: med),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('08:00'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('schedule_time_field')),
      '20:30',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('add_schedule_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add_schedule_btn')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('schedule_item_sched-new')),
      findsOneWidget,
    );
    expect(find.text('20:30'), findsWidgets);
    verify(() => repository.createSchedule('med-1', any())).called(1);
  });

  testWidgets('MedicationDetailScreen uploads a medication photo to Supabase', (
    tester,
  ) async {
    final imageGateway = _RecordingImageStorageGateway();
    const med = MedicationModel(
      id: 'med-1',
      patientId: 'patient-1',
      name: 'Concor 5mg',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentPatientIdProvider.overrideWithValue('patient-1'),
          medicationRepositoryProvider.overrideWithValue(repository),
          supabaseImageRepositoryProvider.overrideWithValue(
            SupabaseImageRepository(gateway: imageGateway),
          ),
          mediaImagePickerProvider.overrideWithValue(
            _FakeMediaImagePicker(
              XFile.fromData(
                Uint8List.fromList([7, 8, 9]),
                name: 'pill.png',
                mimeType: 'image/png',
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MedicationDetailScreen(medication: med),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pill_image_card')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pill_image_upload_btn')));
    await tester.pumpAndSettle();

    expect(imageGateway.uploadedBucket, 'pill-images');
    expect(imageGateway.uploadedPath, 'patient-1/med-1/image');
  });
}
