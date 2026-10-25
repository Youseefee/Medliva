import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/inventory/domain/models/inventory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryRepository {
  InventoryRepository({
    required ApiClient apiClient,
    SupabaseClient? supabaseClient,
  })  : _apiClient = apiClient,
        _supabaseClient = supabaseClient ?? _tryGetDefaultSupabase();

  final ApiClient _apiClient;
  final SupabaseClient? _supabaseClient;

  static SupabaseClient? _tryGetDefaultSupabase() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

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
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      if (_supabaseClient != null) {
        return await _getForecastFromSupabase(patientId);
      }
      if (e is DioException && e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<List<MedicationForecastModel>> _getForecastFromSupabase(
    String patientId,
  ) async {
    final client = _supabaseClient!;
    final List<dynamic> medsRes = await client
        .from('medications')
        .select('*, schedules(*)')
        .eq('patient_id', patientId)
        .eq('is_active', true);

    final List<MedicationForecastModel> forecasts = [];

    for (final rawMed in medsRes) {
      final med = Map<String, dynamic>.from(rawMed as Map);
      final medId = med['id']?.toString() ?? '';
      final name = med['name']?.toString() ?? '';
      final stockCount = (med['stock_count'] as num?)?.toInt() ?? 0;
      final alertThreshold =
          (med['alert_threshold_days'] as num?)?.toInt() ?? 5;

      List<dynamic> schedules = [];
      if (med['schedules'] is List) {
        schedules = med['schedules'] as List<dynamic>;
      } else {
        try {
          final schedRes = await client
              .from('schedules')
              .select()
              .eq('medication_id', medId)
              .eq('is_active', true);
          schedules = schedRes as List<dynamic>;
        } catch (_) {}
      }

      double dailyDose = 0;
      for (final s in schedules) {
        final sMap = Map<String, dynamic>.from(s as Map);
        final isActive = sMap['is_active'] as bool? ?? true;
        if (isActive) {
          dailyDose += (sMap['dose_amount'] as num?)?.toDouble() ?? 1.0;
        }
      }

      final int daysRemaining =
          dailyDose > 0 ? (stockCount / dailyDose).floor() : 999;
      final bool isLowStock = daysRemaining <= alertThreshold;

      forecasts.add(
        MedicationForecastModel(
          medicationId: medId,
          name: name,
          stockCount: stockCount,
          daysRemaining: daysRemaining,
          isLowStock: isLowStock,
        ),
      );
    }

    return forecasts;
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
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      if (_supabaseClient != null) {
        return await _createRefillOrderFromSupabase(
          patientId: patientId,
          medicationName: medicationName,
          quantity: quantity,
        );
      }
      if (e is DioException && e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<RefillOrderResult> _createRefillOrderFromSupabase({
    required String patientId,
    required String medicationName,
    int quantity = 1,
  }) async {
    final client = _supabaseClient!;
    String patientName = 'المريض';
    String? patientAddress;

    try {
      final userRow = await client
          .from('users')
          .select('name, address')
          .eq('id', patientId)
          .maybeSingle();
      if (userRow != null) {
        final name = userRow['name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          patientName = name.trim();
        }
        patientAddress = userRow['address'] as String?;
      }
    } catch (_) {}

    final lines = [
      'السلام عليكم، أود طلب نواقص أدوية للمريض: $patientName',
      'الأدوية المطلوبة:',
      '• $medicationName: $quantity عبوة',
    ];
    if (patientAddress != null && patientAddress.trim().isNotEmpty) {
      lines.add('العنوان: ${patientAddress.trim()}');
    }
    lines.add('شكراً جزيلاً.');
    final messageText = lines.join('\n');
    final encodedText = Uri.encodeComponent(messageText);
    final whatsappUrl = 'https://wa.me/?text=$encodedText';

    return RefillOrderResult(
      messageText: messageText,
      whatsappUrl: whatsappUrl,
    );
  }
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(
    apiClient: ref.watch(apiClientProvider),
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});
