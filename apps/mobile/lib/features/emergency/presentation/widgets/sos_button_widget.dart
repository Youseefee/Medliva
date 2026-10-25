import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medliva/features/emergency/data/emergency_repository.dart';
import 'package:medliva/l10n/app_localizations.dart';

abstract class SosLocationService {
  Future<({double lat, double lng})?> tryGetCoordinates();
}

class GeolocatorSosLocationService implements SosLocationService {
  @override
  Future<({double lat, double lng})?> tryGetCoordinates() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition();
        return (lat: pos.latitude, lng: pos.longitude);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

final sosLocationServiceProvider = Provider<SosLocationService>((ref) {
  return GeolocatorSosLocationService();
});

class SosButtonWidget extends ConsumerStatefulWidget {
  const SosButtonWidget({super.key});

  @override
  ConsumerState<SosButtonWidget> createState() => _SosButtonWidgetState();
}

class _SosButtonWidgetState extends ConsumerState<SosButtonWidget> {
  bool _isSending = false;

  Future<void> _openConfirmAndSend() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.sosConfirmTitle),
        content: Text(l10n.sosConfirmBody),
        actions: [
          SizedBox(
            height: 48,
            child: TextButton(
              key: const ValueKey('sos_cancel_btn'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelButton),
            ),
          ),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              key: const ValueKey('sos_confirm_send_btn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.sos_rounded),
              label: Text(l10n.sosConfirmSendButton),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSending = true);
    try {
      final locService = ref.read(sosLocationServiceProvider);
      final coords = await locService.tryGetCoordinates();
      final repo = ref.read(emergencyRepositoryProvider);
      await repo.triggerSos(lat: coords?.lat, lng: coords?.lng);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.sosSentMessage)),
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

    return Semantics(
      button: true,
      enabled: !_isSending,
      label: l10n.sosButtonLabel,
      onLongPress: _isSending ? null : _openConfirmAndSend,
      child: GestureDetector(
        key: const ValueKey('sos_trigger_btn'),
        onLongPress: _isSending ? null : _openConfirmAndSend,
        child: Container(
          height: 60,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade800,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sos_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                l10n.sosButtonLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
