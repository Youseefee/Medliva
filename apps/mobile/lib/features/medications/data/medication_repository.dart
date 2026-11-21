import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicationRepository {
  MedicationRepository({SupabaseClient? supabaseClient})
    : _supabaseClient = supabaseClient;

  final SupabaseClient? _supabaseClient;

  SupabaseClient get _client => _supabaseClient ?? Supabase.instance.client;

  Future<List<MedicationModel>> listMedications(String patientId) async {
    final response = await _client
        .from('medications')
        .select('*, schedules(*)')
        .eq('patient_id', patientId)
        .eq('is_active', true)
        .order('created_at', ascending: true);

    return (response as List<dynamic>).map((item) {
      final medication = Map<String, dynamic>.from(item as Map);
      final schedules = medication['schedules'];
      if (schedules is List) {
        medication['schedules'] = schedules.where((schedule) {
          final row = Map<String, dynamic>.from(schedule as Map);
          return row['is_active'] as bool? ?? true;
        }).toList();
      }
      return MedicationModel.fromJson(medication);
    }).toList();
  }

  Future<MedicationModel> createMedication(
    String patientId,
    MedicationCreateInput input,
  ) async {
    final medication = input.toJson();
    final schedules = List<Map<String, dynamic>>.from(
      medication.remove('schedules') as List,
    );
    final response = await _client.rpc<Map<String, dynamic>>(
      'create_medication_with_schedules',
      params: {
        'p_patient_id': patientId,
        'p_medication': medication,
        'p_schedules': schedules,
      },
    );
    return MedicationModel.fromJson(_asRow(response));
  }

  Future<MedicationModel> updateMedication(
    String medicationId,
    MedicationUpdateInput input,
  ) async {
    final updates = input.toJson();
    final query = _client.from('medications');
    final response = updates.isEmpty
        ? await query.select('*, schedules(*)').eq('id', medicationId).single()
        : await query
              .update(updates)
              .eq('id', medicationId)
              .select('*, schedules(*)')
              .single();
    final row = Map<String, dynamic>.from(response);
    final schedules = row['schedules'];
    if (schedules is List) {
      row['schedules'] = schedules.where((schedule) {
        final s = Map<String, dynamic>.from(schedule as Map);
        return s['is_active'] as bool? ?? true;
      }).toList();
    }
    return MedicationModel.fromJson(row);
  }

  Future<void> deleteMedication(String medicationId) async {
    final response = await _client
        .from('medications')
        .update({'is_active': false})
        .eq('id', medicationId)
        .select('id')
        .maybeSingle();
    if (response == null) {
      throw StateError('The medication does not exist or is not accessible.');
    }
  }

  Future<List<ScheduleModel>> listSchedules(String medicationId) async {
    final response = await _client
        .from('schedules')
        .select()
        .eq('medication_id', medicationId)
        .eq('is_active', true)
        .order('time_of_day', ascending: true);
    return (response as List<dynamic>)
        .map(
          (item) =>
              ScheduleModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<ScheduleModel> createSchedule(
    String medicationId,
    ScheduleCreateInput input,
  ) async {
    final response = await _client
        .from('schedules')
        .insert({
          'medication_id': medicationId,
          ...input.toJson(),
          'is_active': true,
        })
        .select()
        .single();
    return ScheduleModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<ScheduleModel> updateSchedule(
    String scheduleId,
    ScheduleUpdateInput input,
  ) async {
    final updates = input.toJson();
    final query = _client.from('schedules');
    final response = updates.isEmpty
        ? await query.select().eq('id', scheduleId).single()
        : await query.update(updates).eq('id', scheduleId).select().single();
    return ScheduleModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> deleteSchedule(String scheduleId) async {
    final response = await _client
        .from('schedules')
        .update({'is_active': false})
        .eq('id', scheduleId)
        .select('id')
        .maybeSingle();
    if (response == null) {
      throw StateError('The schedule does not exist or is not accessible.');
    }
  }

  Future<List<TodayDoseModel>> getTodayDoses(
    String patientId, {
    DateTime? now,
  }) async {
    final medicationsResponse = await _client
        .from('medications')
        .select('id, name, is_active, schedules(*)')
        .eq('patient_id', patientId)
        .eq('is_active', true);
    final medications = (medicationsResponse as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    if (medications.isEmpty) return const [];

    final localNow = (now ?? DateTime.now()).toLocal();
    final startOfToday = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
    ).toUtc();
    final endOfToday = DateTime(
      localNow.year,
      localNow.month,
      localNow.day + 1,
    ).toUtc();

    final logsResponse = await _client
        .from('intake_logs')
        .select()
        .eq('patient_id', patientId)
        .gte('scheduled_time', startOfToday.toIso8601String())
        .lt('scheduled_time', endOfToday.toIso8601String())
        .order('created_at', ascending: true);
    final logs = (logsResponse as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final logsBySchedule = <String, Map<String, dynamic>>{};
    for (final log in logs) {
      final scheduleId = log['schedule_id']?.toString();
      if (scheduleId != null) logsBySchedule[scheduleId] = log;
    }

    final doses = <TodayDoseModel>[];
    for (final medication in medications) {
      final medicationId = medication['id'].toString();
      final medicationName = medication['name'] as String;
      final schedules = medication['schedules'] as List<dynamic>? ?? const [];

      for (final item in schedules) {
        final scheduleMap = Map<String, dynamic>.from(item as Map);
        final scheduleModel = ScheduleModel.fromJson({
          'medication_id': medicationId,
          ...scheduleMap,
        });
        if (!scheduleModel.isScheduledOn(localNow)) continue;

        final scheduleId = scheduleModel.id;
        final log = logsBySchedule[scheduleId];
        final actualTime = log?['actual_time'];
        doses.add(
          TodayDoseModel(
            scheduleId: scheduleId,
            medicationId: medicationId,
            medicationName: medicationName,
            timeOfDay: scheduleModel.timeOfDay,
            doseAmount: scheduleModel.doseAmount,
            mealRelation: scheduleModel.mealRelation,
            instructionsAr: scheduleModel.instructionsAr,
            status: log?['status'] as String? ?? 'pending',
            intakeLogId: log?['id']?.toString(),
            actualTime: actualTime == null
                ? null
                : DateTime.parse(actualTime as String),
          ),
        );
      }
    }

    doses.sort((left, right) => left.timeOfDay.compareTo(right.timeOfDay));
    return doses;
  }

  Future<IntakeLogModel> logAdherence(IntakeLogCreateInput input) async {
    final response = await _client.rpc<Map<String, dynamic>>(
      'record_intake_log',
      params: {
        'p_client_uuid': input.clientUuid,
        'p_schedule_id': input.scheduleId,
        'p_scheduled_time': input.scheduledTime.toUtc().toIso8601String(),
        'p_actual_time': input.actualTime?.toUtc().toIso8601String(),
        'p_status': input.status,
        'p_reason': input.reason,
        'p_logged_offline': input.loggedOffline,
      },
    );
    return IntakeLogModel.fromJson(_asRow(response));
  }

  Future<IntakeLogModel> logDose(IntakeLogCreateInput input) =>
      logAdherence(input);

  Future<List<String>> syncBatch(List<Map<String, dynamic>> items) async {
    final synced = <String>[];
    for (final item in items) {
      if (item['entity'] != 'intake_log') continue;
      final clientUuid = item['client_uuid']?.toString();
      final rawPayload = item['payload'];
      if (clientUuid == null || rawPayload is! Map) continue;

      try {
        final payload = Map<String, dynamic>.from(rawPayload);
        final actualTime = payload['actual_time'];
        await logAdherence(
          IntakeLogCreateInput(
            clientUuid: clientUuid,
            scheduleId: payload['schedule_id'].toString(),
            scheduledTime: DateTime.parse(payload['scheduled_time'] as String),
            actualTime: actualTime == null
                ? null
                : DateTime.parse(actualTime as String),
            status: payload['status'] as String? ?? 'taken',
            reason: payload['reason'] as String?,
            loggedOffline: true,
          ),
        );
        synced.add(clientUuid);
      } catch (_) {
        // Keep failed items in the encrypted local queue for another attempt.
      }
    }
    return synced;
  }

  Map<String, dynamic> _asRow(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List && value.isNotEmpty) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    throw StateError('Supabase returned no row.');
  }
}

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository(
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});
