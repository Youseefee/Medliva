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
import 'package:medliva/l10n/app_localizations.dart';

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
        if (location == '/splash' || location == '/login') {
          return null;
        }
        return '/splash';
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
        if (user.isCaregiver && location == '/patient') {
          return '/caregiver';
        }
        if (!user.isCaregiver && location == '/caregiver') {
          return '/patient';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _MedlivaSplashScreen(),
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
      // Must appear BEFORE /medications/:id so "reminder" is not matched as :id.
      GoRoute(
        path: '/medications/reminder',
        builder: (context, state) {
          final dose = state.extra is TodayDoseModel
              ? state.extra! as TodayDoseModel
              : null;
          return DoseReminderScreen(dose: dose);
        },
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
        path: '/vitals/trends',
        builder: (context, state) => const VitalsTrendsScreen(),
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
        path: '/emergency/sos',
        builder: (context, state) => const SosEmergencyScreen(),
      ),
    ],
  );
});

class _MedlivaSplashScreen extends StatelessWidget {
  const _MedlivaSplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appName = AppLocalizations.of(context)?.appName ?? 'Medliva';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 46,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                appName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
