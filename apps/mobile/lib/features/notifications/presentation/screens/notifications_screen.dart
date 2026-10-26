import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/caregiver/data/caregiver_repository.dart';
import 'package:medliva/features/caregiver/domain/models/caregiver.dart';
import 'package:medliva/features/inventory/domain/models/inventory.dart';
import 'package:medliva/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/today_screen.dart';
import 'package:medliva/features/notifications/data/alerts_repository.dart';
import 'package:medliva/features/notifications/domain/models/alert.dart';
import 'package:medliva/features/vitals/domain/models/vital.dart';
import 'package:medliva/features/vitals/presentation/screens/vitals_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';

/// Alerts of the patient the app is currently showing (patient or caregiver
/// acting on behalf of a linked patient).
class AlertsNotifier extends AsyncNotifier<List<AlertModel>> {
  @override
  Future<List<AlertModel>> build() async {
    final patientId = ref.watch(currentPatientIdProvider);
    if (patientId == null || patientId.isEmpty) {
      return const [];
    }
    final repo = ref.watch(alertsRepositoryProvider);
    return await repo.listAlerts(patientId);
  }
}

final alertsNotifierProvider =
    AsyncNotifierProvider<AlertsNotifier, List<AlertModel>>(AlertsNotifier.new);

/// The caregivers monitoring the current patient.
final patientCaregiversProvider =
    FutureProvider<List<LinkedCaregiverModel>>((ref) {
  final patientId = ref.watch(currentPatientIdProvider);
  if (patientId == null || patientId.isEmpty) {
    return Future.value(const []);
  }
  return ref.watch(caregiverRepositoryProvider).listPatientCaregivers(patientId);
});

