import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/emergency/domain/models/emergency.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmergencyRepository {
  EmergencyRepository({
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

  Future<List<EmergencyContactModel>> getContacts(String patientId) =>
      listContacts(patientId);

  Future<List<EmergencyContactModel>> listContacts(String patientId) async {
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '/patients/$patientId/contacts',
      );
      final data = res.data ?? const [];
      return data
          .map((e) => EmergencyContactModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      if (_supabaseClient != null) {
        return await _listContactsFromSupabase(patientId);
      }
      if (e is DioException && e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<List<EmergencyContactModel>> _listContactsFromSupabase(
    String patientId,
  ) async {
    final res = await _supabaseClient!
        .from('emergency_contacts')
        .select()
        .eq('patient_id', patientId)
        .order('is_primary', ascending: false)
        .order('created_at', ascending: true);

    return (res as List<dynamic>)
        .map(
          (e) => EmergencyContactModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<EmergencyContactModel> addContact(
    String patientId,
    EmergencyContactCreateInput input,
  ) =>
      createContact(patientId, input);

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
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      if (_supabaseClient != null) {
        return await _createContactFromSupabase(patientId, input);
      }
      if (e is DioException && e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<EmergencyContactModel> _createContactFromSupabase(
    String patientId,
    EmergencyContactCreateInput input,
  ) async {
    final insertData = {
      'patient_id': patientId,
      'name': input.name,
      'phone': input.phone,
      if (input.relationship != null) 'relationship': input.relationship,
      'is_primary': input.isPrimary,
    };
    final res = await _supabaseClient!
        .from('emergency_contacts')
        .insert(insertData)
        .select()
        .single();
    return EmergencyContactModel.fromJson(Map<String, dynamic>.from(res));
  }

  Future<SosResponseModel> triggerSos({
    String? patientId,
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
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      if (_supabaseClient != null) {
        return await _triggerSosFromSupabase(
          patientId: patientId,
          lat: lat,
          lng: lng,
          note: note,
        );
      }
      if (e is DioException && e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<SosResponseModel> _triggerSosFromSupabase({
    String? patientId,
    double? lat,
    double? lng,
    String? note,
  }) async {
    final client = _supabaseClient!;
    final effectivePatientId = patientId ?? client.auth.currentUser?.id;
    if (effectivePatientId == null) {
      throw ApiException(
        message: 'لم يتم العثور على حساب المريض لتشغيل طوارئ SOS',
        statusCode: 400,
      );
    }

    String? patientName;
    String? patientPhone;
    try {
      final userRow = await client
          .from('users')
          .select('name, phone')
          .eq('id', effectivePatientId)
          .maybeSingle();
      if (userRow != null) {
        patientName = userRow['name'] as String?;
        patientPhone = userRow['phone'] as String?;
      }
    } catch (_) {}

    final sosPayload = {
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (note != null) 'note': note,
      if (patientName != null) 'patient_name': patientName,
      if (patientPhone != null) 'patient_phone': patientPhone,
    };

    int notifiedCount = 0;
    try {
      final contactsRes = await client
          .from('emergency_contacts')
          .select('id')
          .eq('patient_id', effectivePatientId);
      final caregiversRes = await client
          .from('caregiver_links')
          .select('id')
          .eq('patient_id', effectivePatientId)
          .eq('status', 'active');
      notifiedCount =
          (contactsRes as List).length + (caregiversRes as List).length;
    } catch (_) {}

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final insertData = {
      'patient_id': effectivePatientId,
      'type': 'sos',
      'tier': 3,
      'payload_json': jsonEncode(sosPayload),
      'sent_at': nowIso,
    };

    final res = await client
        .from('alerts')
        .insert(insertData)
        .select('id')
        .single();

    return SosResponseModel(
      status: 'active',
      alertId: res['id']?.toString() ?? '',
      notifiedContactsCount: notifiedCount,
    );
  }
}

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository(
    apiClient: ref.watch(apiClientProvider),
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});
