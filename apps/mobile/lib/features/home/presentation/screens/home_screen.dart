import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'package:medliva/features/vitals/presentation/screens/voice_vital_entry.dart';
import 'package:medliva/l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);

    final user = authState.value;
    final userName = user?.name ?? user?.email ?? user?.phone ?? 'عم أحمد';
    final isCaregiver = user?.isCaregiver ?? false;
    final roleName = isCaregiver ? l10n.roleCaregiver : l10n.rolePatient;
    final shellTitle = isCaregiver
        ? l10n.caregiverShellTitle
        : l10n.patientShellTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(shellTitle),
        leading: IconButton(
          key: const ValueKey('open_notifications_button'),
          tooltip: l10n.notificationsTitle,
          icon: const Icon(Icons.notifications_rounded),
          onPressed: () => context.push('/notifications'),
        ),
        actions: [
          IconButton(
            key: const ValueKey('open_medications_button'),
            tooltip: l10n.medicationsTitle,
            icon: const Icon(Icons.medication_rounded),
            onPressed: () => context.push('/medications'),
          ),
          IconButton(
            key: const ValueKey('open_profile_button'),
            tooltip: l10n.profileTitle,
            icon: const Icon(Icons.person_rounded),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            tooltip: l10n.logoutButton,
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
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
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
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
    switch (_selectedIndex) {
      case 1:
        return const MedicationListScreen();
      case 2:
        return const VitalsScreen();
      case 3:
        return _buildPatientMoreHub(context, l10n, theme);
      default:
        return _buildPatientHomeTab(context, l10n, theme, userName, roleName);
    }
  }

  Widget _buildCaregiverTabBody(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    String userName,
    String roleName,
  ) {
    switch (_selectedIndex) {
      case 1:
        return const TodayScreen(readOnly: true);
      case 2:
        return const VitalsTrendsScreen();
      case 3:
        return const InventoryScreen();
      default:
        return Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGreetingCard(l10n, theme, userName, roleName),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/caregiver/pair'),
                      icon: const Icon(Icons.link_rounded),
                      label: Text(l10n.pairPatientTitle),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/reports/doctor'),
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(l10n.doctorReportTitle),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Expanded(child: CaregiverDashboardScreen()),
            ],
          ),
        );
    }
  }

  Widget _buildGreetingCard(
    AppLocalizations l10n,
    ThemeData theme,
    String userName,
    String roleName,
  ) {
    return Container(
      padding: const EdgeInsetsDirectional.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F7F4), Color(0xFFEFFBF9)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wb_sunny_rounded,
            size: 52,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.goodMorning} — ${l10n.welcomeUser(userName)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF0F2942),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.goodMorningGreeting,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.userRoleLabel(roleName),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
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
    final doses = ref.watch(todayDosesNotifierProvider).value ?? const [];
    final totalCount = doses.isEmpty ? 7 : doses.length;
    final takenCount = doses.isEmpty
        ? 6
        : doses.where((d) => d.status == 'taken').length;
    final adherencePct = totalCount > 0
        ? ((takenCount / totalCount) * 100).round()
        : 85;
    final nextDose = doses.firstOrNull;

    return Padding(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Morning Greeting Card (Image 1 Screen 1)
          _buildGreetingCard(l10n, theme, userName, roleName),
          const SizedBox(height: 12),

          // 2. Today's Medication Highlight Card + Weekly Adherence Ring Row
          Row(
            children: [
              Expanded(
                child: InkWell(
                  key: const ValueKey('open_dose_reminder_card'),
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DoseReminderScreen(dose: nextDose),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsetsDirectional.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.medication_rounded,
                              color: Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                l10n.todayMedicationCardTitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 20),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          nextDose?.medicationName ?? 'أملوديبين 5 مجم',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          nextDose != null
                              ? 'الساعة ${nextDose.timeOfDay}'
                              : 'الساعة 8:00 صباحاً',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsetsDirectional.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: (adherencePct / 100).clamp(0.0, 1.0),
                              strokeWidth: 6,
                              backgroundColor: Colors.grey.shade200,
                              color: const Color(0xFF00796B),
                            ),
                            Center(
                              child: Text(
                                '$adherencePct%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.weeklyAdherenceSub(takenCount, totalCount),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              l10n.weeklyAdherenceKeepUp,
                              style: const TextStyle(
                                color: Color(0xFF00796B),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
    final items = <({
      IconData icon,
      Color color,
      String title,
      VoidCallback onTap,
    })>[
      (
        icon: Icons.mic_rounded,
        color: const Color(0xFF00897B),
        title: l10n.navVoiceVitals,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const VoiceVitalsScreen()),
        ),
      ),
      (
        icon: Icons.document_scanner_rounded,
        color: const Color(0xFF0284C7),
        title: l10n.scanPrescriptionTitle,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PrescriptionScanScreen(),
          ),
        ),
      ),
      (
        icon: Icons.notifications_active_rounded,
        color: const Color(0xFFF59E0B),
        title: l10n.timeForMedicationTitle,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const DoseReminderScreen()),
        ),
      ),
      (
        icon: Icons.sos_rounded,
        color: const Color(0xFFDC2626),
        title: l10n.sosScreenTitle,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SosEmergencyScreen()),
        ),
      ),
      (
        icon: Icons.show_chart_rounded,
        color: const Color(0xFF7C3AED),
        title: l10n.navTrends,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const VitalsTrendsScreen()),
        ),
      ),
      (
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFF0D9488),
        title: l10n.navInventoryComm,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const InventoryScreen()),
        ),
      ),
      (
        icon: Icons.picture_as_pdf_rounded,
        color: const Color(0xFF2563EB),
        title: l10n.doctorReportTitle,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const DoctorReportScreen()),
        ),
      ),
      (
        icon: Icons.notifications_rounded,
        color: const Color(0xFFEA580C),
        title: l10n.notificationsTitle,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
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
        color: const Color(0xFF475569),
        title: l10n.settingsTitle,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
        ),
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsetsDirectional.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade200),
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
                    backgroundColor: item.color.withValues(alpha: 0.14),
                    child: Icon(item.icon, color: item.color, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
