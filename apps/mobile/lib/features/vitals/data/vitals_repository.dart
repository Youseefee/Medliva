import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/vitals/domain/models/vital.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VitalsRepository {
  VitalsRepository({SupabaseClient? supabaseClient})
    : _supabaseClient = supabaseClient;

  final SupabaseClient? _supabaseClient;

  SupabaseClient get _client => _supabaseClient ?? Supabase.instance.client;

  Future<List<VitalReadingModel>> listVitals(String patientId) async {
    final res = await _client
        .from('vitals_logs')
        .select()
        .eq('patient_id', patientId)
        .order('recorded_at', ascending: false)
        .limit(50);

    final data = res as List<dynamic>;
    return data
        .map(
          (e) =>
              VitalReadingModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<VitalReadingModel> createVital(
    String patientId,
    VitalCreateInput input,
  ) async {
    final result = await _client.rpc<Map<String, dynamic>>(
      'record_vital',
      params: {
        'p_patient_id': patientId,
        'p_client_uuid': input.clientUuid,
        'p_type': input.type,
        'p_value_primary': input.valuePrimary,
        'p_value_secondary': input.valueSecondary,
        'p_meal_context': input.mealContext,
      },
    );
    return VitalReadingModel.fromJson(Map<String, dynamic>.from(result));
  }

  // Alias for addVital
  Future<VitalReadingModel> addVital(
    String patientId,
    VitalCreateInput input,
  ) => createVital(patientId, input);

  static String computeTriageBand({
    required String type,
    required double valuePrimary,
    double? valueSecondary,
    String? mealContext,
  }) {
    final t = type.toLowerCase();
    if (t == 'bp') {
      final dia = valueSecondary ?? 80.0;
      if (valuePrimary >= 180 ||
          valuePrimary <= 90 ||
          dia >= 120 ||
          dia <= 50) {
        return 'critical';
      }
      if (valuePrimary >= 130 || dia > 80) {
        return 'borderline';
      }
      return 'normal';
    } else if (t == 'glucose') {
      final ctx = (mealContext ?? 'random').toLowerCase();
      if (ctx == 'fasting' || ctx == 'صايم' || ctx == 'صائم') {
        if (valuePrimary < 70 || valuePrimary > 250) return 'critical';
        if (valuePrimary > 110) return 'borderline';
        return 'normal';
      }
      if (ctx == 'post_prandial' ||
          ctx == 'فاطر' ||
          ctx == 'بعد_الاكل' ||
          ctx == 'بعد_الأكل') {
        if (valuePrimary < 70 || valuePrimary > 300) return 'critical';
        if (valuePrimary > 140) return 'borderline';
        return 'normal';
      }
      if (valuePrimary < 70 || valuePrimary > 250) return 'critical';
      if (valuePrimary > 140) return 'borderline';
      return 'normal';
    } else if (t == 'pulse') {
      if (valuePrimary < 50 || valuePrimary > 120) return 'critical';
      if (valuePrimary < 60 || valuePrimary > 100) return 'borderline';
      return 'normal';
    }
    return 'normal';
  }

}

final vitalsRepositoryProvider = Provider<VitalsRepository>((ref) {
  return VitalsRepository(supabaseClient: ref.watch(supabaseClientProvider));
});
