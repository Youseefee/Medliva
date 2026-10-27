import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/caregiver/domain/models/caregiver.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaregiverRepositoryException implements Exception {
  const CaregiverRepositoryException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class CaregiverRepository {
  CaregiverRepository({SupabaseClient? supabaseClient})
    : _supabaseClient = supabaseClient;

  final SupabaseClient? _supabaseClient;

  SupabaseClient get _client => _supabaseClient ?? Supabase.instance.client;

  Future<void> _requireSignedIn() async {
    if (_client.auth.currentUser == null) {
      throw const CaregiverRepositoryException(
        'يجب تسجيل الدخول لإكمال العملية',
        code: 'UNAUTHENTICATED',
      );
    }
  }

  Future<T> _rpc<T>(String function, {Map<String, dynamic>? params}) async {
    try {
      return await _client.rpc<T>(function, params: params);
    } on PostgrestException catch (error) {
      final code = _errorCode(error.message);
      throw CaregiverRepositoryException(
        _errorMessage(code, error.message),
        code: code,
      );
    }
  }

  String? _errorCode(String message) {
    const codes = [
      'UNAUTHENTICATED',
      'INVALID_ROLE',
      'INVALID_CODE',
      'CANNOT_PAIR_SELF',
      'ALREADY_LINKED',
      'PAIRING_ALREADY_PENDING',
      'FORBIDDEN',
    ];
    final upper = message.toUpperCase();
    for (final code in codes) {
      if (upper.contains(code)) return code;
    }
    return null;
  }

  String _errorMessage(String? code, String fallback) {
    return switch (code) {
      'UNAUTHENTICATED' => 'يجب تسجيل الدخول لإكمال العملية',
      'INVALID_ROLE' => 'نوع الحساب غير مناسب لهذه العملية',
      'INVALID_CODE' => 'رمز الاقتران غير صحيح أو منتهي الصلاحية',
      'CANNOT_PAIR_SELF' => 'لا يمكنك الاقتران بنفسك',
      'ALREADY_LINKED' => 'هذا المريض مرتبط بحسابك بالفعل',
      'PAIRING_ALREADY_PENDING' => 'يوجد طلب ربط سابق قيد الانتظار',
      'FORBIDDEN' => 'ليس لديك صلاحية عرض بيانات هذا المريض',
      _ => fallback,
    };
  }

  Future<PairingCodeModel> generatePairingCode() async {
    await _requireSignedIn();
    final result = await _rpc<Map<String, dynamic>>(
      'generate_caregiver_pairing_code',
    );
    return PairingCodeModel.fromJson(Map<String, dynamic>.from(result));
  }

  Future<LinkedPatientModel> pairWithPatient(String code) async {
    await _requireSignedIn();
    final result = await _rpc<Map<String, dynamic>>(
      'consume_caregiver_pairing_code',
      params: {'p_code': code.trim()},
    );
    return LinkedPatientModel.fromJson(Map<String, dynamic>.from(result));
  }

  Future<List<Map<String, dynamic>>> _loadDashboardRows({DateTime? now}) async {
    await _requireSignedIn();
    final result = await _rpc<List<dynamic>>(
      'get_caregiver_dashboard',
      params: now == null ? null : {'p_now': now.toUtc().toIso8601String()},
    );
    return result.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<List<LinkedPatientModel>> listLinkedPatients({DateTime? now}) async {
    final rows = await _loadDashboardRows(now: now);
    return rows.map(LinkedPatientModel.fromJson).toList();
  }

  Future<List<MissedDoseAlertModel>> listCaregiverAlerts({
    DateTime? now,
  }) async {
    final rows = await _loadDashboardRows(now: now);
    return rows
        .expand((patient) {
          final missedDoses =
              patient['missed_doses'] as List<dynamic>? ?? const [];
          return missedDoses;
        })
        .map(
          (dose) => MissedDoseAlertModel.fromJson(
            Map<String, dynamic>.from(dose as Map),
          ),
        )
        .toList();
  }

  /// The caregivers that monitor a patient (patient side view).
  Future<List<LinkedCaregiverModel>> listPatientCaregivers(
    String patientId,
  ) async {
    await _requireSignedIn();
    final result = await _rpc<List<dynamic>>(
      'list_patient_caregivers',
      params: {'p_patient_id': patientId},
    );
    return result
        .map(
          (row) => LinkedCaregiverModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }
}

final caregiverRepositoryProvider = Provider<CaregiverRepository>((ref) {
  return CaregiverRepository(supabaseClient: ref.watch(supabaseClientProvider));
});
