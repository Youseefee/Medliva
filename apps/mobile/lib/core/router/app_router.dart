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
          final med =
              state.extra as MedicationModel? ??
              MedicationModel(
                id: state.pathParameters['id'] ?? '',
                patientId: '',
                name: '',
              );
          return MedicationDetailScreen(medication: med);
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
        builder: (context, state) => const DoseReminderScreen(),
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
