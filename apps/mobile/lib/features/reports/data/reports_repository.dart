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

class ReportsRepository {
  ReportsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

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
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
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
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(apiClient: ref.watch(apiClientProvider));
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
