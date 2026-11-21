import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/emergency/data/emergency_repository.dart';
import 'package:medliva/features/emergency/domain/models/emergency.dart';
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
      final next = _holdProgress + (1 / 30);
      if (next >= 1.0) {
        timer.cancel();
        setState(() => _holdProgress = 1.0);
        unawaited(_triggerEmergency());
      } else {
        setState(() => _holdProgress = next);
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
      final freshCoords = await locService.tryGetCoordinates();
      final coords = freshCoords ?? _coordinates;
      if (freshCoords != null && mounted) {
        setState(() => _coordinates = freshCoords);
      }
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

  Future<void> _openContactCallDialog(EmergencyContactModel contact) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.sosContactCallTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.relationship != null &&
                      contact.relationship!.trim().isNotEmpty
                  ? '${contact.name} - ${contact.relationship!.trim()}'
                  : contact.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(contact.phone, style: theme.textTheme.bodyLarge),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancelButton),
          ),
          OutlinedButton.icon(
            key: ValueKey('sos_copy_phone_btn_${contact.id}'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => Navigator.of(dialogContext).pop('copy'),
            icon: const Icon(Icons.copy_rounded),
            label: Text(l10n.sosCopyPhone),
          ),
          ElevatedButton.icon(
            key: ValueKey('sos_contact_confirm_send_btn_${contact.id}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
            ),
            onPressed: () => Navigator.of(dialogContext).pop('sos'),
            icon: const Icon(Icons.sos_rounded),
            label: Text(l10n.sosConfirmSendButton),
          ),
        ],
      ),
    );

    if (!mounted || action == null) return;
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: contact.phone));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sosPhoneCopied)));
    } else if (action == 'sos') {
      await _triggerEmergency();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final contactsAsync = ref.watch(emergencyContactsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_rounded,
              color: theme.colorScheme.primary,
              size: 26,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.appName,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
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
                  color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.sosScreenSubtitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Big Circular Hold-3-Seconds Button
              Center(
                child: RepaintBoundary(
                  child: Semantics(
                    button: true,
                    enabled: !_isSending,
                    label: l10n.sosHold3Seconds,
                    child: GestureDetector(
                      key: const ValueKey('sos_hold_circle_btn'),
                      onTapDown: (_) => _startHold(),
                      onTapUp: (_) => _cancelHold(),
                      onTapCancel: _cancelHold,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.red.shade900.withValues(alpha: 0.25)
                                  : Colors.red.shade50,
                            ),
                          ),
                          Container(
                            width: 192,
                            height: 192,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.red.shade900.withValues(alpha: 0.45)
                                  : Colors.red.shade100,
                            ),
                          ),
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CircularProgressIndicator(
                              value: _isSending ? null : _holdProgress,
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
                                if (_isSending)
                                  const SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3.5,
                                    ),
                                  )
                                else
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
                ),
              ),
              const SizedBox(height: 20),

              // Location Notice Banner
              Container(
                padding: const EdgeInsetsDirectional.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF450A0A).withValues(alpha: 0.45)
                      : Colors.red.shade50,
                  border: Border.all(
                    color: isDark
                        ? Colors.red.shade800.withValues(alpha: 0.5)
                        : Colors.red.shade100,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  l10n.sosLocationSharingNotice,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.red.shade200 : Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 14),

              // Current Location Share Card
              Card(
                elevation: 0,
                color: theme.cardTheme.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 54,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                              : const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: isDark
                              ? Colors.red.shade300
                              : Colors.red.shade700,
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
                              style: theme.textTheme.bodyMedium,
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
                children: [
                  Expanded(
                    child: Text(
                      l10n.caregiversSectionTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
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
              contactsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsetsDirectional.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsetsDirectional.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.error),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        err.toString(),
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: OutlinedButton.icon(
                          onPressed: () => ref.invalidate(
                            emergencyContactsNotifierProvider,
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.retry),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (contacts) {
                  if (contacts.isEmpty) {
                    return Container(
                      key: const ValueKey('sos_no_contacts'),
                      padding: const EdgeInsetsDirectional.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5)
                            : Colors.grey.shade50,
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        l10n.noEmergencyContacts,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final contact in contacts)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(bottom: 10),
                          child: Card(
                            elevation: 0,
                            color: theme.cardTheme.color,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsetsDirectional.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: isDark
                                    ? const Color(
                                        0xFF064E3B,
                                      ).withValues(alpha: 0.35)
                                    : const Color(0xFFE0F2F1),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                contact.relationship != null &&
                                        contact.relationship!.trim().isNotEmpty
                                    ? '${contact.name} - ${contact.relationship!.trim()}'
                                    : contact.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    contact.phone,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                              trailing: SizedBox(
                                width: 48,
                                height: 48,
                                child: Material(
                                  color: _isSending
                                      ? theme.colorScheme.surfaceContainerHighest
                                      : (isDark
                                            ? Colors.green.shade800
                                            : Colors.green.shade700),
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    key: ValueKey(
                                      'sos_contact_call_btn_${contact.id}',
                                    ),
                                    tooltip: l10n.sosContactCallTitle,
                                    icon: const Icon(
                                      Icons.phone_rounded,
                                      color: Colors.white,
                                    ),
                                    onPressed: _isSending
                                        ? null
                                        : () => _openContactCallDialog(contact),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),

              // Call Now Bottom Red CTA
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
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
                  icon: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.phone_in_talk_rounded, size: 28),
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
