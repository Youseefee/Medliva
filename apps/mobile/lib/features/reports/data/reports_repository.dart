import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/reports/domain/models/report_summary.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsRepository {
  ReportsRepository({SupabaseClient? supabaseClient})
    : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabaseClient;

  Future<ReportSummaryModel> getReportSummary({
    required String patientId,
    String? fromDate,
    String? toDate,
  }) async {
    final now = DateTime.now().toUtc();
    final endDate = _parseUtcDate(
      toDate,
      DateTime.utc(now.year, now.month, now.day),
    );
    final startDate = _parseUtcDate(
      fromDate,
      endDate.subtract(const Duration(days: 30)),
    );
    if (startDate.isAfter(endDate)) {
      throw ArgumentError('fromDate must not be after toDate.');
    }

    final startAt = startDate.toIso8601String();
    final endExclusive = endDate.add(const Duration(days: 1)).toIso8601String();
    final profile = await _supabaseClient
        .from('users')
        .select('name, phone')
        .eq('id', patientId)
        .maybeSingle();
    if (profile == null) throw StateError('Patient profile was not found.');

    final medicationRows = await _supabaseClient
        .from('medications')
        .select(
          'id, name, form, strength, stock_count, schedules(id, time_of_day)',
        )
        .eq('patient_id', patientId)
        .eq('is_active', true);

    final medicationNamesBySchedule = <String, String>{};
    final activeMedications = (medicationRows as List<dynamic>).map((raw) {
      final medication = Map<String, dynamic>.from(raw as Map);
      final schedules = (medication['schedules'] as List<dynamic>? ?? const [])
          .map((schedule) => Map<String, dynamic>.from(schedule as Map));
      final times = <String>[];
      for (final schedule in schedules) {
        final scheduleId = schedule['id']?.toString();
        if (scheduleId != null) {
          medicationNamesBySchedule[scheduleId] =
              medication['name']?.toString() ?? '';
        }
        final rawTime = schedule['time_of_day']?.toString() ?? '';
        times.add(rawTime.length >= 5 ? rawTime.substring(0, 5) : rawTime);
      }
      return <String, dynamic>{
        'id': medication['id'],
        'name': medication['name'],
        'dose_form': medication['form'],
        'strength': medication['strength'],
        'stock_count': medication['stock_count'],
        'times': times,
      };
    }).toList();

    final logRows = await _supabaseClient
        .from('intake_logs')
        .select('scheduled_time, actual_time, status, reason, schedule_id')
        .eq('patient_id', patientId)
        .gte('scheduled_time', startAt)
        .lt('scheduled_time', endExclusive)
        .order('scheduled_time', ascending: false);
    var taken = 0;
    var skipped = 0;
    var missed = 0;
    final adherenceHistory = (logRows as List<dynamic>).map((raw) {
      final log = Map<String, dynamic>.from(raw as Map);
      final status = log['status']?.toString() ?? '';
      if (status == 'taken') taken++;
      if (status == 'skipped') skipped++;
      if (status == 'missed') missed++;
      return <String, dynamic>{
        ...log,
        'medication_name':
            medicationNamesBySchedule[log['schedule_id']?.toString()] ?? '',
      };
    }).toList();

    final vitalsRows = await _supabaseClient
        .from('vitals_logs')
        .select('type, value_primary, value_secondary, band, recorded_at')
        .eq('patient_id', patientId)
        .gte('recorded_at', startAt)
        .lt('recorded_at', endExclusive)
        .order('recorded_at', ascending: false);
    final totalDoses = adherenceHistory.length;

    return ReportSummaryModel(
      patientId: patientId,
      patientName: (profile['name'] as String?)?.trim().isNotEmpty == true
          ? (profile['name'] as String).trim()
          : 'المريض',
      patientPhone: profile['phone'] as String?,
      fromDate: _dateOnly(startDate),
      toDate: _dateOnly(endDate),
      adherenceRatePct: totalDoses == 0 ? 100 : (taken / totalDoses) * 100,
      totalDoses: totalDoses,
      takenDoses: taken,
      skippedDoses: skipped,
      missedDosesCount: missed,
      activeMedications: activeMedications,
      adherenceHistory: adherenceHistory,
      vitalsHistory: (vitalsRows as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
    );
  }

  Future<({String token, String url, DateTime expiresAt})> createReportShare({
    required String patientId,
    int expiresInHours = 24,
  }) async {
    final result = await _supabaseClient.rpc<dynamic>(
      'create_report_share',
      params: {
        'p_patient_id': patientId,
        'p_expires_in_hours': expiresInHours,
        'p_scope': 'summary_30d',
      },
    );
    final data = Map<String, dynamic>.from(result as Map);
    final token = data['token'] as String;
    final expiresAt = DateTime.parse(data['expires_at'] as String).toUtc();
    final baseUrl = _supabaseClient.rest.url.replaceFirst('/rest/v1', '');
    final url =
        '$baseUrl/functions/v1/public-report?token='
        '${Uri.encodeQueryComponent(token)}';

    return (token: token, url: url, expiresAt: expiresAt);
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(supabaseClient: ref.watch(supabaseClientProvider));
});

DateTime _parseUtcDate(String? value, DateTime fallback) {
  if (value == null) return fallback;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('Invalid report date: $value');
  return DateTime.utc(parsed.year, parsed.month, parsed.day);
}

String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;

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
      return _ReportFonts(base: base, bold: bold, supportsArabic: true);
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
      'ا': 'A',
      'أ': 'A',
      'إ': 'E',
      'آ': 'Aa',
      'ء': '',
      'ئ': '',
      'ؤ': '',
      'ب': 'B',
      'ت': 'T',
      'ث': 'Th',
      'ج': 'G',
      'ح': 'H',
      'خ': 'Kh',
      'د': 'D',
      'ذ': 'Z',
      'ر': 'R',
      'ز': 'Z',
      'س': 'S',
      'ش': 'Sh',
      'ص': 'S',
      'ض': 'D',
      'ط': 'T',
      'ظ': 'Z',
      'ع': 'A',
      'غ': 'Gh',
      'ف': 'F',
      'ق': 'Q',
      'ك': 'K',
      'ل': 'L',
      'م': 'M',
      'ن': 'N',
      'ه': 'H',
      'و': 'W',
      'ي': 'Y',
      'ى': 'A',
      'ة': 'a',
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
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
    String text(String value) => fonts.supportsArabic ? value : _toLatin(value);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
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
                pw.Text('Date Range: ${summary.fromDate} -> ${summary.toDate}'),
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
