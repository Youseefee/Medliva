import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/emergency/domain/models/emergency.dart';

class EmergencyRepository {
  EmergencyRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<EmergencyContactModel>> listContacts(String patientId) async {
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '/patients/$patientId/contacts',
      );
      final data = res.data ?? const [];
      return data
          .map((e) => EmergencyContactModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<EmergencyContactModel> createContact(
    String patientId,
    EmergencyContactCreateInput input,
  ) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/patients/$patientId/contacts',
        data: input.toJson(),
      );
      return EmergencyContactModel.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<SosResponseModel> triggerSos({
    double? lat,
    double? lng,
    String? note,
  }) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/emergency/sos',
        data: {
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (note != null) 'note': note,
        },
      );
      return SosResponseModel.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }
}

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository(apiClient: ref.watch(apiClientProvider));
});
