import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/prescription/domain/models/prescription.dart';
import 'package:medliva/features/storage/data/supabase_image_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef PrescriptionImagePicker = MediaImagePicker;

abstract class PrescriptionOcrGateway {
  Future<Map<String, dynamic>> scanPrescription({
    required String patientId,
    required String imagePath,
    required String fileName,
  });
}

class SupabasePrescriptionOcrGateway implements PrescriptionOcrGateway {
  SupabasePrescriptionOcrGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> scanPrescription({
    required String patientId,
    required String imagePath,
    required String fileName,
  }) async {
    final response = await _client.functions.invoke(
      'scan-prescription',
      body: {
        'patient_id': patientId,
        'image_path': imagePath,
        'file_name': fileName,
      },
    );
    final data = response.data;
    if (response.status < 200 || response.status >= 300) {
      throw FunctionException(
        status: response.status,
        details: data,
        reasonPhrase: 'Prescription scan failed',
      );
    }
    if (data is! Map) {
      throw const FormatException('Invalid prescription scan response.');
    }
    return Map<String, dynamic>.from(data);
  }
}

class PrescriptionRepository {
  PrescriptionRepository({
    required PrescriptionOcrGateway ocrGateway,
    required SupabaseImageRepository imageRepository,
  }) : _ocrGateway = ocrGateway,
       _imageRepository = imageRepository;

  final PrescriptionOcrGateway _ocrGateway;
  final SupabaseImageRepository _imageRepository;

  Future<PrescriptionScanResult> scanPrescription(
    XFile file, {
    required String patientId,
  }) async {
    final imagePath = await _imageRepository.uploadPrescriptionImage(
      patientId: patientId,
      bytes: await file.readAsBytes(),
      fileName: file.name,
      mimeType: file.mimeType,
    );
    final result = await _ocrGateway.scanPrescription(
      patientId: patientId,
      imagePath: imagePath,
      fileName: file.name,
    );
    return PrescriptionScanResult.fromJson(result);
  }
}

final prescriptionImagePickerProvider = Provider<PrescriptionImagePicker>(
  (ref) => ref.watch(mediaImagePickerProvider),
);

final prescriptionOcrGatewayProvider = Provider<PrescriptionOcrGateway>(
  (ref) => SupabasePrescriptionOcrGateway(ref.watch(supabaseClientProvider)),
);

final prescriptionRepositoryProvider = Provider<PrescriptionRepository>((ref) {
  return PrescriptionRepository(
    ocrGateway: ref.watch(prescriptionOcrGatewayProvider),
    imageRepository: ref.watch(supabaseImageRepositoryProvider),
  );
});
