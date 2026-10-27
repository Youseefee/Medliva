import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/notifications/domain/models/alert.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertsRepository {
  AlertsRepository({SupabaseClient? supabaseClient})
    : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabaseClient;

  /// Reads stored alerts and today's 15-minute missed-dose alerts via Postgres.
  Future<List<AlertModel>> listAlerts(
    String patientId, {
    int limit = 50,
    DateTime? now,
  }) async {
    if (limit < 1 || limit > 200) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 200.');
    }
    final rows = await _supabaseClient.rpc<dynamic>(
      'list_patient_alerts',
      params: {
        'p_patient_id': patientId,
        'p_limit': limit,
        'p_now': now?.toUtc().toIso8601String(),
      },
    );
    return (rows as List<dynamic>).map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      if (map['payload'] == null && map['payload_json'] != null) {
        final payload = map['payload_json'];
        if (payload is String) map['payload'] = jsonDecode(payload);
      }
      return AlertModel.fromJson(map);
    }).toList();
  }
}

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository(supabaseClient: ref.watch(supabaseClientProvider));
});
