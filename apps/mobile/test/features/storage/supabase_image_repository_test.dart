import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medliva/features/storage/data/supabase_image_repository.dart';

class _RecordingImageStorageGateway implements ImageStorageGateway {
  String? uploadedBucket;
  String? uploadedPath;
  Uint8List? uploadedBytes;
  String? uploadedContentType;
  bool uploadedWithUpsert = false;
  bool exists = false;
  String? signedBucket;
  String? signedPath;
  int? signedUrlLifetime;

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
    uploadedBytes = bytes;
    uploadedContentType = contentType;
    uploadedWithUpsert = upsert;
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
    signedBucket = bucket;
    signedPath = path;
    signedUrlLifetime = expiresInSeconds;
    return 'https://storage.example/signed-image';
  }
}

void main() {
  test('uploads prescription directly to its private patient folder', () async {
    final gateway = _RecordingImageStorageGateway();
    final repository = SupabaseImageRepository(
      gateway: gateway,
      idGenerator: () => 'image-id',
    );
    final bytes = Uint8List.fromList([1, 2, 3]);

    final path = await repository.uploadPrescriptionImage(
      patientId: 'patient-1',
      bytes: bytes,
      fileName: 'prescription.png',
    );

    expect(path, 'patient-1/image-id');
    expect(gateway.uploadedBucket, 'prescriptions');
    expect(gateway.uploadedPath, path);
    expect(gateway.uploadedBytes, bytes);
    expect(gateway.uploadedContentType, 'image/png');
    expect(gateway.uploadedWithUpsert, isFalse);
  });

  test('uploads medication photo with replacement enabled', () async {
    final gateway = _RecordingImageStorageGateway();
    final repository = SupabaseImageRepository(gateway: gateway);
    final file = XFile.fromData(
      Uint8List.fromList([4, 5, 6]),
      name: 'pill.webp',
      mimeType: 'image/webp',
    );

    final path = await repository.uploadPillImage(
      patientId: 'patient-1',
      medicationId: 'med-1',
      file: file,
    );

    expect(path, 'patient-1/med-1/image');
    expect(gateway.uploadedBucket, 'pill-images');
    expect(gateway.uploadedContentType, 'image/webp');
    expect(gateway.uploadedWithUpsert, isTrue);
  });

  test('creates a temporary private URL only when the image exists', () async {
    final gateway = _RecordingImageStorageGateway()..exists = true;
    final repository = SupabaseImageRepository(gateway: gateway);

    final url = await repository.getPillImageSignedUrl(
      patientId: 'patient-1',
      medicationId: 'med-1',
    );

    expect(url, 'https://storage.example/signed-image');
    expect(gateway.signedBucket, 'pill-images');
    expect(gateway.signedPath, 'patient-1/med-1/image');
    expect(
      gateway.signedUrlLifetime,
      SupabaseImageRepository.signedUrlLifetimeSeconds,
    );
  });

  test(
    'does not create a signed URL for an image that is not present',
    () async {
      final gateway = _RecordingImageStorageGateway();
      final repository = SupabaseImageRepository(gateway: gateway);

      final url = await repository.getPillImageSignedUrl(
        patientId: 'patient-1',
        medicationId: 'med-1',
      );

      expect(url, isNull);
      expect(gateway.signedPath, isNull);
    },
  );

  test('rejects path traversal before requesting an upload', () async {
    final gateway = _RecordingImageStorageGateway();
    final repository = SupabaseImageRepository(gateway: gateway);

    await expectLater(
      repository.uploadPrescriptionImage(
        patientId: '../another-patient',
        bytes: Uint8List(0),
        fileName: 'prescription.jpg',
      ),
      throwsArgumentError,
    );
    expect(gateway.uploadedPath, isNull);
  });
}
