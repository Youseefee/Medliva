import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medliva/features/prescription/data/prescription_repository.dart';
import 'package:medliva/features/storage/data/supabase_image_repository.dart';

class _RecordingPrescriptionOcrGateway implements PrescriptionOcrGateway {
  _RecordingPrescriptionOcrGateway(this.events, this.response);

  final List<String> events;
  final Map<String, dynamic> response;

  @override
  Future<Map<String, dynamic>> scanPrescription({
    required String patientId,
    required String imagePath,
    required String fileName,
  }) async {
    events.add('ocr-request:$patientId:$imagePath');
    return response;
  }
}

class _RecordingImageStorageGateway implements ImageStorageGateway {
  _RecordingImageStorageGateway(this.events);

  final List<String> events;

  @override
  Future<void> uploadBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
    bool upsert = false,
  }) async {
    events.add('supabase-upload:$bucket:$path');
  }

  @override
  Future<bool> objectExists({
    required String bucket,
    required String path,
  }) async {
    return false;
  }

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int expiresInSeconds,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  test(
    'stores the private image before invoking the Supabase OCR function',
    () async {
      final events = <String>[];
      final repository = PrescriptionRepository(
        ocrGateway: _RecordingPrescriptionOcrGateway(events, {
          'medications': [
            {'drug_trade_name': 'Test medicine'},
          ],
          'confidence': 0.8,
          'source': 'gemini_vision',
        }),
        imageRepository: SupabaseImageRepository(
          gateway: _RecordingImageStorageGateway(events),
          idGenerator: () => 'prescription-image',
        ),
      );

      final result = await repository.scanPrescription(
        XFile.fromData(
          Uint8List.fromList([1, 2, 3]),
          name: 'prescription.jpg',
          mimeType: 'image/jpeg',
        ),
        patientId: 'patient-1',
      );

      expect(events, [
        'supabase-upload:prescriptions:patient-1/prescription-image',
      'ocr-request:patient-1:patient-1/prescription-image',
      ]);
      expect(result.medications.single.drugTradeName, 'Test medicine');
      expect(result.source, 'gemini_vision');
    },
  );

  test('keeps the empty text fallback empty when OCR is unavailable', () async {
    final events = <String>[];
    final repository = PrescriptionRepository(
      ocrGateway: _RecordingPrescriptionOcrGateway(events, const {
        'medications': <dynamic>[],
        'confidence': 0.0,
        'source': 'text',
      }),
      imageRepository: SupabaseImageRepository(
        gateway: _RecordingImageStorageGateway(events),
        idGenerator: () => 'fallback-image',
      ),
    );

    final result = await repository.scanPrescription(
      XFile.fromData(Uint8List.fromList([1]), name: 'unreadable.jpg'),
      patientId: 'patient-1',
    );

    expect(result.medications, isEmpty);
    expect(result.confidence, 0.0);
    expect(result.source, 'text');
  });
}
