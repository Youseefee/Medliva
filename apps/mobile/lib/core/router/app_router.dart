import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/auth/presentation/screens/email_password_screen.dart';
import 'package:medliva/features/auth/presentation/screens/profile_screen.dart';
import 'package:medliva/features/caregiver/presentation/screens/pairing_screens.dart';
import 'package:medliva/features/emergency/presentation/screens/contacts_screen.dart';
import 'package:medliva/features/emergency/presentation/screens/sos_emergency_screen.dart';
import 'package:medliva/features/home/presentation/screens/home_screen.dart';
import 'package:medliva/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/dose_reminder_screen.dart';
import 'package:medliva/features/medications/presentation/screens/medication_detail_screen.dart';
import 'package:medliva/features/medications/presentation/screens/medication_form_screen.dart';
import 'package:medliva/features/medications/presentation/screens/medication_list_screen.dart';
import 'package:medliva/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:medliva/features/prescription/presentation/screens/prescription_scan_screen.dart';
import 'package:medliva/features/reports/presentation/screens/doctor_report_screen.dart';
import 'package:medliva/features/vitals/presentation/screens/vitals_screen.dart';
import 'package:medliva/features/vitals/presentation/screens/vitals_trends_screen.dart';
import 'package:medliva/features/vitals/presentation/screens/voice_vital_entry.dart';

final _routerRefreshProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref
    ..listen(authNotifierProvider, (_, _) {
      notifier.value++;
    })
    ..onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.value != null;
      final location = state.matchedLocation;

      if (isLoading) {
        return location == '/splash' ? null : '/splash';
      }

      final isAuthRoute = location == '/login';

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (isAuthenticated) {
        final user = authState.value!;
        final targetShell = user.isCaregiver ? '/caregiver' : '/patient';
        if (isAuthRoute || location == '/splash' || location == '/home') {
          return targetShell;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const EmailPasswordScreen(),
      ),
      GoRoute(
        path: '/patient',
        builder: (context, state) =>
            const HomeScreen(key: ValueKey('patient_shell')),
      ),
      GoRoute(
        path: '/caregiver',
        builder: (context, state) =>
            const HomeScreen(key: ValueKey('caregiver_shell')),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/medications',
        builder: (context, state) => const MedicationListScreen(),
      ),
      GoRoute(
        path: '/medications/new',
        builder: (context, state) => const MedicationFormScreen(),
      ),
      GoRoute(
        path: '/medications/:id',
        builder: (context, state) {
          // Never show a detail screen for an empty placeholder
          // medication: if the caller did not pass one via `extra`
          // (deep link / page refresh), load it by id, or show a
          // not-found error if it cannot be loaded.
          final med = state.extra as MedicationModel?;
          if (med != null) {
            return MedicationDetailScreen(medication: med);
          }
          return MedicationDetailLoader(
            medicationId: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/medications/:id/edit',
        builder: (context, state) {
          final med = state.extra as MedicationModel?;
          return MedicationFormScreen(existingMedication: med);
        },
      ),
      GoRoute(
        path: '/caregiver/pairing-code',
        builder: (context, state) => const PatientPairingCodeScreen(),
      ),
      GoRoute(
        path: '/caregiver/pair',
        builder: (context, state) => const CaregiverPairScreen(),
      ),
      GoRoute(
        path: '/vitals',
        builder: (context, state) => const VitalsScreen(),
      ),
      GoRoute(
        path: '/prescription/scan',
        builder: (context, state) => const PrescriptionScanScreen(),
      ),
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const EmergencyContactsScreen(),
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: '/reports/doctor',
        builder: (context, state) => const DoctorReportScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/medications/reminder',
        builder: (context, state) {
          // The home dose card passes its next dose via `extra`; the
          // More hub navigates without one, in which case the screen
          // falls back to the first pending dose as before.
          final dose = state.extra as TodayDoseModel?;
          return DoseReminderScreen(dose: dose);
        },
      ),
      GoRoute(
        path: '/vitals/voice',
        builder: (context, state) => const VoiceVitalsScreen(),
      ),
      GoRoute(
        path: '/vitals/trends',
        builder: (context, state) => const VitalsTrendsScreen(),
      ),
      GoRoute(
        path: '/emergency/sos',
        builder: (context, state) => const SosEmergencyScreen(),
      ),
    ],
  );
});

/// Loads a medication by id for deep links / refreshes of
/// `/medications/:id` where no [MedicationModel] was passed via `extra`.
/// Shows a loading indicator while fetching, the detail screen on
/// success, and a plain not-found error (never an empty placeholder
/// medication) when the id is missing or not found.
class MedicationDetailLoader extends ConsumerWidget {
  const MedicationDetailLoader({required this.medicationId, super.key});

  final String medicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (medicationId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('الدواء غير موجود')),
      );
    }
    final medsAsync = ref.watch(medicationsNotifierProvider);
    return medsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('تعذر تحميل الدواء: $error')),
      ),
      data: (meds) {
        final med = meds.where((m) => m.id == medicationId).firstOrNull;
        if (med == null) {
          return const Scaffold(
            body: Center(child: Text('الدواء غير موجود')),
          );
        }
        return MedicationDetailScreen(medication: med);
      },
    );
  }
}
