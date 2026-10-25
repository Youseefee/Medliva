import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/vitals/presentation/screens/vitals_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';

class VitalsTrendsScreen extends ConsumerStatefulWidget {
  const VitalsTrendsScreen({super.key});

  @override
  ConsumerState<VitalsTrendsScreen> createState() =>
      _VitalsTrendsScreenState();
}

class _VitalsTrendsScreenState extends ConsumerState<VitalsTrendsScreen> {
  String _activeTab = 'bp';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vitals = ref.watch(vitalsNotifierProvider).value ?? const [];

    final bpNormal =
        vitals.where((v) => v.type == 'bp' && v.band == 'normal').length;
    final bpBorder =
        vitals.where((v) => v.type == 'bp' && v.band == 'borderline').length;
    final bpCrit =
        vitals.where((v) => v.type == 'bp' && v.band == 'critical').length;

    final gluNormal =
        vitals.where((v) => v.type == 'glucose' && v.band == 'normal').length;
    final gluBorder = vitals
        .where((v) => v.type == 'glucose' && v.band == 'borderline')
        .length;
    final gluCrit =
        vitals.where((v) => v.type == 'glucose' && v.band == 'critical').length;

    final bpReadings = vitals
        .where((v) => v.type == 'bp')
        .take(7)
        .toList()
        .reversed
        .toList();
    final bpPoints = bpReadings.length >= 2
        ? bpReadings
            .map((v) => ((v.valuePrimary - 80) / 140).clamp(0.15, 0.85))
            .toList()
        : const <double>[];

    final gluReadings = vitals
        .where((v) => v.type == 'glucose')
        .take(7)
        .toList()
        .reversed
        .toList();
    final gluPoints = gluReadings.length >= 2
        ? gluReadings
            .map((v) => ((v.valuePrimary - 60) / 220).clamp(0.15, 0.85))
            .toList()
        : const <double>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navTrends),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toggle Pills (ضغط الدم | سكر الدم)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        key: const ValueKey('trend_tab_bp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _activeTab == 'bp'
                              ? const Color(0xFF00796B)
                              : Colors.grey.shade200,
                          foregroundColor: _activeTab == 'bp'
                              ? Colors.white
                              : Colors.black87,
                          elevation: 0,
                        ),
                        onPressed: () => setState(() => _activeTab = 'bp'),
                        child: Text(l10n.vitalTypeBp),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        key: const ValueKey('trend_tab_glucose'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _activeTab == 'glucose'
                              ? const Color(0xFF00796B)
                              : Colors.grey.shade200,
                          foregroundColor: _activeTab == 'glucose'
                              ? Colors.white
                              : Colors.black87,
                          elevation: 0,
                        ),
                        onPressed: () => setState(() => _activeTab = 'glucose'),
                        child: Text(l10n.vitalTypeGlucose),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 7-Day trend of the selected metric only.
              if (_activeTab == 'bp')
                _TrendCard(
                  key: const ValueKey('trend_card_bp'),
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFFE53935),
                  title: l10n.bpLast7Days,
                  points: bpPoints,
                  normalCount: bpNormal,
                  borderlineCount: bpBorder,
                  criticalCount: bpCrit,
                  l10n: l10n,
                )
              else
                _TrendCard(
                  key: const ValueKey('trend_card_glucose'),
                  icon: Icons.water_drop_rounded,
                  iconColor: const Color(0xFFD32F2F),
                  title: l10n.glucoseLast7Days,
                  points: gluPoints,
                  normalCount: gluNormal,
                  borderlineCount: gluBorder,
                  criticalCount: gluCrit,
                  l10n: l10n,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.points,
    required this.normalCount,
    required this.borderlineCount,
    required this.criticalCount,
    required this.l10n,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<double> points;
  final int normalCount;
  final int borderlineCount;
  final int criticalCount;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (points.isEmpty)
              Container(
                height: 130,
                alignment: Alignment.center,
                padding: const EdgeInsetsDirectional.all(12),
                child: Text(
                  l10n.noVitalsRecorded,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: 130,
                child: CustomPaint(
                  painter: _SevenDayChartPainter(points: points),
                  child: const SizedBox.expand(),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CountBadge(
                    count: normalCount,
                    label: l10n.withinNormalCount,
                    bg: const Color(0xFFE8F5E9),
                    fg: const Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CountBadge(
                    count: borderlineCount,
                    label: l10n.slightlyHighCount,
                    bg: const Color(0xFFFFF8E1),
                    fg: const Color(0xFFB45309),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CountBadge(
                    count: criticalCount,
                    label: l10n.highCount,
                    bg: const Color(0xFFFFEBEE),
                    fg: const Color(0xFFC62828),
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
    required this.bg,
    required this.fg,
  });

  final int count;
  final String label;
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
              fontSize: 13,
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
  const _SevenDayChartPainter({required this.points});

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    // Background horizontal triage bands
    final redPaint = Paint()..color = const Color(0xFFFFEBEE);
    final yellowPaint = Paint()..color = const Color(0xFFFFF8E1);
    final greenPaint = Paint()..color = const Color(0xFFE8F5E9);

    canvas
      ..drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.33),
        redPaint,
      )
      ..drawRect(
        Rect.fromLTWH(0, size.height * 0.33, size.width, size.height * 0.33),
        yellowPaint,
      )
      ..drawRect(
        Rect.fromLTWH(0, size.height * 0.66, size.width, size.height * 0.34),
        greenPaint,
      );

    if (points.length < 2) return;

    final linePaint = Paint()
      ..color = const Color(0xFF00897B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final stepX = size.width / (points.length - 1);

    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height * (1 - points[i].clamp(0.1, 0.9));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final val = points[i];
      final y = size.height * (1 - val.clamp(0.1, 0.9));
      final dotColor = val >= 0.68
          ? const Color(0xFFE53935)
          : val >= 0.51
              ? const Color(0xFFF59E0B)
              : const Color(0xFF10B981);
      canvas.drawCircle(
        Offset(x, y),
        5.5,
        Paint()..color = dotColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SevenDayChartPainter oldDelegate) =>
      oldDelegate.points != points;
}
