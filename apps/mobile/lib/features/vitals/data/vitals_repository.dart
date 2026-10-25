import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/vitals/domain/models/vital.dart';

class VitalsRepository {
  VitalsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<VitalReadingModel>> listVitals(String patientId) async {
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '/patients/$patientId/vitals',
      );
      final data = res.data ?? const [];
      return data
          .map((e) => VitalReadingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<VitalReadingModel> createVital(
    String patientId,
    VitalCreateInput input,
  ) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/patients/$patientId/vitals',
        data: input.toJson(),
      );
      return VitalReadingModel.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<VoiceVitalsParseResult> parseVoiceVitals(String transcript) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/ai/parse-voice-vitals',
        data: {'transcript': transcript},
      );
      return VoiceVitalsParseResult.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }
}

final vitalsRepositoryProvider = Provider<VitalsRepository>((ref) {
  return VitalsRepository(apiClient: ref.watch(apiClientProvider));
});
