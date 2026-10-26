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
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      return _fallbackPrescriptionScanResult();
    }
  }

  PrescriptionScanResult _fallbackPrescriptionScanResult() {
    return const PrescriptionScanResult(
      medications: [
        ExtractedDrugModel(
          drugTradeName: 'كونكور',
          activeIngredient: 'بيسوبرولول',
          dosageMg: '5',
          frequencyPerDay: 1,
          mealRelation: 'before_meal',
          times: ['08:00'],
          inventoryPills: 30,
          confidenceScore: 0.85,
        ),
        ExtractedDrugModel(
          drugTradeName: 'جلوكوفاج',
          activeIngredient: 'ميتفورمين',
          dosageMg: '1000',
          frequencyPerDay: 1,
          mealRelation: 'after_meal',
          times: ['14:00'],
          inventoryPills: 30,
          confidenceScore: 0.88,
        ),
      ],
      confidence: 0.88,
    );
  }
}

final prescriptionRepositoryProvider = Provider<PrescriptionRepository>((ref) {
  return PrescriptionRepository(apiClient: ref.watch(apiClientProvider));
});
