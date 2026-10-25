import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/notifications/domain/models/alert.dart';

class AlertsRepository {
  AlertsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Recent alerts of a patient (SOS, critical vitals, low stock, missed doses).
  Future<List<AlertModel>> listAlerts(
    String patientId, {
    int limit = 50,
  }) async {
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '/patients/$patientId/alerts',
        queryParameters: {'limit': limit},
      );
      final data = res.data ?? const [];
      return data
          .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }
}

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository(apiClient: ref.watch(apiClientProvider));
});
