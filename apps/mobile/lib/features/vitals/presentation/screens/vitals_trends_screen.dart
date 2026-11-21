import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/vitals/domain/models/vital.dart';
import 'package:medliva/features/vitals/presentation/screens/vitals_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';

class _ChartPoint {
  const _ChartPoint({
    required this.normalizedY,
    required this.band,
    required this.valueLabel,
    required this.dateLabel,
  });

  final double normalizedY;
  final String band;
  final String valueLabel;
  final String dateLabel;
}

class VitalsTrendsScreen extends ConsumerStatefulWidget {
  const VitalsTrendsScreen({
    this.embedded = false,
    this.referenceDate,
    super.key,
  });

  final bool embedded;
  final DateTime? referenceDate;

  @override
  ConsumerState<VitalsTrendsScreen> createState() => _VitalsTrendsScreenState();
}

class _VitalsTrendsScreenState extends ConsumerState<VitalsTrendsScreen> {
  String _activeTab = 'bp';

  List<_ChartPoint> _buildPoints(
    List<VitalReadingModel> readings,
    String type,
  ) {
    final ordered = readings.take(7).toList().reversed.toList();
    return ordered.map((v) {
      final double norm;
      final String valLabel;
      if (type == 'bp') {
        norm = ((v.valuePrimary - 70) / 140).clamp(0.12, 0.88);
        valLabel = v.valueSecondary != null
            ? '${v.valuePrimary.toInt()}/${v.valueSecondary!.toInt()}'
            : '${v.valuePrimary.toInt()}';
      } else if (type == 'glucose') {
        norm = ((v.valuePrimary - 50) / 260).clamp(0.12, 0.88);
        valLabel = '${v.valuePrimary.toInt()}';
      } else {
        norm = ((v.valuePrimary - 40) / 100).clamp(0.12, 0.88);
        valLabel = '${v.valuePrimary.toInt()}';
      }
      final local = v.recordedAt.toLocal();
      final dateLabel = '${local.day}/${local.month}';
      return _ChartPoint(
        normalizedY: norm,
        band: v.band,
        valueLabel: valLabel,
        dateLabel: dateLabel,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final vitalsAsync = ref.watch(vitalsNotifierProvider);

    final refNow = (widget.referenceDate ?? DateTime.now()).toLocal();
    final cutoff = refNow.subtract(const Duration(days: 7));

    final body = SafeArea(
      child: vitalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  err.toString(),
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(vitalsNotifierProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (allVitals) {
          final recentVitals = allVitals
              .where((v) => !v.recordedAt.toLocal().isBefore(cutoff))
              .toList();

          final bpRecent =
              recentVitals.where((v) => v.type == 'bp').toList();
          final gluRecent =
              recentVitals.where((v) => v.type == 'glucose').toList();
          final pulseRecent =
              recentVitals.where((v) => v.type == 'pulse').toList();

          final activeList = _activeTab == 'bp'
              ? bpRecent
              : (_activeTab == 'glucose' ? gluRecent : pulseRecent);
          final normalCount =
              activeList.where((v) => v.band == 'normal').length;
          final borderCount =
              activeList.where((v) => v.band == 'borderline').length;
          final critCount =
              activeList.where((v) => v.band == 'critical').length;
          final points = _buildPoints(activeList, _activeTab);

          final String title;
          final IconData icon;
          final Color iconColor;
          final String yHighLabel;
          final String yLowLabel;
          final Key cardKey;
          if (_activeTab == 'bp') {
            title = l10n.bpLast7Days;
            icon = Icons.favorite_rounded;
            iconColor = const Color(0xFFE53935);
            yHighLabel = '200';
            yLowLabel = '80';
            cardKey = const ValueKey('trend_card_bp');
          } else if (_activeTab == 'glucose') {
            title = l10n.glucoseLast7Days;
            icon = Icons.water_drop_rounded;
            iconColor = const Color(0xFFD32F2F);
            yHighLabel = '300';
            yLowLabel = '60';
            cardKey = const ValueKey('trend_card_glucose');
          } else {
            title = '${l10n.vitalTypePulse} (${l10n.reportRangeDays(7)})';
            icon = Icons.monitor_heart_rounded;
            iconColor = theme.colorScheme.primary;
            yHighLabel = '140';
            yLowLabel = '40';
            cardKey = const ValueKey('trend_card_pulse');
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vitalsNotifierProvider);
              await ref.read(vitalsNotifierProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsetsDirectional.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tab in [
                        (
                          id: 'bp',
                          key: const ValueKey('trend_tab_bp'),
                          label: l10n.vitalTypeBp,
                        ),
                        (
                          id: 'glucose',
                          key: const ValueKey('trend_tab_glucose'),
                          label: l10n.vitalTypeGlucose,
                        ),
                        (
                          id: 'pulse',
                          key: const ValueKey('trend_tab_pulse'),
                          label: l10n.vitalPulseTab,
                        ),
                      ])
                        Semantics(
                          selected: _activeTab == tab.id,
                          button: true,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              key: tab.key,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                backgroundColor: _activeTab == tab.id
                                    ? const Color(0xFF00796B)
                                    : (isDark
                                        ? theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                        : Colors.grey.shade200),
                                foregroundColor: _activeTab == tab.id
                                    ? Colors.white
                                    : (isDark
                                        ? theme.colorScheme.onSurface
                                        : Colors.black87),
                                elevation: 0,
                              ),
                              onPressed: () =>
                                  setState(() => _activeTab = tab.id),
                              icon: Icon(
                                _activeTab == tab.id
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                size: 18,
                              ),
                              label: Text(tab.label),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _TrendCard(
                    key: cardKey,
                    icon: icon,
                    iconColor: iconColor,
                    title: title,
                    points: points,
                    yHighLabel: yHighLabel,
                    yLowLabel: yLowLabel,
                    normalCount: normalCount,
                    borderlineCount: borderCount,
                    criticalCount: critCount,
                    l10n: l10n,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (widget.embedded) {
      return Scaffold(body: body);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTrends)),
      body: body,
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.points,
    required this.yHighLabel,
    required this.yLowLabel,
    required this.normalCount,
    required this.borderlineCount,
    required this.criticalCount,
    required this.l10n,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<_ChartPoint> points;
  final String yHighLabel;
  final String yLowLabel;
  final int normalCount;
  final int borderlineCount;
  final int criticalCount;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isDark ? Colors.red.shade300 : iconColor,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (points.isEmpty)
              Container(
                height: 150,
                alignment: Alignment.center,
                padding: const EdgeInsetsDirectional.all(12),
                child: Text(
                  l10n.noVitalsRecorded,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              )
            else
              Directionality(
                textDirection: TextDirection.ltr,
                child: RepaintBoundary(
                  child: SizedBox(
                    height: 170,
                    child: CustomPaint(
                      painter: _SevenDayChartPainter(
                        points: points,
                        isDark: isDark,
                        yHighLabel: yHighLabel,
                        yLowLabel: yLowLabel,
                        labelColor: theme.colorScheme.onSurface,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CountBadge(
                    count: normalCount,
                    label: l10n.withinNormalCount,
                    icon: Icons.check_circle_rounded,
                    bg: isDark
                        ? const Color(0xFF064E3B).withValues(alpha: 0.5)
                        : const Color(0xFFE8F5E9),
                    fg: isDark
                        ? const Color(0xFF6EE7B7)
                        : const Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CountBadge(
                    count: borderlineCount,
                    label: l10n.slightlyHighCount,
                    icon: Icons.warning_amber_rounded,
                    bg: isDark
                        ? const Color(0xFF451A03).withValues(alpha: 0.5)
                        : const Color(0xFFFFF8E1),
                    fg: isDark
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFFB45309),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CountBadge(
                    count: criticalCount,
                    label: l10n.highCount,
                    icon: Icons.dangerous_rounded,
                    bg: isDark
                        ? const Color(0xFF450A0A).withValues(alpha: 0.5)
                        : const Color(0xFFFFEBEE),
                    fg: isDark
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFFC62828),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  final int count;
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: 10,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              color: fg,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SevenDayChartPainter extends CustomPainter {
  const _SevenDayChartPainter({
    required this.points,
    required this.isDark,
    required this.yHighLabel,
    required this.yLowLabel,
    required this.labelColor,
  });

  final List<_ChartPoint> points;
  final bool isDark;
  final String yHighLabel;
  final String yLowLabel;
  final Color labelColor;

  Color _dotColorForBand(String band) {
    switch (band) {
      case 'critical':
        return isDark ? Colors.red.shade300 : const Color(0xFFE53935);
      case 'borderline':
        return isDark ? Colors.amber.shade300 : const Color(0xFFF59E0B);
      default:
        return isDark ? Colors.green.shade300 : const Color(0xFF10B981);
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset, {
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
    bool centerX = true,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: labelColor,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = centerX ? offset.dx - painter.width / 2 : offset.dx;
    painter.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 36.0;
    const rightPad = 16.0;
    const topPad = 18.0;
    const bottomPad = 24.0;
    final chartWidth = (size.width - leftPad - rightPad).clamp(
      10.0,
      double.infinity,
    );
    final chartHeight = (size.height - topPad - bottomPad).clamp(
      10.0,
      double.infinity,
    );

    final redPaint = Paint()
      ..color = isDark
          ? const Color(0xFF450A0A).withValues(alpha: 0.45)
          : const Color(0xFFFFEBEE);
    final yellowPaint = Paint()
      ..color = isDark
          ? const Color(0xFF451A03).withValues(alpha: 0.45)
          : const Color(0xFFFFF8E1);
    final greenPaint = Paint()
      ..color = isDark
          ? const Color(0xFF064E3B).withValues(alpha: 0.45)
          : const Color(0xFFE8F5E9);

    canvas
      ..drawRect(
        Rect.fromLTWH(leftPad, topPad, chartWidth, chartHeight * 0.33),
        redPaint,
      )
      ..drawRect(
        Rect.fromLTWH(
          leftPad,
          topPad + chartHeight * 0.33,
          chartWidth,
          chartHeight * 0.33,
        ),
        yellowPaint,
      )
      ..drawRect(
        Rect.fromLTWH(
          leftPad,
          topPad + chartHeight * 0.66,
          chartWidth,
          chartHeight * 0.34,
        ),
        greenPaint,
      );

    // Y-axis reference labels
    _paintText(canvas, yHighLabel, const Offset(2, topPad), centerX: false);
    _paintText(
      canvas,
      yLowLabel,
      Offset(2, topPad + chartHeight - 14),
      centerX: false,
    );

    if (points.isEmpty) return;

    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? leftPad + chartWidth / 2
          : leftPad + (i * chartWidth / (points.length - 1));
      final y = topPad + chartHeight * (1 - points[i].normalizedY);
      offsets.add(Offset(x, y));
    }

    if (offsets.length >= 2) {
      final linePaint = Paint()
        ..color = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF00897B)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (var i = 1; i < offsets.length; i++) {
        path.lineTo(offsets[i].dx, offsets[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final pos = offsets[i];
      canvas.drawCircle(
        pos,
        6,
        Paint()..color = _dotColorForBand(point.band),
      );
      _paintText(
        canvas,
        point.valueLabel,
        Offset(pos.dx, (pos.dy - 18).clamp(0.0, topPad + chartHeight - 14)),
      );
      _paintText(
        canvas,
        point.dateLabel,
        Offset(pos.dx, topPad + chartHeight + 6),
        fontWeight: FontWeight.normal,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SevenDayChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.isDark != isDark ||
      oldDelegate.yHighLabel != yHighLabel ||
      oldDelegate.yLowLabel != yLowLabel;
}
