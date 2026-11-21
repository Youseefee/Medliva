import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/today_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';

class DoseReminderScreen extends ConsumerStatefulWidget {
  const DoseReminderScreen({this.dose, super.key});

  final TodayDoseModel? dose;

  @override
  ConsumerState<DoseReminderScreen> createState() => _DoseReminderScreenState();
}

class _DoseReminderScreenState extends ConsumerState<DoseReminderScreen> {
  bool _isSubmitting = false;

  Future<void> _logAndClose(TodayDoseModel activeDose, String status) async {
    if (_isSubmitting) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSubmitting = true);
    try {
      final synced = await ref
          .read(todayDosesNotifierProvider.notifier)
          .logDose(dose: activeDose, status: status);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (!synced) {
        messenger?.showSnackBar(
          SnackBar(content: Text(l10n.doseLoggedOffline)),
        );
      } else if (status == 'snoozed') {
        messenger?.showSnackBar(
          SnackBar(content: Text(l10n.doseSnoozedSuccess)),
        );
      }
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        GoRouter.maybeOf(context)?.go('/patient');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dosesAsync = ref.watch(todayDosesNotifierProvider);
    final doses = dosesAsync.value ?? const [];

    TodayDoseModel? activeDose;
    if (widget.dose != null) {
      final refreshed = doses
          .where((d) => d.scheduleId == widget.dose!.scheduleId)
          .firstOrNull;
      final candidate = refreshed ?? widget.dose!;
      if (candidate.isActionable) activeDose = candidate;
    }
    activeDose ??= doses.where((d) => d.isActionable).firstOrNull;

    if (activeDose == null) {
      return Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: dosesAsync.isLoading
              ? const Center(child: CircularProgressIndicator())
              : dosesAsync.hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.errorOccurred,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(todayDosesNotifierProvider),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noPendingDose,
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => context.push('/medications'),
                          child: Text(l10n.manageMedicationsLink),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      );
    }

    final currentDose = activeDose;
    final medName = currentDose.medicationName;
    final timeStr = currentDose.timeOfDay;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 32).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: Icon(
                          Icons.notifications_active_rounded,
                          size: 48,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.timeForMedicationTitle,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 124,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? const [Color(0xFF134E4A), Color(0xFF042F2E)]
                                : const [Color(0xFFE0F7F4), Color(0xFFB2DFDB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.35 : 0.08,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.medication_rounded,
                              size: 56,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        medName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.timeAt(timeStr),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsetsDirectional.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? theme.colorScheme.surfaceContainerHigh
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          l10n.timeForMedicationTip,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 60,
                        child: ElevatedButton.icon(
                          key: const ValueKey('reminder_take_btn'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF0D9488)
                                : const Color(0xFF00796B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () => _logAndClose(currentDose, 'taken'),
                          icon: _isSubmitting
                              ? const SizedBox.square(
                                  dimension: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 30),
                          label: Text(
                            l10n.tookItButton,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                key: const ValueKey('reminder_snooze_btn'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? const Color(0xFF0284C7)
                                      : const Color(0xFF0288D1),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _logAndClose(
                                        currentDose,
                                        'snoozed',
                                      ),
                                icon: const Icon(
                                  Icons.access_time_rounded,
                                  size: 24,
                                ),
                                label: Text(
                                  l10n.snoozeButton,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: OutlinedButton.icon(
                                key: const ValueKey('reminder_skip_btn'),
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _logAndClose(
                                        currentDose,
                                        'skipped',
                                      ),
                                icon: const Icon(Icons.close_rounded, size: 22),
                                label: Text(l10n.skipDoseButton),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
