import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/reports/domain/models/report_summary.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsRepository {
  ReportsRepository({
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

  Future<ReportSummaryModel> getReportSummary({
    required String patientId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final res = await _apiClient.dio.get<Map<String, dynamic>>(
        '/patients/$patientId/reports/summary',
        queryParameters: {
          if (fromDate != null) 'from': fromDate,
          if (toDate != null) 'to': toDate,
        },
      );
      return ReportSummaryModel.fromJson(res.data!);
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      if (_supabaseClient != null) {
        return await _getReportSummaryFromSupabase(
          patientId: patientId,
          fromDate: fromDate,
          toDate: toDate,
        );
      }
      if (e is DioException && e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  Future<ReportSummaryModel> _getReportSummaryFromSupabase({
    required String patientId,
    String? fromDate,
    String? toDate,
  }) async {
    final client = _supabaseClient!;
    final now = DateTime.now().toUtc();
    final toDt = toDate != null ? DateTime.tryParse(toDate) ?? now : now;
    final fromDt = fromDate != null
        ? DateTime.tryParse(fromDate) ?? toDt.subtract(const Duration(days: 30))
        : toDt.subtract(const Duration(days: 30));

    final fromIso = fromDt.toIso8601String().split('T').first;
    final toIso = toDt.toIso8601String().split('T').first;

    // 1. Fetch patient profile
    String patientName = 'المريض';
    String? patientPhone;
    try {
      final userRes = await client
          .from('users')
          .select('name, phone')
          .eq('id', patientId)
          .maybeSingle();
      if (userRes != null) {
        final name = userRes['name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          patientName = name.trim();
        }
        patientPhone = userRes['phone'] as String?;
      }
    } catch (_) {}

    // 2. Fetch active medications with schedules
    final activeMeds = <Map<String, dynamic>>[];
    try {
      final medsRes = await client
          .from('medications')
          .select('id, name, strength, form, schedules(id, time_of_day, dose_amount, meal_relation)')
          .eq('patient_id', patientId)
          .eq('is_active', true);
      for (final m in medsRes as List<dynamic>) {
        final medMap = Map<String, dynamic>.from(m as Map);
        activeMeds.add(medMap);
      }
    } catch (_) {}

    // 3. Fetch intake logs in date range
    final adherenceHistory = <Map<String, dynamic>>[];
    int taken = 0;
    int skipped = 0;
    int missed = 0;

    try {
      final logsRes = await client
          .from('intake_logs')
          .select('scheduled_time, status, actual_time, schedule_id')
          .eq('patient_id', patientId)
          .gte('scheduled_time', fromDt.toIso8601String())
          .lte('scheduled_time', toDt.toIso8601String())
          .order('scheduled_time', ascending: false);

      for (final log in logsRes as List<dynamic>) {
        final lMap = Map<String, dynamic>.from(log as Map);
        final status = lMap['status'] as String? ?? 'pending';
        if (status == 'taken') taken++;
        if (status == 'skipped') skipped++;
        if (status == 'missed') missed++;
        adherenceHistory.add(lMap);
      }
    } catch (_) {}

    final totalDoses = taken + skipped + missed;
    final adherencePct = totalDoses > 0
        ? (taken / totalDoses) * 100
        : 100.0;

    // 4. Fetch vitals logs in date range
    final vitalsHistory = <Map<String, dynamic>>[];
    try {
      final vitalsRes = await client
          .from('vitals_logs')
          .select('type, value_primary, value_secondary, band, recorded_at')
          .eq('patient_id', patientId)
          .gte('recorded_at', fromDt.toIso8601String())
          .lte('recorded_at', toDt.toIso8601String())
          .order('recorded_at', ascending: false);

      for (final v in vitalsRes as List<dynamic>) {
        vitalsHistory.add(Map<String, dynamic>.from(v as Map));
      }
    } catch (_) {}

    return ReportSummaryModel(
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      fromDate: fromIso,
      toDate: toIso,
      adherenceRatePct: adherencePct,
      totalDoses: totalDoses,
      takenDoses: taken,
      skippedDoses: skipped,
      missedDosesCount: missed,
      activeMedications: activeMeds,
      adherenceHistory: adherenceHistory,
      vitalsHistory: vitalsHistory,
    );
  }

  Future<({String token, String url, DateTime expiresAt})> createReportShare({
    required String patientId,
    int expiresInHours = 24,
  }) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        '/patients/$patientId/reports/share',
        data: {
          'expires_in_hours': expiresInHours,
          'scope': 'summary_30d',
        },
      );
      final data = res.data!;
      return (
        token: data['token'] as String,
        url: data['url'] as String,
        expiresAt: DateTime.parse(data['expires_at'] as String),
      );
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        if (e.error is ApiException) throw e.error!;
        rethrow;
      }
      return await _createReportShareFallback(
        patientId: patientId,
        expiresInHours: expiresInHours,
      );
    }
  }

  Future<({String token, String url, DateTime expiresAt})>
      _createReportShareFallback({
    required String patientId,
    int expiresInHours = 24,
  }) async {
    final expiresAt = DateTime.now().toUtc().add(Duration(hours: expiresInHours));
    final randomHex = List.generate(
      16,
      (_) => Random().nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final url =
        'https://medliva-report.web.app/public/reports/$randomHex';

    if (_supabaseClient != null) {
      try {
        await _supabaseClient.from('report_shares').insert({
          'patient_id': patientId,
          'token_hash': randomHex,
          'scope': 'summary_30d',
          'expires_at': expiresAt.toIso8601String(),
        });
      } catch (_) {}
    }

    return (
      token: randomHex,
      url: url,
      expiresAt: expiresAt,
    );
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(
    apiClient: ref.watch(apiClientProvider),
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});

/// Fonts used by the doctor report PDF.
class _ReportFonts {
  const _ReportFonts({
    required this.base,
    required this.bold,
    required this.supportsArabic,
  });

  final pw.Font? base;
  final pw.Font? bold;
  final bool supportsArabic;
}

class DoctorReportPdfBuilder {
  const DoctorReportPdfBuilder();

  /// Fonts used by the report. `supportsArabic` is false when the Arabic
  /// font could not be loaded, in that case Arabic text is transliterated.
  static Future<_ReportFonts> _loadFonts(pw.Font? customFont) async {
    if (customFont != null) {
      return _ReportFonts(
        base: customFont,
        bold: customFont,
        supportsArabic: customFont is pw.TtfFont,
      );
    }

    try {
      // Cairo is bundled directly in assets for reliable offline rendering.
      final baseData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      final base = pw.Font.ttf(baseData);
      final bold = pw.Font.ttf(boldData);
      return _ReportFonts(
        base: base,
        bold: bold,
        supportsArabic: true,
      );
    } catch (_) {
      try {
        final base = await PdfGoogleFonts.cairoRegular();
        final bold = await PdfGoogleFonts.cairoBold();
        return _ReportFonts(
          base: base,
          bold: bold,
          supportsArabic: base is pw.TtfFont,
        );
      } catch (_) {
        // Offline / no font cache: fall back to Helvetica.
        return const _ReportFonts(
          base: null,
          bold: null,
          supportsArabic: false,
        );
      }
    }
  }

  static String _toLatin(String text) {
    if (text.isEmpty) return text;
    const arabicToLatin = {
      'ا': 'A', 'أ': 'A', 'إ': 'E', 'آ': 'Aa', 'ء': '', 'ئ': '', 'ؤ': '',
      'ب': 'B', 'ت': 'T', 'ث': 'Th', 'ج': 'G', 'ح': 'H', 'خ': 'Kh',
      'د': 'D', 'ذ': 'Z', 'ر': 'R', 'ز': 'Z', 'س': 'S', 'ش': 'Sh',
      'ص': 'S', 'ض': 'D', 'ط': 'T', 'ظ': 'Z', 'ع': 'A', 'غ': 'Gh',
      'ف': 'F', 'ق': 'Q', 'ك': 'K', 'ل': 'L', 'م': 'M', 'ن': 'N',
      'ه': 'H', 'و': 'W', 'ي': 'Y', 'ى': 'A', 'ة': 'a',
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
      '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    };
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (arabicToLatin.containsKey(char)) {
        buffer.write(arabicToLatin[char]);
      } else if (rune >= 32 && rune <= 126) {
        buffer.write(char);
      }
    }
    final res = buffer.toString().trim();
    return res.isEmpty ? text : res;
  }

  Future<Uint8List> buildPdf({
    required ReportSummaryModel summary,
    pw.Font? customFont,
  }) async {
    // The doctor report is always generated in English (LTR).
    final doc = pw.Document();
    final fonts = await _loadFonts(customFont);
    final baseFont = fonts.base ?? pw.Font.helvetica();
    final boldFont = fonts.bold ?? pw.Font.helveticaBold();

    // Arabic is kept as-is when the embedded font supports it, otherwise it
    // is transliterated so the doctor still gets a readable report.
    String text(String value) =>
        fonts.supportsArabic ? value : _toLatin(value);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
        ),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Medliva - Doctor Medical Report',
                  style: const pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Patient: ${text(summary.patientName)} (${summary.patientPhone ?? 'not provided'})',
                ),
                pw.Text(
                  'Date Range: ${summary.fromDate} -> ${summary.toDate}',
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Active Medications Table
          pw.Text(
            'Active Medications',
            style: const pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: const ['Medication', 'Strength', 'Form', 'Times'],
            data: summary.activeMedications
                .map(
                  (m) => [
                    text((m['name'] ?? '').toString()),
                    text((m['strength'] ?? '-').toString()),
                    text((m['dose_form'] ?? '-').toString()),
                    ((m['times'] as List<dynamic>?) ?? const []).join(', '),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 16),

          // Adherence Summary + Table
          pw.Text(
            'Adherence Summary: ${summary.adherenceRatePct}% '
            '(Taken: ${summary.takenDoses}/${summary.totalDoses}, '
            'Skipped: ${summary.skippedDoses}, '
            'Missed: ${summary.missedDosesCount})',
            style: const pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: const ['Medication', 'Scheduled', 'Actual', 'Status'],
            data: summary.adherenceHistory
                .map(
                  (log) => [
                    text((log['medication_name'] ?? '-').toString()),
                    (log['scheduled_time'] ?? '-').toString(),
                    (log['actual_time'] ?? '-').toString(),
                    (log['status'] ?? '-').toString().toUpperCase(),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 16),

          // Vitals Table with abnormal values marked by text
          pw.Text(
            'Vitals History',
            style: const pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: const ['Type', 'Value', 'Triage Status', 'Recorded At'],
            data: summary.vitalsHistory.map((v) {
              final p = v['value_primary'];
              final s = v['value_secondary'];
              final valStr = s != null ? '$p/$s' : '$p';
              final band = (v['band'] ?? 'normal').toString();
              final bandText = band == 'normal'
                  ? 'NORMAL'
                  : 'ABNORMAL (${band.toUpperCase()})';
              return [
                (v['type'] ?? '-').toString().toUpperCase(),
                valStr,
                bandText,
                (v['recorded_at'] ?? '-').toString(),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 24),

          // Footer Disclaimer
          pw.Divider(),
          pw.Text(
            'Disclaimer: Generated by Medliva for clinical follow-up. '
            'Does not replace direct medical evaluation.',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    return await doc.save();
  }
}
