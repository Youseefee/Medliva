import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/emergency/data/emergency_repository.dart';
import 'package:medliva/features/emergency/presentation/screens/contacts_screen.dart';
import 'package:medliva/features/emergency/presentation/widgets/sos_button_widget.dart';
import 'package:medliva/l10n/app_localizations.dart';

class SosEmergencyScreen extends ConsumerStatefulWidget {
  const SosEmergencyScreen({super.key});

  @override
  ConsumerState<SosEmergencyScreen> createState() => _SosEmergencyScreenState();
}

class _SosEmergencyScreenState extends ConsumerState<SosEmergencyScreen> {
  Timer? _holdTimer;
  double _holdProgress = 0;
  bool _isSending = false;
  ({double lat, double lng})? _coordinates;

  @override
  void initState() {
    super.initState();
    unawaited(_loadLocation());
  }

  Future<void> _loadLocation() async {
    final service = ref.read(sosLocationServiceProvider);
    final coords = await service.tryGetCoordinates();
    if (!mounted || coords == null) return;
    setState(() => _coordinates = coords);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHold() {
    if (_isSending) return;
    _holdTimer?.cancel();
    setState(() => _holdProgress = 0.05);
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _holdProgress += 1 / 30;
      });
      if (_holdProgress >= 1.0) {
        timer.cancel();
        unawaited(_triggerEmergency());
      }
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    if (_holdProgress < 1.0 && mounted) {
      setState(() => _holdProgress = 0.0);
    }
  }

  Future<void> _triggerEmergency() async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _holdProgress = 0.0;
    });
    try {
      final locService = ref.read(sosLocationServiceProvider);
      final coords = await locService.tryGetCoordinates();
      final repo = ref.read(emergencyRepositoryProvider);
      await repo.triggerSos(lat: coords?.lat, lng: coords?.lng);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.sosSentMessage),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final contactsAsync = ref.watch(emergencyContactsNotifierProvider);
    final contacts = contactsAsync.value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: Color(0xFF00796B),
              size: 26,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.appName,
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(0xFF00796B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.sosScreenTitle,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.sosScreenSubtitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Big Circular Hold-3-Seconds Button
              Center(
                child: GestureDetector(
                  key: const ValueKey('sos_hold_circle_btn'),
                  onTapDown: (_) => _startHold(),
                  onTapUp: (_) => _cancelHold(),
                  onTapCancel: _cancelHold,
                  onLongPress: _triggerEmergency,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.shade50,
                        ),
                      ),
                      Container(
                        width: 192,
                        height: 192,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.shade100,
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          // Determinate on purpose: an indeterminate spinner
                          // would imply the button is busy while it is idle.
                          value: _holdProgress,
                          strokeWidth: 8,
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      Container(
                        width: 168,
                        height: 168,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade500,
                              Colors.red.shade800,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.phone_in_talk_rounded,
                              color: Colors.white,
                              size: 54,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsetsDirectional.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                l10n.sosHold3Seconds,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Location Notice Banner
              Container(
                padding: const EdgeInsetsDirectional.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  l10n.sosLocationSharingNotice,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 14),

              // Current Location Share Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: Colors.red.shade700,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.currentLocationShareTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _coordinates != null
                                  ? l10n.locationCoordinatesLabel(
                                      _coordinates!.lat.toStringAsFixed(4),
                                      _coordinates!.lng.toStringAsFixed(4),
                                    )
                                  : l10n.locationUnavailable,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Caregivers Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.caregiversSectionTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const EmergencyContactsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(l10n.addContactButton),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Caregivers List
              if (contacts.isEmpty) ...[
                Container(
                  key: const ValueKey('sos_no_contacts'),
                  padding: const EdgeInsetsDirectional.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    l10n.noEmergencyContacts,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else
                for (final contact in contacts)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 10),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFE0F2F1),
                          child: Icon(
                            Icons.person_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          contact.relationship != null &&
                                  contact.relationship!.isNotEmpty
                              ? '${contact.name} - ${contact.relationship}'
                              : contact.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(contact.phone),
                        trailing: CircleAvatar(
                          backgroundColor: Colors.green.shade700,
                          child: IconButton(
                            icon: const Icon(
                              Icons.phone_rounded,
                              color: Colors.white,
                            ),
                            onPressed: _triggerEmergency,
                          ),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 12),

              // Call Now Bottom Red CTA
              SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  key: const ValueKey('sos_call_now_btn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _isSending ? null : _triggerEmergency,
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 28),
                  label: Text(
                    l10n.callNowButton,
                    style: const TextStyle(
                      fontSize: 22,
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
