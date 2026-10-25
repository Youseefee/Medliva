import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/caregiver/domain/models/caregiver.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaregiverRepository {
  CaregiverRepository({
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

  Future<PairingCodeModel> generatePairingCode() async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/caregiver/pairing-code',
      );
      return PairingCodeModel.fromJson(res.data!);
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      if (_supabaseClient != null) {
        return await _generatePairingCodeFromSupabase();
      }
      if (e is DioException && e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<PairingCodeModel> _generatePairingCodeFromSupabase() async {
    final client = _supabaseClient!;
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw ApiException(
        message: 'يجب تسجيل الدخول لتوليد رمز الاقتران',
        statusCode: 401,
      );
    }

    final code = (Random().nextInt(900000) + 100000).toString();
    final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 10));

    final existing = await client
        .from('caregiver_links')
        .select('id')
        .eq('patient_id', currentUserId)
        .eq('status', 'pending')
        .maybeSingle();

    if (existing != null) {
      final existingId = existing['id'] as Object;
      await client.from('caregiver_links').update({
        'pairing_code': code,
        'pairing_code_expires_at': expiresAt.toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', existingId);
    } else {
      await client.from('caregiver_links').insert({
        'patient_id': currentUserId,
        'pairing_code': code,
        'pairing_code_expires_at': expiresAt.toIso8601String(),
        'status': 'pending',
      });
    }

    return PairingCodeModel(code: code, expiresAt: expiresAt);
  }

  Future<LinkedPatientModel> pairWithPatient(String code) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/caregiver/pair',
        data: {'code': code.trim()},
      );
      return LinkedPatientModel.fromJson(res.data!);
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      if (_supabaseClient != null) {
        return await _pairWithPatientFromSupabase(code);
      }
      if (e is DioException && e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<LinkedPatientModel> _pairWithPatientFromSupabase(String code) async {
    final client = _supabaseClient!;
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw ApiException(
        message: 'يجب تسجيل الدخول لربط مريض',
        statusCode: 401,
      );
    }

    final link = await client
        .from('caregiver_links')
        .select()
        .eq('pairing_code', code.trim())
        .eq('status', 'pending')
        .maybeSingle();

    if (link == null) {
      throw ApiException(
        message: 'رمز الاقتران غير صحيح أو منتهي الصلاحية',
        code: 'INVALID_CODE',
        statusCode: 400,
      );
    }

    final expStr = link['pairing_code_expires_at'] as String?;
    final exp = expStr != null ? DateTime.tryParse(expStr) : null;
    if (exp == null || exp.isBefore(DateTime.now().toUtc())) {
      throw ApiException(
        message: 'رمز الاقتران غير صحيح أو منتهي الصلاحية',
        code: 'INVALID_CODE',
        statusCode: 400,
      );
    }

    final patientId = link['patient_id'] as String;
    if (patientId == currentUserId) {
      throw ApiException(
        message: 'لا يمكنك الاقتران بنفسك',
        code: 'CANNOT_PAIR_SELF',
        statusCode: 400,
      );
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final linkId = link['id'] as Object;
    await client.from('caregiver_links').update({
      'caregiver_id': currentUserId,
      'status': 'active',
      'linked_at': nowIso,
      'pairing_code': null,
      'pairing_code_expires_at': null,
      'updated_at': nowIso,
    }).eq('id', linkId);

    Map<String, dynamic>? patientUser;
    try {
      final userRes = await client
          .from('users')
          .select('name, phone')
          .eq('id', patientId)
          .maybeSingle();
      if (userRes != null) {
        patientUser = Map<String, dynamic>.from(userRes);
      }
    } catch (_) {}

    return LinkedPatientModel(
      patientId: patientId,
      name: patientUser?['name'] as String?,
      phone: patientUser?['phone'] as String?,
      status: 'active',
      linkedAt: DateTime.tryParse(nowIso),
    );
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
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      if (_supabaseClient != null) {
        return await _listLinkedPatientsFromSupabase();
      }
      if (e is DioException && e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<List<LinkedPatientModel>> _listLinkedPatientsFromSupabase() async {
    final client = _supabaseClient!;
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) return const [];

    final rawLinks = await client
        .from('caregiver_links')
        .select()
        .eq('caregiver_id', currentUserId)
        .eq('status', 'active');

    final links = (rawLinks as List<dynamic>)
        .map((l) => Map<String, dynamic>.from(l as Map))
        .toList();

    final patientIds = links.map((l) => l['patient_id'].toString()).toList();
    final Map<String, Map<String, dynamic>> userMap = {};
    if (patientIds.isNotEmpty) {
      try {
        final usersRes = await client
            .from('users')
            .select('id, name, phone')
            .filter('id', 'in', patientIds);
        for (final u in usersRes as List<dynamic>) {
          final map = Map<String, dynamic>.from(u as Map);
          userMap[map['id'].toString()] = map;
        }
      } catch (_) {}
    }

    return links.map((l) {
      final pId = l['patient_id'].toString();
      final u = userMap[pId];
      return LinkedPatientModel(
        patientId: pId,
        name: u?['name'] as String?,
        phone: u?['phone'] as String?,
        status: l['status'] as String? ?? 'active',
        linkedAt: l['linked_at'] != null
            ? DateTime.tryParse(l['linked_at'].toString())
            : null,
      );
    }).toList();
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
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      if (_supabaseClient != null) {
        return await _listPatientCaregiversFromSupabase(patientId);
      }
      if (e is DioException && e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<List<LinkedCaregiverModel>> _listPatientCaregiversFromSupabase(
    String patientId,
  ) async {
    final client = _supabaseClient!;
    final rawLinks = await client
        .from('caregiver_links')
        .select()
        .eq('patient_id', patientId)
        .eq('status', 'active');

    final links = (rawLinks as List<dynamic>)
        .map((l) => Map<String, dynamic>.from(l as Map))
        .toList();

    final caregiverIds = links
        .map((l) => l['caregiver_id']?.toString())
        .whereType<String>()
        .toList();
    final Map<String, Map<String, dynamic>> userMap = {};
    if (caregiverIds.isNotEmpty) {
      try {
        final usersRes = await client
            .from('users')
            .select('id, name, phone')
            .filter('id', 'in', caregiverIds);
        for (final u in usersRes as List<dynamic>) {
          final map = Map<String, dynamic>.from(u as Map);
          userMap[map['id'].toString()] = map;
        }
      } catch (_) {}
    }

    return links.map((l) {
      final cId = l['caregiver_id']?.toString() ?? '';
      final u = userMap[cId];
      return LinkedCaregiverModel(
        caregiverId: cId,
        name: u?['name'] as String?,
        phone: u?['phone'] as String?,
        status: l['status'] as String? ?? 'active',
        linkedAt: l['linked_at'] != null
            ? DateTime.tryParse(l['linked_at'].toString())
            : null,
      );
    }).toList();
  }
}

final caregiverRepositoryProvider = Provider<CaregiverRepository>((ref) {
  return CaregiverRepository(
    apiClient: ref.watch(apiClientProvider),
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});
