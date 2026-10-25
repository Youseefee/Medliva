import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicationRepository {
  MedicationRepository({
    required ApiClient apiClient,
    SupabaseClient? supabaseClient,
  })  : _apiClient = apiClient,
        _supabaseClient = supabaseClient;

  final ApiClient _apiClient;
  final SupabaseClient? _supabaseClient;

  SupabaseClient get _client => _supabaseClient ?? Supabase.instance.client;

  Future<List<MedicationModel>> listMedications(String patientId) async {
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '/patients/$patientId/medications',
      );
      final data = res.data ?? const [];
      return data
          .map((e) => MedicationModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      return await _listMedicationsFromSupabase(patientId);
    } catch (_) {
      return await _listMedicationsFromSupabase(patientId);
    }
  }

  Future<List<MedicationModel>> _listMedicationsFromSupabase(
    String patientId,
  ) async {
    final res = await _client
        .from('medications')
        .select('*, schedules(*)')
        .eq('patient_id', patientId)
        .eq('is_active', true)
        .order('created_at', ascending: true);

    final list = res as List<dynamic>;
    return list
        .map((e) => MedicationModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((m) => m.isActive)
        .toList();
  }

  Future<MedicationModel> createMedication(
    String patientId,
    MedicationCreateInput input,
  ) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/patients/$patientId/medications',
        data: input.toJson(),
      );
      return MedicationModel.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      return await _createMedicationInSupabase(patientId, input);
    } catch (_) {
      return await _createMedicationInSupabase(patientId, input);
    }
  }

  Future<MedicationModel> _createMedicationInSupabase(
    String patientId,
    MedicationCreateInput input,
  ) async {
    final medRow = {
      'patient_id': patientId,
      'name': input.name,
      if (input.tradeName != null) 'trade_name': input.tradeName,
      if (input.activeIngredient != null)
        'active_ingredient': input.activeIngredient,
      'form': input.form,
      if (input.strength != null) 'strength': input.strength,
      'stock_count': input.stockCount,
      'alert_threshold_days': input.alertThresholdDays,
      if (input.expiryDate != null) 'expiry_date': input.expiryDate,
      'is_active': true,
    };

    final medRes = await _client
        .from('medications')
        .insert(medRow)
        .select()
        .single();

    final createdMed = Map<String, dynamic>.from(medRes);
    final medId = createdMed['id'] as String;

    final createdSchedules = <Map<String, dynamic>>[];
    for (final s in input.schedules) {
      final schedRow = {
        'medication_id': medId,
        'time_of_day': s.timeOfDay,
        'dose_amount': s.doseAmount,
        'meal_relation': s.mealRelation,
        'days_mask': s.daysMask,
        if (s.instructionsAr != null) 'instructions_ar': s.instructionsAr,
        'is_active': true,
      };
      final schedRes = await _client
          .from('schedules')
          .insert(schedRow)
          .select()
          .single();
      createdSchedules.add(Map<String, dynamic>.from(schedRes));
    }

    createdMed['schedules'] = createdSchedules;
    return MedicationModel.fromJson(createdMed);
  }

  Future<MedicationModel> updateMedication(
    String medicationId,
    MedicationUpdateInput input,
  ) async {
    try {
      final res = await _apiClient.dio.patch<Map<String, dynamic>>(
        '/medications/$medicationId',
        data: input.toJson(),
      );
      return MedicationModel.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      return await _updateMedicationInSupabase(medicationId, input);
    } catch (_) {
      return await _updateMedicationInSupabase(medicationId, input);
    }
  }

  Future<MedicationModel> _updateMedicationInSupabase(
    String medicationId,
    MedicationUpdateInput input,
  ) async {
    final updated = await _client
        .from('medications')
        .update(input.toJson())
        .eq('id', medicationId)
        .select('*, schedules(*)')
        .single();
    return MedicationModel.fromJson(Map<String, dynamic>.from(updated));
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      await _apiClient.dio.delete<Map<String, dynamic>>(
        '/medications/$medicationId',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      await _client
          .from('medications')
          .update({'is_active': false})
          .eq('id', medicationId);
    } catch (_) {
      await _client
          .from('medications')
          .update({'is_active': false})
          .eq('id', medicationId);
    }
  }

  Future<List<ScheduleModel>> listSchedules(String medicationId) async {
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '/medications/$medicationId/schedules',
      );
      final data = res.data ?? const [];
      return data
          .map((e) => ScheduleModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      return await _listSchedulesFromSupabase(medicationId);
    } catch (_) {
      return await _listSchedulesFromSupabase(medicationId);
    }
  }

  Future<List<ScheduleModel>> _listSchedulesFromSupabase(
    String medicationId,
  ) async {
    final res = await _client
        .from('schedules')
        .select()
        .eq('medication_id', medicationId)
        .eq('is_active', true);
    final list = res as List<dynamic>;
    return list
        .map((e) => ScheduleModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ScheduleModel> createSchedule(
    String medicationId,
    ScheduleCreateInput input,
  ) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/medications/$medicationId/schedules',
        data: input.toJson(),
      );
      return ScheduleModel.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      return await _createScheduleInSupabase(medicationId, input);
    } catch (_) {
      return await _createScheduleInSupabase(medicationId, input);
    }
  }

  Future<ScheduleModel> _createScheduleInSupabase(
    String medicationId,
    ScheduleCreateInput input,
  ) async {
    final schedRow = {
      'medication_id': medicationId,
      'time_of_day': input.timeOfDay,
      'dose_amount': input.doseAmount,
      'meal_relation': input.mealRelation,
      'days_mask': input.daysMask,
      if (input.instructionsAr != null) 'instructions_ar': input.instructionsAr,
      'is_active': true,
    };
    final res = await _client
        .from('schedules')
        .insert(schedRow)
        .select()
        .single();
    return ScheduleModel.fromJson(Map<String, dynamic>.from(res));
  }

  Future<List<TodayDoseModel>> getTodayDoses(String patientId) async {
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '/patients/$patientId/today',
      );
      final data = res.data ?? const [];
      return data
          .map((e) => TodayDoseModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      return await _getTodayDosesFromSupabase(patientId);
    } catch (_) {
      return await _getTodayDosesFromSupabase(patientId);
    }
  }

  Future<List<TodayDoseModel>> _getTodayDosesFromSupabase(
    String patientId,
  ) async {
    // 1. Fetch active medications with schedules
    final medsRes = await _client
        .from('medications')
        .select('id, name, is_active, schedules(*)')
        .eq('patient_id', patientId)
        .eq('is_active', true);

    final meds = (medsRes as List<dynamic>)
        .map((m) => Map<String, dynamic>.from(m as Map))
        .toList();

    if (meds.isEmpty) return const [];

    // 2. Fetch today's intake logs for patient
    final now = DateTime.now();
    final startOfToday = DateTime.utc(now.year, now.month, now.day, 0, 0, 0);
    final endOfToday =
        DateTime.utc(now.year, now.month, now.day, 23, 59, 59, 999);

    final logsRes = await _client
        .from('intake_logs')
        .select()
        .eq('patient_id', patientId)
        .gte('scheduled_time', startOfToday.toIso8601String())
        .lte('scheduled_time', endOfToday.toIso8601String());

    final logs = (logsRes as List<dynamic>)
        .map((l) => Map<String, dynamic>.from(l as Map))
        .toList();

    final logsBySchedule = <String, Map<String, dynamic>>{};
    for (final l in logs) {
      final schedId = l['schedule_id']?.toString();
      if (schedId != null) {
        logsBySchedule[schedId] = l;
      }
    }

    final doses = <TodayDoseModel>[];

    for (final med in meds) {
      final medId = med['id'] as String;
      final medName = med['name'] as String;
      final rawSchedules = med['schedules'] as List<dynamic>? ?? const [];

      for (final sRaw in rawSchedules) {
        final s = Map<String, dynamic>.from(sRaw as Map);
        final isActive = s['is_active'] as bool? ?? true;
        if (!isActive) continue;

        final scheduleId = s['id'] as String;
        final rawTime = s['time_of_day'] as String;
        final timeOfDay =
            rawTime.length >= 5 ? rawTime.substring(0, 5) : rawTime;

        final log = logsBySchedule[scheduleId];
        final status =
            log != null ? (log['status'] as String? ?? 'taken') : 'pending';
        final intakeLogId = log != null ? log['id'] as String? : null;
        final actualTime = log != null && log['actual_time'] != null
            ? DateTime.parse(log['actual_time'] as String)
            : null;

        doses.add(
          TodayDoseModel(
            scheduleId: scheduleId,
            medicationId: medId,
            medicationName: medName,
            timeOfDay: timeOfDay,
            doseAmount: (s['dose_amount'] as num?)?.toDouble() ?? 1.0,
            mealRelation: s['meal_relation'] as String? ?? 'after_meal',
            instructionsAr: s['instructions_ar'] as String?,
            status: status,
            intakeLogId: intakeLogId,
            actualTime: actualTime,
          ),
        );
      }
    }

    doses.sort((a, b) => a.timeOfDay.compareTo(b.timeOfDay));
    return doses;
  }

  Future<IntakeLogModel> logAdherence(IntakeLogCreateInput input) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/adherence/log',
        data: input.toJson(),
      );
      return IntakeLogModel.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      return await _logAdherenceInSupabase(input);
    } catch (_) {
      return await _logAdherenceInSupabase(input);
    }
  }

  // Convenience alias for logAdherence
  Future<IntakeLogModel> logDose(IntakeLogCreateInput input) =>
      logAdherence(input);

  Future<IntakeLogModel> _logAdherenceInSupabase(
    IntakeLogCreateInput input,
  ) async {
    // 1. Idempotency check by client_uuid
    try {
      final existing = await _client
          .from('intake_logs')
          .select()
          .eq('client_uuid', input.clientUuid)
          .maybeSingle();

      if (existing != null) {
        return IntakeLogModel.fromJson(Map<String, dynamic>.from(existing));
      }
    } catch (_) {
      // Proceed to insert if idempotency lookup fails
    }

    // 2. Resolve patient_id and medication info
    String? patientId = input.patientId;
    String? medId;
    double doseAmount = 1;
    int? currentStock;

    try {
      final schedRes = await _client
          .from('schedules')
          .select(
            'medication_id, dose_amount, medications(id, patient_id, stock_count)',
          )
          .eq('id', input.scheduleId)
          .maybeSingle();

      if (schedRes != null) {
        final sMap = Map<String, dynamic>.from(schedRes);
        doseAmount = (sMap['dose_amount'] as num?)?.toDouble() ?? 1.0;
        final medData = sMap['medications'] != null
            ? Map<String, dynamic>.from(sMap['medications'] as Map)
            : null;
        if (medData != null) {
          patientId ??= medData['patient_id'] as String?;
          medId = medData['id'] as String?;
          currentStock = medData['stock_count'] as int?;
        }
      }
    } catch (_) {}

    patientId ??= _client.auth.currentUser?.id ?? '';

    final actualTime = input.actualTime ??
        (input.status == 'taken' ? DateTime.now().toUtc() : null);

    final row = {
      'client_uuid': input.clientUuid,
      'schedule_id': input.scheduleId,
      'patient_id': patientId,
      'scheduled_time': input.scheduledTime.toUtc().toIso8601String(),
      if (actualTime != null) 'actual_time': actualTime.toIso8601String(),
      'status': input.status,
      if (input.reason != null) 'reason': input.reason,
      'logged_offline': input.loggedOffline,
    };

    final inserted = await _client
        .from('intake_logs')
        .insert(row)
        .select()
        .single();

    // 3. Deduct stock if taken
    if (input.status == 'taken' && medId != null && currentStock != null) {
      try {
        final newStock = (currentStock - doseAmount).round();
        await _client
            .from('medications')
            .update({'stock_count': newStock < 0 ? 0 : newStock})
            .eq('id', medId);
      } catch (_) {}
    }

    return IntakeLogModel.fromJson(Map<String, dynamic>.from(inserted));
  }

  Future<List<String>> syncBatch(List<Map<String, dynamic>> items) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/sync/batch',
        data: {'items': items},
      );
      final rawIds =
          res.data?['synced_client_uuids'] as List<dynamic>? ?? const [];
      return rawIds.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      return await _syncBatchInSupabase(items);
    } catch (_) {
      return await _syncBatchInSupabase(items);
    }
  }

  Future<List<String>> _syncBatchInSupabase(
    List<Map<String, dynamic>> items,
  ) async {
    final synced = <String>[];
    for (final item in items) {
      final clientUuid = item['client_uuid']?.toString();
      final entity = item['entity'] as String?;
      final payload = item['payload'] as Map<String, dynamic>? ?? const {};

      if (clientUuid == null) continue;

      if (entity == 'intake_log') {
        try {
          await _logAdherenceInSupabase(
            IntakeLogCreateInput(
              clientUuid: clientUuid,
              scheduleId: payload['schedule_id'].toString(),
              scheduledTime: DateTime.parse(payload['scheduled_time'] as String),
              actualTime: payload['actual_time'] != null
                  ? DateTime.parse(payload['actual_time'] as String)
                  : null,
              status: payload['status'] as String? ?? 'taken',
              reason: payload['reason'] as String?,
              loggedOffline: true,
            ),
          );
          synced.add(clientUuid);
        } catch (_) {}
      }
    }
    return synced;
  }
}

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository(
    apiClient: ref.watch(apiClientProvider),
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});
