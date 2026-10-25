import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/prescription/domain/models/prescription.dart';

abstract class PrescriptionImagePicker {
  Future<XFile?> pickImage(ImageSource source);
}

class DevicePrescriptionImagePicker implements PrescriptionImagePicker {
  DevicePrescriptionImagePicker({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<XFile?> pickImage(ImageSource source) {
    return _picker.pickImage(source: source);
  }
}

final prescriptionImagePickerProvider =
    Provider<PrescriptionImagePicker>((ref) {
  return DevicePrescriptionImagePicker();
});

class PrescriptionRepository {
  PrescriptionRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<PrescriptionScanResult> scanPrescription(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: file.name),
      });
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/ai/scan-prescription',
        data: formData,
      );
      return PrescriptionScanResult.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }
}

final prescriptionRepositoryProvider = Provider<PrescriptionRepository>((ref) {
  return PrescriptionRepository(apiClient: ref.watch(apiClientProvider));
});
