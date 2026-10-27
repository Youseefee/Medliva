import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/emergency/domain/models/emergency.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmergencyRepository {
  EmergencyRepository({SupabaseClient? supabaseClient})
    : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabaseClient;

  Future<List<EmergencyContactModel>> getContacts(String patientId) =>
      listContacts(patientId);

  Future<List<EmergencyContactModel>> listContacts(String patientId) async {
    final rows = await _supabaseClient
        .from('emergency_contacts')
        .select()
        .eq('patient_id', patientId)
        .order('is_primary', ascending: false)
        .order('created_at', ascending: true);

    return (rows as List<dynamic>)
        .map(
          (row) => EmergencyContactModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<EmergencyContactModel> addContact(
    String patientId,
    EmergencyContactCreateInput input,
  ) => createContact(patientId, input);

  Future<EmergencyContactModel> createContact(
    String patientId,
    EmergencyContactCreateInput input,
  ) async {
    final row = await _supabaseClient
        .from('emergency_contacts')
        .insert({
          'patient_id': patientId,
          'name': input.name,
          'phone': input.phone,
          if (input.relationship != null) 'relationship': input.relationship,
          'is_primary': input.isPrimary,
        })
        .select()
        .single();

    return EmergencyContactModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<SosResponseModel> triggerSos({
    double? lat,
    double? lng,
    String? note,
  }) async {
    final response = await _supabaseClient.rpc<dynamic>(
      'trigger_sos',
      params: {'p_lat': lat, 'p_lng': lng, 'p_note': note},
    );
    return SosResponseModel.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }
}

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository(supabaseClient: ref.watch(supabaseClientProvider));
});
