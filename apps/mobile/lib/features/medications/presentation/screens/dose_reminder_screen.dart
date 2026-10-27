import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/today_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';

class DoseReminderScreen extends ConsumerWidget {
  const DoseReminderScreen({this.dose, super.key});

  final TodayDoseModel? dose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dosesAsync = ref.watch(todayDosesNotifierProvider);
    final doses = dosesAsync.value ?? const [];
    final activeDose = dose?.isActionable == true
        ? dose
        : doses.where((d) => d.isActionable).firstOrNull;

    if (activeDose == null) {
      return Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: dosesAsync.isLoading
              ? const Center(child: CircularProgressIndicator())
              : dosesAsync.hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.errorOccurred),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(todayDosesNotifierProvider),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.event_available_rounded,
                          size: 64,
                          color: Color(0xFF00796B),
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

    final medName = activeDose.medicationName;
    final timeStr = activeDose.timeOfDay;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 64,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.timeForMedicationTitle,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: const Color(0xFF0F2942),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE0F7F4), Color(0xFFB2DFDB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.medication_rounded,
                        size: 92,
                        color: Color(0xFF00796B),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                medName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF0F2942),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.timeAt(timeStr),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsetsDirectional.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  l10n.timeForMedicationTip,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 64,
                child: ElevatedButton.icon(
                  key: const ValueKey('reminder_take_btn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    await ref
                        .read(todayDosesNotifierProvider.notifier)
                        .logDose(dose: activeDose, status: 'taken');
                    if (context.mounted) {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/patient');
                      }
                    }
                  },
                  icon: const Icon(Icons.check_rounded, size: 32),
                  label: Text(
                    l10n.tookItButton,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 64,
                child: ElevatedButton.icon(
                  key: const ValueKey('reminder_snooze_btn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    await ref
                        .read(todayDosesNotifierProvider.notifier)
                        .logDose(dose: activeDose, status: 'snoozed');
                    if (context.mounted) {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/patient');
                      }
                    }
                  },
                  icon: const Icon(Icons.access_time_rounded, size: 30),
                  label: Text(
                    l10n.snoozeButton,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