/// A single row of the notification centre.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.category,
    required this.bgColor,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.timeLabel,
    required this.body,
    required this.subBody,
  });

  final String id;
  final String category;
  final Color bgColor;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String timeLabel;
  final String body;
  final String subBody;
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final alertsAsync = ref.watch(alertsNotifierProvider);
    final caregiversAsync = ref.watch(patientCaregiversProvider);
    final dosesAsync = ref.watch(todayDosesNotifierProvider);
    final inventoryAsync = ref.watch(inventoryForecastProvider);
    final vitalsAsync = ref.watch(vitalsNotifierProvider);

    final items = _buildItems(
      l10n: l10n,
      alerts: alertsAsync.value ?? const [],
      caregivers: caregiversAsync.value ?? const [],
      doses: dosesAsync.value ?? const [],
      inventory: inventoryAsync.value ?? const [],
      vitals: vitalsAsync.value ?? const [],
    );

    final filtered = _selectedFilter == 'all'
        ? items
        : items.where((item) => item.category == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFF00796B),
                  size: 24,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.appName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF00796B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  for (final tab in [
                    (id: 'all', label: l10n.filterAll),
                    (id: 'medications', label: l10n.filterMedications),
                    (id: 'caregivers', label: l10n.filterCaregivers),
                    (id: 'alerts', label: l10n.filterAlerts),
                  ])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: SizedBox(
                        height: 48,
                        child: ChoiceChip(
                          key: ValueKey('notif_filter_${tab.id}'),
                          label: Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _selectedFilter == tab.id
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          selected: _selectedFilter == tab.id,
                          selectedColor: const Color(0xFF00695C),
                          backgroundColor: Colors.grey.shade200,
                          onSelected: (_) =>
                              setState(() => _selectedFilter = tab.id),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(l10n)
                  : ListView.separated(
                      padding: const EdgeInsetsDirectional.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            switch (item.category) {
                              case 'medications':
                                unawaited(context.push('/medications'));
                              case 'alerts':
                                unawaited(context.push('/vitals'));
                              case 'caregivers':
                                unawaited(context.push('/caregiver/pairing-code'));
                              default:
                                unawaited(context.push('/inventory'));
                            }
                          },
                          child: Container(
                            key: ValueKey('notif_card_${item.id}'),
                            padding: const EdgeInsetsDirectional.all(18),
                            decoration: BoxDecoration(
                              color: item.bgColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: item.iconColor,
                                  child: Icon(
                                    item.icon,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                color: item.iconColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            item.timeLabel,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.body,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.subBody,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right_rounded, size: 24),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 56,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.notifEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.notifEmptySub,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the notification list: real API alerts first, then the cards
  /// derived from the live medication, inventory and vitals data.
  List<NotificationItem> _buildItems({
    required AppLocalizations l10n,
    required List<AlertModel> alerts,
    required List<LinkedCaregiverModel> caregivers,
    required List<TodayDoseModel> doses,
    required List<MedicationForecastModel> inventory,
    required List<VitalReadingModel> vitals,
  }) {
    final items = <NotificationItem>[
      for (final alert in alerts) _alertItem(alert, l10n),
    ];

    final nextDose = doses
        .where((d) => d.status == 'pending' || d.status == 'snoozed')
        .firstOrNull;
    if (nextDose != null) {
      items.add(
        NotificationItem(
          id: 'next_dose',
          category: 'medications',
          bgColor: const Color(0xFFEBF5FF),
          iconColor: const Color(0xFF1E88E5),
          icon: Icons.medication_rounded,
          title: l10n.notifDoseTimeTitle,
          timeLabel: nextDose.timeOfDay,
          body: l10n.notifDoseBody(nextDose.medicationName),
          subBody: l10n.notifDoseSub(nextDose.timeOfDay),
        ),
      );
    }

    final lowStockItem = inventory.where((i) => i.isUnderSevenDays).firstOrNull;
    if (lowStockItem != null) {
      items.add(
        NotificationItem(
          id: 'low_stock_${lowStockItem.medicationId}',
          category: 'medications',
          bgColor: const Color(0xFFFFF8E1),
          iconColor: const Color(0xFFF59E0B),
          icon: Icons.medication_liquid_rounded,
          title: l10n.notifLowStockTitle,
          timeLabel: l10n.daysLeftLabel(lowStockItem.daysRemaining),
          body: l10n.notifLowStockBody(lowStockItem.name),
          subBody: l10n.notifLowStockSub(lowStockItem.daysRemaining),
        ),
      );
    }

    final abnormalVital =
        vitals.where((v) => v.band != 'normal').firstOrNull ??
        (vitals.isNotEmpty ? vitals.first : null);
    if (abnormalVital != null) {
      final value = abnormalVital.valueSecondary != null
          ? '${abnormalVital.valuePrimary.toInt()}/'
              '${abnormalVital.valueSecondary!.toInt()}'
          : abnormalVital.valuePrimary.toInt().toString();
      items.add(
        NotificationItem(
          id: 'vital_${abnormalVital.id}',
          category: 'alerts',
          bgColor: const Color(0xFFFFEBEE),
          iconColor: const Color(0xFFE53935),
          icon: Icons.favorite_rounded,
          title: l10n.notifHighVitalTitle,
          timeLabel: _relativeTime(l10n, abnormalVital.recordedAt),
          body: l10n.notifHighVitalBody(value),
          subBody: l10n.alertCaregiversNotified,
        ),
      );
    }

    if (caregivers.isNotEmpty) {
      final names = caregivers
          .map((c) => c.displayName)
          .where((name) => name.isNotEmpty)
          .join('، ');
      items.add(
        NotificationItem(
          id: 'caregivers',
          category: 'caregivers',
          bgColor: const Color(0xFFE6F7F1),
          iconColor: const Color(0xFF00897B),
          icon: Icons.chat_bubble_rounded,
          title: l10n.notifCaregiverMsgTitle,
          timeLabel: l10n.notifCaregiverMonitorSub,
          body: l10n.notifCaregiversBody(
            names.isEmpty ? l10n.notifCaregiverMonitorSub : names,
          ),
          subBody: l10n.notifCaregiverMonitorSub,
        ),
      );
    }

    return items;
  }

  NotificationItem _alertItem(AlertModel alert, AppLocalizations l10n) {
    final timeLabel = _relativeTime(l10n, alert.createdAt);

    switch (alert.type) {
      case 'sos':
        final note = alert.note;
        return NotificationItem(
          id: 'alert_${alert.id}',
          category: 'alerts',
          bgColor: const Color(0xFFFFEBEE),
          iconColor: const Color(0xFFE53935),
          icon: Icons.emergency_rounded,
          title: l10n.alertSosTitle,
          timeLabel: timeLabel,
          body: note != null && note.isNotEmpty
              ? l10n.alertSosNote(note)
              : l10n.alertSosBody,
          subBody: l10n.alertCaregiversNotified,
        );
      case 'critical_vital':
        final primary = alert.vitalValuePrimary;
        final secondary = alert.vitalValueSecondary;
        final value = primary == null
            ? ''
            : secondary == null
                ? primary.toInt().toString()
                : '${primary.toInt()}/${secondary.toInt()}';
        return NotificationItem(
          id: 'alert_${alert.id}',
          category: 'alerts',
          bgColor: const Color(0xFFFFEBEE),
          iconColor: const Color(0xFFE53935),
          icon: Icons.favorite_rounded,
          title: l10n.alertCriticalVitalTitle,
          timeLabel: timeLabel,
          body: l10n.alertVitalReading(value),
          subBody: l10n.alertCaregiversNotified,
        );
      case 'low_stock':
        return NotificationItem(
          id: 'alert_${alert.id}',
          category: 'medications',
          bgColor: const Color(0xFFFFF8E1),
          iconColor: const Color(0xFFF59E0B),
          icon: Icons.medication_liquid_rounded,
          title: l10n.alertLowStockTitle,
          timeLabel: timeLabel,
          body: l10n.alertLowStockBody(alert.medicationName ?? ''),
          subBody: l10n.alertCaregiversNotified,
        );
      case 'missed_dose':
        return NotificationItem(
          id: 'alert_${alert.id}',
          category: 'medications',
          bgColor: const Color(0xFFFFF8E1),
          iconColor: const Color(0xFFF59E0B),
          icon: Icons.schedule_rounded,
          title: l10n.alertMissedDoseTitle,
          timeLabel: timeLabel,
          body: l10n.alertMissedDoseBody(alert.medicationName ?? ''),
          subBody: alert.timeOfDay ?? '',
        );
      case 'expiry':
        return NotificationItem(
          id: 'alert_${alert.id}',
          category: 'medications',
          bgColor: const Color(0xFFFFF8E1),
          iconColor: const Color(0xFFF59E0B),
          icon: Icons.event_busy_rounded,
          title: l10n.alertExpiryTitle,
          timeLabel: timeLabel,
          body: l10n.alertExpiryBody(alert.medicationName ?? ''),
          subBody: '',
        );
      default:
        return NotificationItem(
          id: 'alert_${alert.id}',
          category: 'alerts',
          bgColor: const Color(0xFFE8EAF6),
          iconColor: const Color(0xFF3949AB),
          icon: Icons.notifications_active_rounded,
          title: l10n.notificationsTitle,
          timeLabel: timeLabel,
          body: l10n.alertGenericBody,
          subBody: '',
        );
    }
  }

  String _relativeTime(AppLocalizations l10n, DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt.toLocal());
    if (diff.isNegative || diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    return l10n.timeDaysAgo(diff.inDays);
  }
}
