import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/caregiver/domain/models/caregiver.dart';

class CaregiverRepository {
  CaregiverRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<PairingCodeModel> generatePairingCode() async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/caregiver/pairing-code',
      );
      return PairingCodeModel.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<LinkedPatientModel> pairWithPatient(String code) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/caregiver/pair',
        data: {'code': code.trim()},
      );
      return LinkedPatientModel.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<List<LinkedPatientModel>> listLinkedPatients() async {
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '/caregiver/patients',
      );
      final data = res.data ?? const [];
      return data
          .map((e) => LinkedPatientModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  /// The caregivers that monitor a patient (patient side view).
  Future<List<LinkedCaregiverModel>> listPatientCaregivers(
    String patientId,
  ) async {
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '/patients/$patientId/caregivers',
      );
      final data = res.data ?? const [];
      return data
          .map((e) => LinkedCaregiverModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }
}

final caregiverRepositoryProvider = Provider<CaregiverRepository>((ref) {
  return CaregiverRepository(apiClient: ref.watch(apiClientProvider));
});
