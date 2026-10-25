import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/vitals/domain/models/vital.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VitalsRepository {
  VitalsRepository({
    required ApiClient apiClient,
    SupabaseClient? supabaseClient,
  })  : _apiClient = apiClient,
        _supabaseClient = supabaseClient;

  final ApiClient _apiClient;
  final SupabaseClient? _supabaseClient;

  SupabaseClient get _client => _supabaseClient ?? Supabase.instance.client;

  Future<List<VitalReadingModel>> listVitals(String patientId) async {
    try {
      final res = await _apiClient.dio.get<List<dynamic>>(
        '/patients/$patientId/vitals',
      );
      final data = res.data ?? const [];
      return data
          .map((e) => VitalReadingModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      return await _listVitalsFromSupabase(patientId);
    } catch (_) {
      return await _listVitalsFromSupabase(patientId);
    }
  }

  Future<List<VitalReadingModel>> _listVitalsFromSupabase(
    String patientId,
  ) async {
    final res = await _client
        .from('vitals_logs')
        .select()
        .eq('patient_id', patientId)
        .order('recorded_at', ascending: false);

    final data = res as List<dynamic>;
    return data
        .map((e) => VitalReadingModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<VitalReadingModel> createVital(
    String patientId,
    VitalCreateInput input,
  ) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/patients/$patientId/vitals',
        data: input.toJson(),
      );
      return VitalReadingModel.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      return await _createVitalInSupabase(patientId, input);
    } catch (_) {
      return await _createVitalInSupabase(patientId, input);
    }
  }

  // Alias for addVital
  Future<VitalReadingModel> addVital(
    String patientId,
    VitalCreateInput input,
  ) =>
      createVital(patientId, input);

  Future<VitalReadingModel> _createVitalInSupabase(
    String patientId,
    VitalCreateInput input,
  ) async {
    final band = computeTriageBand(
      type: input.type,
      valuePrimary: input.valuePrimary,
      valueSecondary: input.valueSecondary,
      mealContext: input.mealContext,
    );

    final row = {
      if (input.clientUuid != null) 'client_uuid': input.clientUuid,
      'patient_id': patientId,
      'type': input.type,
      'value_primary': input.valuePrimary,
      if (input.valueSecondary != null)
        'value_secondary': input.valueSecondary,
      if (input.mealContext != null) 'meal_context': input.mealContext,
      'band': band,
      if (input.rawTranscript != null) 'raw_transcript': input.rawTranscript,
      'recorded_at': DateTime.now().toUtc().toIso8601String(),
    };

    final inserted = await _client
        .from('vitals_logs')
        .insert(row)
        .select()
        .single();

    return VitalReadingModel.fromJson(Map<String, dynamic>.from(inserted));
  }

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

  Future<VoiceVitalsParseResult> parseVoiceVitals(String transcript) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/ai/parse-voice-vitals',
        data: {'transcript': transcript},
      );
      return VoiceVitalsParseResult.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      return parseVoiceVitalsLocally(transcript);
    } catch (_) {
      return parseVoiceVitalsLocally(transcript);
    }
  }

  static String normalizeDigits(String input) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var result = input;
    for (var i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], '$i');
    }
    return result;
  }

  static String normalizeArabicSpokenNumbers(String input) {
    var cleaned = normalizeDigits(input);
    cleaned = cleaned.replaceAll(RegExp(r'\s*(?:على|فوق|من)\s*'), ' / ');

    const compoundPatterns = [
      ('مية وخمسة وتلاتين', '135'),
      ('مية وخمسة وثلاثين', '135'),
      ('مية وعشرين', '120'),
      ('مية وتلاتين', '130'),
      ('مية وثلاثين', '130'),
      ('مية واربعين', '140'),
      ('مية وأربعين', '140'),
      ('مية وخمسين', '150'),
      ('مية وستين', '160'),
      ('مية وسبعين', '170'),
      ('مية وتمانين', '180'),
      ('مية وثمانين', '180'),
      ('مية وتسعين', '190'),
      ('ميتين', '200'),
      ('مئتين', '200'),
      ('خمسة وتسعين', '95'),
      ('خمسة وتمانين', '85'),
      ('خمسة وثمانين', '85'),
      ('خمسة وسبعين', '75'),
      ('تسعين', '90'),
      ('تمانين', '80'),
      ('ثمانين', '80'),
      ('سبعين', '70'),
      ('ستين', '60'),
      ('خمسين', '50'),
      ('اربعين', '40'),
      ('أربعين', '40'),
      ('تلاتين', '30'),
      ('ثلاثين', '30'),
      ('عشرين', '20'),
      ('عشرة', '10'),
      ('مية', '100'),
      ('مئة', '100'),
      ('مائة', '100'),
    ];

    for (final pattern in compoundPatterns) {
      cleaned = cleaned.replaceAll(pattern.$1, pattern.$2);
    }
    return cleaned;
  }

  static VoiceVitalsParseResult parseVoiceVitalsLocally(String transcript) {
    final text = normalizeArabicSpokenNumbers(transcript.trim());
    // BP check: e.g. "120 على 80" or "120 / 80" or "120 80"
    final bpMatch =
        RegExp(r'(\d{2,3})\s*(?:/|-|\s)\s*(\d{2,3})').firstMatch(text);
    if (bpMatch != null &&
        (text.contains('ضغط') ||
            text.contains('bp') ||
            bpMatch.group(2) != null)) {
      final sys = double.tryParse(bpMatch.group(1)!) ?? 120;
      final dia = double.tryParse(bpMatch.group(2)!) ?? 80;
      final band = computeTriageBand(
        type: 'bp',
        valuePrimary: sys,
        valueSecondary: dia,
      );
      return VoiceVitalsParseResult(
        transcript: transcript,
        type: 'bp',
        valuePrimary: sys,
        valueSecondary: dia,
        band: band,
        messageAr: 'تم التعرف على قراءة ضغط الدم $sys / $dia',
      );
    }

    // Pulse check
    if (text.contains('نبض') ||
        text.contains('قلب') ||
        text.contains('pulse')) {
      final match = RegExp(r'(\d{2,3})').firstMatch(text);
      if (match != null) {
        final val = double.tryParse(match.group(1)!) ?? 75;
        final band = computeTriageBand(type: 'pulse', valuePrimary: val);
        return VoiceVitalsParseResult(
          transcript: transcript,
          type: 'pulse',
          valuePrimary: val,
          band: band,
          messageAr: 'تم التعرف على النبض $val نبضة/دقيقة',
        );
      }
    }

    // Glucose check (or default if any single number)
    final numMatch = RegExp(r'(\d{2,3})').firstMatch(text);
    final double val =
        numMatch != null ? (double.tryParse(numMatch.group(1)!) ?? 110) : 110;
    String? mealContext;
    if (text.contains('صايم') || text.contains('صائم')) {
      mealContext = 'fasting';
    } else if (text.contains('فاطر') || text.contains('بعد')) {
      mealContext = 'post_prandial';
    }
    final band = computeTriageBand(
      type: 'glucose',
      valuePrimary: val,
      mealContext: mealContext,
    );
    return VoiceVitalsParseResult(
      transcript: transcript,
      type: 'glucose',
      valuePrimary: val,
      mealContext: mealContext,
      band: band,
      messageAr: 'تم التعرف على قراءة السكر $val مجم/ديسيلتر',
    );
  }
}

final vitalsRepositoryProvider = Provider<VitalsRepository>((ref) {
  return VitalsRepository(
    apiClient: ref.watch(apiClientProvider),
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});
