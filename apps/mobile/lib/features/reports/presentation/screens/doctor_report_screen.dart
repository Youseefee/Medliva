import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/reports/data/reports_repository.dart';
import 'package:medliva/features/reports/domain/models/report_summary.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:pdf/widgets.dart' as pw;
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

class _QrCodePainter extends CustomPainter {
  const _QrCodePainter({required this.data});

  final String data;
  static const Color _color = Color(0xFF0F2942);

  @override
  void paint(Canvas canvas, Size size) {
    final qr = pw.Barcode.qrCode();
    final elements = qr.make(
      data,
      width: size.width,
      height: size.height,
      drawText: false,
    );
    final paint = Paint()
      ..color = _color
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;

    for (final element in elements) {
      if (element is pw.BarcodeBar && element.black) {
        canvas.drawRect(
          Rect.fromLTWH(
            element.left,
            element.top,
            element.width,
            element.height,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCodePainter oldDelegate) =>
      oldDelegate.data != data;
}

class DoctorReportScreen extends ConsumerStatefulWidget {
  const DoctorReportScreen({super.key});

  @override
  ConsumerState<DoctorReportScreen> createState() => _DoctorReportScreenState();
}

class _DoctorReportScreenState extends ConsumerState<DoctorReportScreen> {
  String? _shareUrl;
  bool _isGeneratingLink = false;
  bool _isExportingPdf = false;

  Future<void> _exportPdf(
    BuildContext context,
    ReportSummaryModel summary, {
    required bool printPreview,
  }) async {
    if (_isExportingPdf) return;
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _isExportingPdf = true);
    try {
      const builder = DoctorReportPdfBuilder();
      final bytes = await builder.buildPdf(
        summary: summary,
        isArabic: isArabic,
      );
      final filename = 'medliva_report_${summary.patientId}.pdf';
      if (printPreview) {
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: filename);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: filename);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(l10n.reportPdfError),
          backgroundColor: Theme.of(this.context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  Future<void> _generateShareLink(String patientId) async {
    setState(() => _isGeneratingLink = true);
    try {
      final repo = ref.read(reportsRepositoryProvider);
      final res = await repo.createReportShare(patientId: patientId);
      if (!mounted) return;
      setState(() {
        _shareUrl = res.url;
        _isGeneratingLink = false;
      });
      try {
        await Clipboard.setData(ClipboardData(text: res.url));
      } catch (_) {}
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.reportLinkCopied)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGeneratingLink = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _copyShareLink() async {
    final url = _shareUrl;
    if (url == null || url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.reportLinkCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summaryAsync = ref.watch(reportSummaryProvider);
    final selectedDays = ref.watch(reportDateRangeDaysProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.doctorReportTitle)),
      body: SafeArea(
        child: summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.reportLoadError,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: ElevatedButton.icon(
                      onPressed: () => ref.invalidate(reportSummaryProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.retry),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (summary) {
            if (summary == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(24),
                  child: Card(
                    key: const ValueKey('report_no_patient_card'),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            size: 52,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.reportNoPatientSelected,
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            final roundedPct = summary.adherenceRatePct.round();

            return RefreshIndicator(
              onRefresh: () => ref.refresh(reportSummaryProvider.future),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 48,
                                  ),
                                  child: OutlinedButton(
                                    key: ValueKey('report_range_${range}d'),
                                    style: OutlinedButton.styleFrom(
                                      padding:
                                          const EdgeInsetsDirectional.symmetric(
                                            horizontal: 8,
                                            vertical: 10,
                                          ),
                                      backgroundColor: selectedDays == range
                                          ? theme.colorScheme.primary
                                          : (isDark
                                                ? theme
                                                      .colorScheme
                                                      .surfaceContainerHighest
                                                : theme.colorScheme.surface),
                                      foregroundColor: selectedDays == range
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                      side: BorderSide(
                                        color: selectedDays == range
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outlineVariant,
                                      ),
                                    ),
                                    onPressed: () => ref
                                        .read(
                                          reportDateRangeDaysProvider.notifier,
                                        )
                                        .setDays(range),
                                    child: Text(
                                      l10n.reportRangeDays(range),
                                      textAlign: TextAlign.center,
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
                      color: theme.cardTheme.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: theme.colorScheme.onPrimaryContainer,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        summary.patientName,
                                        style: theme.textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: Text(
                                            '${summary.fromDate} → ${summary.toDate}',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ),
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
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    l10n.appName,
                                    style: TextStyle(
                                      color: theme
                                          .colorScheme
                                          .onSecondaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 28),
                            Row(
                              children: [
                                RepaintBoundary(
                                  child: SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CircularProgressIndicator(
                                          value:
                                              (summary.adherenceRatePct / 100)
                                                  .clamp(0.0, 1.0),
                                          strokeWidth: 8,
                                          backgroundColor: isDark
                                              ? theme
                                                    .colorScheme
                                                    .surfaceContainerHighest
                                              : Colors.grey.shade200,
                                          color: theme.colorScheme.primary,
                                        ),
                                        Center(
                                          child: Text(
                                            '$roundedPct%',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${l10n.reportAdherenceSummary(roundedPct)} '
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

                    // Secure QR Share Card
                    Card(
                      elevation: 0,
                      color: theme.cardTheme.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.share_rounded,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.secureShareTitle,
                                        style: theme.textTheme.titleLarge,
                                      ),
                                      Text(
                                        l10n.secureShareSubtitle,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: RepaintBoundary(
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
                                  child: _shareUrl != null
                                      ? Semantics(
                                          label: l10n.reportQrHint,
                                          child: CustomPaint(
                                            key: const ValueKey(
                                              'report_qr_code',
                                            ),
                                            size: const Size.square(168),
                                            painter: _QrCodePainter(
                                              data: _shareUrl!,
                                            ),
                                          ),
                                        )
                                      : Column(
                                          key: const ValueKey(
                                            'report_qr_placeholder',
                                          ),
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.qr_code_2_rounded,
                                              size: 112,
                                              color: const Color(
                                                0xFF0F2942,
                                              ).withValues(alpha: 0.3),
                                            ),
                                            const SizedBox(height: 6),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 220,
                                              ),
                                              child: Text(
                                                l10n.reportQrHint,
                                                style: const TextStyle(
                                                  color: Color(0xFF475569),
                                                  fontSize: 16,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsetsDirectional.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF451A03)
                                    : const Color(0xFFFFF8E1),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(
                                          0xFFB45309,
                                        ).withValues(alpha: 0.4)
                                      : const Color(0xFFFDE68A),
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        color: isDark
                                            ? const Color(0xFFFCD34D)
                                            : const Color(0xFFB45309),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          l10n.expiresIn24Hours,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: isDark
                                                    ? const Color(0xFFFCD34D)
                                                    : const Color(0xFFB45309),
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Directionality(
                                    textDirection: _shareUrl != null
                                        ? TextDirection.ltr
                                        : Directionality.of(context),
                                    child: Text(
                                      _shareUrl ?? l10n.expiresIn24HoursSub,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: isDark
                                                ? const Color(0xFFFDE68A)
                                                : null,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 52),
                              child: OutlinedButton.icon(
                                key: const ValueKey('generate_share_link_btn'),
                                onPressed: _isGeneratingLink
                                    ? null
                                    : () =>
                                          _generateShareLink(summary.patientId),
                                icon: _isGeneratingLink
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: theme.colorScheme.primary,
                                        ),
                                      )
                                    : const Icon(Icons.link_rounded),
                                label: Text(l10n.shareLinkButton),
                              ),
                            ),
                            if (_shareUrl != null) ...[
                              const SizedBox(height: 10),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                ),
                                child: TextButton.icon(
                                  key: const ValueKey('copy_share_link_btn'),
                                  onPressed: _copyShareLink,
                                  icon: const Icon(Icons.copy_rounded),
                                  label: Text(l10n.copyCodeButton),
                                ),
                              ),
                            ],
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
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: OutlinedButton.icon(
                        key: const ValueKey('preview_print_pdf_btn'),
                        onPressed: _isExportingPdf
                            ? null
                            : () => _exportPdf(
                                context,
                                summary,
                                printPreview: true,
                              ),
                        icon: _isExportingPdf
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : const Icon(Icons.print_rounded),
                        label: Text(l10n.reportPreviewPrintButton),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: ElevatedButton.icon(
                        key: const ValueKey('share_pdf_report_btn'),
                        onPressed: _isExportingPdf
                            ? null
                            : () => _exportPdf(
                                context,
                                summary,
                                printPreview: false,
                              ),
                        icon: _isExportingPdf
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.share_rounded),
                        label: Text(l10n.shareReportButton),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
