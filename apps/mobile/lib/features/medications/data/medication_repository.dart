import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';

class MedicationRepository {
  MedicationRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<MedicationModel>> listMedications(String patientId) async {
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '/patients/$patientId/medications',
      );
      final data = res.data ?? const [];
      return data
          .map((e) => MedicationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
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
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
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
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      await _apiClient.dio.delete<Map<String, dynamic>>(
        '/medications/$medicationId',
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<List<ScheduleModel>> listSchedules(String medicationId) async {
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '/medications/$medicationId/schedules',
      );
      final data = res.data ?? const [];
      return data
          .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
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
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<List<TodayDoseModel>> getTodayDoses(String patientId) async {
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '/patients/$patientId/today',
      );
      final data = res.data ?? const [];
      return data
          .map((e) => TodayDoseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<IntakeLogModel> logAdherence(IntakeLogCreateInput input) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/adherence/log',
        data: input.toJson(),
      );
      return IntakeLogModel.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
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
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }
}

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository(apiClient: ref.watch(apiClientProvider));
});
