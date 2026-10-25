import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/inventory/domain/models/inventory.dart';

class InventoryRepository {
  InventoryRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<MedicationForecastModel>> getForecast(String patientId) async {
    try {
      final res = await _apiClient.dio.get<Map<String, dynamic>>(
        '/patients/$patientId/inventory/forecast',
      );
      final rawMeds =
          res.data?['medications'] as List<dynamic>? ?? const [];
      return rawMeds
          .map(
            (e) =>
                MedicationForecastModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<RefillOrderResult> createRefillOrder({
    required String patientId,
    required String medicationName,
    int quantity = 1,
  }) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/patients/$patientId/inventory/refill-order',
        data: {
          'items': [
            {'name': medicationName, 'quantity': quantity},
          ],
        },
      );
      return RefillOrderResult.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(apiClient: ref.watch(apiClientProvider));
});
