import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/notifications/domain/models/alert.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertsRepository {
  AlertsRepository({
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
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      if (_supabaseClient != null) {
        return await _listAlertsFromSupabase(patientId, limit: limit);
      }
      if (e is DioException && e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<List<AlertModel>> _listAlertsFromSupabase(
    String patientId, {
    int limit = 50,
  }) async {
    final rows = await _supabaseClient!
        .from('alerts')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List<dynamic>).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      if (map['payload'] == null && map['payload_json'] != null) {
        final raw = map['payload_json'];
        if (raw is String) {
          try {
            map['payload'] = jsonDecode(raw);
          } catch (_) {}
        } else if (raw is Map) {
          map['payload'] = Map<String, dynamic>.from(raw);
        }
      }
      return AlertModel.fromJson(map);
    }).toList();
  }
}

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository(
    apiClient: ref.watch(apiClientProvider),
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});
