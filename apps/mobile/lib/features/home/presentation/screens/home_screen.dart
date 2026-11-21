import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medliva/core/theme/app_theme.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/auth/presentation/screens/profile_screen.dart';
import 'package:medliva/features/caregiver/presentation/screens/caregiver_dashboard_screen.dart';
import 'package:medliva/features/emergency/presentation/screens/sos_emergency_screen.dart';
import 'package:medliva/features/emergency/presentation/widgets/sos_button_widget.dart';
import 'package:medliva/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:medliva/features/medications/presentation/screens/dose_reminder_screen.dart';
import 'package:medliva/features/medications/presentation/screens/medication_list_screen.dart';
import 'package:medliva/features/medications/presentation/screens/today_screen.dart';
import 'package:medliva/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:medliva/features/prescription/presentation/screens/prescription_scan_screen.dart';
import 'package:medliva/features/reports/presentation/screens/doctor_report_screen.dart';
import 'package:medliva/features/vitals/presentation/screens/vitals_screen.dart';
import 'package:medliva/features/vitals/presentation/screens/vitals_trends_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:medliva/main.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  final Set<int> _visitedTabs = {0};

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
      _visitedTabs.add(index);
    });
  }

  void _pushOrNavigate(
    BuildContext context,
    String route,
    WidgetBuilder fallbackBuilder, {
    Object? extra,
  }) {
    if (GoRouter.maybeOf(context) != null) {
      unawaited(context.push(route, extra: extra));
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: fallbackBuilder),
      );
    }
  }

  Future<void> _confirmLogout(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            key: const ValueKey('confirm_logout_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              minimumSize: const Size(120, 48),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.logoutButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await ref.read(authNotifierProvider.notifier).logout();
    if (context.mounted && GoRouter.maybeOf(context) != null) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final alertsCount = ref.watch(alertsNotifierProvider).value?.length ?? 0;

    final user = authState.value;
    final userName = (user?.name != null && user!.name!.trim().isNotEmpty)
        ? user.name!.trim()
        : (user?.email != null && user!.email!.trim().isNotEmpty)
            ? user.email!.trim()
            : (user?.phone != null && user!.phone!.trim().isNotEmpty)
                ? user.phone!.trim()
                : l10n.greetingFallbackName;
    final isCaregiver = user?.isCaregiver ?? false;
    final roleName = isCaregiver ? l10n.roleCaregiver : l10n.rolePatient;
    final shellTitle = isCaregiver
        ? switch (_selectedIndex) {
            1 => l10n.todayDosesTitle,
            2 => l10n.navTrends,
            3 => l10n.inventoryTitle,
            _ => l10n.caregiverShellTitle,
          }
        : switch (_selectedIndex) {
            1 => l10n.medicationsTitle,
            2 => l10n.vitalsTitle,
            3 => l10n.navMore,
            _ => l10n.patientShellTitle,
          };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          shellTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          key: const ValueKey('open_notifications_button'),
          tooltip: l10n.notificationsTitle,
          icon: alertsCount > 0
              ? Badge.count(
                  count: alertsCount,
                  child: const Icon(Icons.notifications_rounded),
                )
              : const Icon(Icons.notifications_rounded),
          onPressed: () => _pushOrNavigate(
            context,
            '/notifications',
            (_) => const NotificationsScreen(),
          ),
        ),
        actions: [
          IconButton(
            key: const ValueKey('toggle_theme_button'),
            tooltip: isDark
                ? l10n.switchToLightTheme
                : l10n.switchToDarkTheme,
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: () => ref
                .read(themeModeProvider.notifier)
                .toggle(isCurrentlyDark: isDark),
          ),
          IconButton(
            key: const ValueKey('open_medications_button'),
            tooltip: l10n.medicationsTitle,
            icon: const Icon(Icons.medication_rounded),
            onPressed: () => _pushOrNavigate(
              context,
              '/medications',
              (_) => const MedicationListScreen(),
            ),
          ),
          IconButton(
            key: const ValueKey('open_profile_button'),
            tooltip: l10n.profileTitle,
            icon: const Icon(Icons.person_rounded),
            onPressed: () => _pushOrNavigate(
              context,
              '/profile',
              (_) => const ProfileScreen(),
            ),
          ),
          IconButton(
            key: const ValueKey('logout_action_button'),
            tooltip: l10n.logoutButton,
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _confirmLogout(context, l10n),
          ),
        ],
      ),
      body: SafeArea(
        child: isCaregiver
            ? _buildCaregiverTabBody(context, l10n, theme, userName, roleName)
            : _buildPatientTabBody(context, l10n, theme, userName, roleName),
      ),
      bottomNavigationBar: NavigationBar(
        key: const ValueKey('main_bottom_nav'),
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: isCaregiver
            ? [
                NavigationDestination(
                  icon: const Icon(Icons.home_rounded),
                  label: l10n.navHome,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.schedule_rounded),
                  label: l10n.navTimeline,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.bar_chart_rounded),
                  label: l10n.navVitals,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.inventory_2_rounded),
                  label: l10n.navInventoryComm,
                ),
              ]
            : [
                NavigationDestination(
                  icon: const Icon(Icons.home_rounded),
                  label: l10n.navHome,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.medication_rounded),
                  label: l10n.navMedications,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.monitor_heart_rounded),
                  label: l10n.navVitals,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.more_horiz_rounded),
                  label: l10n.navMore,
                ),
              ],
      ),
    );
  }

  Widget _buildPatientTabBody(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    String userName,
    String roleName,
  ) {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        _buildPatientHomeTab(context, l10n, theme, userName, roleName),
        if (_visitedTabs.contains(1))
          const MedicationListScreen(embedded: true)
        else
          const SizedBox.shrink(),
        if (_visitedTabs.contains(2))
          const VitalsScreen(embedded: true)
        else
          const SizedBox.shrink(),
        if (_visitedTabs.contains(3))
          _buildPatientMoreHub(context, l10n, theme)
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildCaregiverTabBody(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    String userName,
    String roleName,
  ) {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGreetingCard(l10n, theme, userName, roleName),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 54),
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/caregiver/pair'),
                        icon: const Icon(Icons.link_rounded),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            l10n.pairPatientTitle,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 54),
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/reports/doctor'),
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            l10n.doctorReportTitle,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Expanded(child: CaregiverDashboardScreen()),
            ],
          ),
        ),
        if (_visitedTabs.contains(1))
          const TodayScreen(readOnly: true)
        else
          const SizedBox.shrink(),
        if (_visitedTabs.contains(2))
          const VitalsTrendsScreen(embedded: true)
        else
          const SizedBox.shrink(),
        if (_visitedTabs.contains(3))
          const InventoryScreen(embedded: true)
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildGreetingCard(
    AppLocalizations l10n,
    ThemeData theme,
    String userName,
    String roleName,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF134E4A), Color(0xFF0F172A)]
              : const [Color(0xFFE0F7F4), Color(0xFFEFFBF9)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCCFBF1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wb_sunny_rounded,
            size: 46,
            color: isDark ? AppTheme.darkWarningColor : const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.goodMorning} — ${l10n.welcomeUser(userName)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : const Color(0xFF0F2942),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.goodMorningGreeting,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : const Color(0xFF334155),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.userRoleLabel(roleName),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientHomeTab(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    String userName,
    String roleName,
  ) {
    final dosesAsync = ref.watch(todayDosesNotifierProvider);
    final doses = dosesAsync.value ?? const [];
    final totalCount = doses.length;
    final takenCount = doses.where((d) => d.status == 'taken').length;
    final adherencePct =
        totalCount > 0 ? ((takenCount / totalCount) * 100).round() : 0;
    final nextDose = doses.where((d) => d.isActionable).firstOrNull;

    final cardBgColor =
        theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow;
    final cardBorderColor = theme.colorScheme.outlineVariant;

    final nextDoseCard = InkWell(
      key: const ValueKey('open_dose_reminder_card'),
      borderRadius: BorderRadius.circular(18),
      onTap: () => _pushOrNavigate(
        context,
        '/medications/reminder',
        (_) => DoseReminderScreen(dose: nextDose),
        extra: nextDose,
      ),
      child: Container(
        padding: const EdgeInsetsDirectional.all(14),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medication_rounded,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.todayMedicationCardTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (nextDose != null)
              Text(
                nextDose.medicationName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else if (dosesAsync.isLoading && !dosesAsync.hasValue)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                dosesAsync.hasError ? l10n.errorOccurred : l10n.noPendingDose,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (nextDose != null)
              Text(
                l10n.timeAt(nextDose.timeOfDay),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );

    final adherenceCard = Container(
      padding: const EdgeInsetsDirectional.all(14),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorderColor),
      ),
      child: Row(
        children: [
          if (totalCount > 0)
            SizedBox(
              width: 54,
              height: 54,
              child: RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: (adherencePct / 100).clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: theme.colorScheme.primary,
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$adherencePct%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              fontFamily: AppTheme.fontFamily,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (dosesAsync.isLoading && !dosesAsync.hasValue)
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              Icons.event_busy_rounded,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.weeklyAdherenceTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (totalCount > 0)
                  Text(
                    l10n.weeklyAdherenceSub(takenCount, totalCount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  )
                else if (!(dosesAsync.isLoading && !dosesAsync.hasValue))
                  Text(
                    dosesAsync.hasError
                        ? l10n.errorOccurred
                        : l10n.noDosesToday,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (totalCount > 0 && takenCount > 0)
                  Text(
                    l10n.weeklyAdherenceKeepUp,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Morning Greeting Card
          _buildGreetingCard(l10n, theme, userName, roleName),
          const SizedBox(height: 12),

          // 2. Today's Medication Highlight Card + Daily Adherence Row
          LayoutBuilder(
            builder: (context, constraints) {
              final stackVertically = constraints.maxWidth < 300;
              if (stackVertically) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    nextDoseCard,
                    const SizedBox(height: 10),
                    adherenceCard,
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: nextDoseCard),
                    const SizedBox(width: 10),
                    Expanded(child: adherenceCard),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // 3. Today's Interactive Doses List
          const Expanded(child: TodayScreen()),
          const SizedBox(height: 12),

          // 4. Red Emergency SOS Bar
          const SosButtonWidget(),
        ],
      ),
    );
  }

  Widget _buildPatientMoreHub(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor =
        theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow;
    final cardBorderColor = theme.colorScheme.outlineVariant;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    final items =
        <({IconData icon, Color color, String title, VoidCallback onTap})>[
          (
            icon: Icons.document_scanner_rounded,
            color: const Color(0xFF0284C7),
            title: l10n.scanPrescriptionTitle,
            onTap: () => _pushOrNavigate(
              context,
              '/prescription/scan',
              (_) => const PrescriptionScanScreen(),
            ),
          ),
          (
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFFF59E0B),
            title: l10n.timeForMedicationTitle,
            onTap: () => _pushOrNavigate(
              context,
              '/medications/reminder',
              (_) => const DoseReminderScreen(),
            ),
          ),
          (
            icon: Icons.sos_rounded,
            color: const Color(0xFFDC2626),
            title: l10n.sosScreenTitle,
            onTap: () => _pushOrNavigate(
              context,
              '/emergency/sos',
              (_) => const SosEmergencyScreen(),
            ),
          ),
          (
            icon: Icons.show_chart_rounded,
            color: const Color(0xFF7C3AED),
            title: l10n.navTrends,
            onTap: () => _pushOrNavigate(
              context,
              '/vitals/trends',
              (_) => const VitalsTrendsScreen(),
            ),
          ),
          (
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF0D9488),
            title: l10n.navInventoryComm,
            onTap: () => _pushOrNavigate(
              context,
              '/inventory',
              (_) => const InventoryScreen(),
            ),
          ),
          (
            icon: Icons.picture_as_pdf_rounded,
            color: const Color(0xFF2563EB),
            title: l10n.doctorReportTitle,
            onTap: () => _pushOrNavigate(
              context,
              '/reports/doctor',
              (_) => const DoctorReportScreen(),
            ),
          ),
          (
            icon: Icons.notifications_rounded,
            color: const Color(0xFFEA580C),
            title: l10n.notificationsTitle,
            onTap: () => _pushOrNavigate(
              context,
              '/notifications',
              (_) => const NotificationsScreen(),
            ),
          ),
          (
            icon: Icons.qr_code_rounded,
            color: const Color(0xFF00796B),
            title: l10n.pairingCodeTitle,
            onTap: () => context.push('/caregiver/pairing-code'),
          ),
          (
            icon: Icons.settings_rounded,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            title: l10n.settingsTitle,
            onTap: () => _pushOrNavigate(
              context,
              '/profile',
              (_) => const ProfileScreen(),
            ),
          ),
        ];

    return GridView.builder(
      padding: const EdgeInsetsDirectional.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: (148 * textScale).clamp(148.0, 210.0),
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 0,
          color: cardBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: cardBorderColor),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: item.onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: item.color.withValues(
                      alpha: isDark ? 0.22 : 0.14,
                    ),
                    child: Icon(item.icon, color: item.color, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: Text(
                      item.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
