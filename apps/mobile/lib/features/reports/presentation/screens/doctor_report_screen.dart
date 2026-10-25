import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/reports/data/reports_repository.dart';
import 'package:medliva/features/reports/domain/models/report_summary.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:printing/printing.dart';

class ReportDateRangeNotifier extends Notifier<int> {
  @override
  int build() => 30;

  int setDays(int days) => state = days;
}

final reportDateRangeDaysProvider =
    NotifierProvider<ReportDateRangeNotifier, int>(
  ReportDateRangeNotifier.new,
);

final reportSummaryProvider = FutureProvider<ReportSummaryModel?>((ref) {
  final patientId = ref.watch(currentPatientIdProvider);
  if (patientId == null || patientId.isEmpty) {
    return Future.value();
  }
  final days = ref.watch(reportDateRangeDaysProvider);
  final repo = ref.watch(reportsRepositoryProvider);
  if (days == 30) {
    return repo.getReportSummary(patientId: patientId);
  }
  final now = DateTime.now().toUtc();
  final from = now.subtract(Duration(days: days));
  final toDateStr =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final fromDateStr =
      '${from.year.toString().padLeft(4, '0')}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
  return repo.getReportSummary(
    patientId: patientId,
    fromDate: fromDateStr,
    toDate: toDateStr,
  );
});

class DoctorReportScreen extends ConsumerStatefulWidget {
  const DoctorReportScreen({super.key});

  @override
  ConsumerState<DoctorReportScreen> createState() => _DoctorReportScreenState();
}

class _DoctorReportScreenState extends ConsumerState<DoctorReportScreen> {
  String? _shareUrl;
  bool _isGeneratingLink = false;

  Future<void> _sharePdf(
    BuildContext context,
    ReportSummaryModel summary,
  ) async {
    const builder = DoctorReportPdfBuilder();
    final bytes = await builder.buildPdf(
      summary: summary,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'medliva_report_${summary.patientId}.pdf',
    );
  }

  Future<void> _generateShareLink(String patientId) async {
    setState(() => _isGeneratingLink = true);
    try {
      final repo = ref.read(reportsRepositoryProvider);
      final res = await repo.createReportShare(patientId: patientId);
      if (!mounted) return;
      setState(() => _shareUrl = res.url);
      await Clipboard.setData(ClipboardData(text: res.url));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.url)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingLink = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(reportSummaryProvider);
    final selectedDays = ref.watch(reportDateRangeDaysProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.doctorReportTitle),
      ),
      body: SafeArea(
        child: summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text(err.toString())),
          data: (summary) {
            if (summary == null) {
              return const SizedBox.shrink();
            }

            return SingleChildScrollView(
              padding: const EdgeInsetsDirectional.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Date Range Selector (7 / 30 / 90 days)
                  Row(
                    children: [
                      for (final range in const [7, 30, 90])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 4,
                            ),
                            child: Semantics(
                              selected: selectedDays == range,
                              button: true,
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  key: ValueKey('report_range_${range}d'),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: selectedDays == range
                                        ? const Color(0xFF00796B)
                                        : Colors.white,
                                    foregroundColor: selectedDays == range
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  onPressed: () => ref
                                      .read(
                                        reportDateRangeDaysProvider.notifier,
                                      )
                                      .setDays(range),
                                  child: Text(
                                    l10n.daysLeftLabel(range),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Patient Summary & Adherence Ring Card
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 28,
                                backgroundColor: Color(0xFFE0F2F1),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF00796B),
                                  size: 34,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      summary.patientName,
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${summary.fromDate} → ${summary.toDate}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsetsDirectional.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  l10n.appName,
                                  style: const TextStyle(
                                    color: Color(0xFF0369A1),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          Row(
                            children: [
                              SizedBox(
                                width: 68,
                                height: 68,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CircularProgressIndicator(
                                      value: (summary.adherenceRatePct / 100)
                                          .clamp(0.0, 1.0),
                                      strokeWidth: 8,
                                      backgroundColor: Colors.grey.shade200,
                                      color: const Color(0xFF00796B),
                                    ),
                                    Center(
                                      child: Text(
                                        '${summary.adherenceRatePct.toInt()}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Adherence: ${summary.adherenceRatePct}% '
                                      '(${summary.takenDoses}/${summary.totalDoses})',
                                      key: const ValueKey(
                                        'report_adherence_summary',
                                      ),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.reportActiveMedsVitalsSummary(
                                        summary.activeMedications.length,
                                        summary.vitalsHistory.length,
                                      ),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Secure QR Share Card (Image 3 Screen 4)
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Color(0xFFE0F2F1),
                                child: Icon(
                                  Icons.share_rounded,
                                  color: Color(0xFF00796B),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.secureShareTitle,
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    Text(
                                      l10n.secureShareSubtitle,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Container(
                              padding: const EdgeInsetsDirectional.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.qr_code_2_rounded,
                                size: 148,
                                color: Color(0xFF0F2942),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsetsDirectional.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.schedule_rounded,
                                      color: Color(0xFFB45309),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      l10n.expiresIn24Hours,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: const Color(0xFFB45309),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _shareUrl ?? l10n.expiresIn24HoursSub,
                                  style: theme.textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              key: const ValueKey('generate_share_link_btn'),
                              onPressed: _isGeneratingLink
                                  ? null
                                  : () => _generateShareLink(summary.patientId),
                              icon: const Icon(Icons.link_rounded),
                              label: Text(l10n.shareLinkButton),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.reportDisclaimer,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () => _sharePdf(context, summary),
                            icon: const Icon(Icons.picture_as_pdf_rounded),
                            label: Text(l10n.downloadPdfButton),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            key: const ValueKey('share_pdf_report_btn'),
                            onPressed: () => _sharePdf(context, summary),
                            icon: const Icon(Icons.share_rounded),
                            label: Text(l10n.shareReportButton),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
