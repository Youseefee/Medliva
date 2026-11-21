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
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return await _tryGetLastKnown();
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            timeLimit: Duration(seconds: 4),
          ),
        );
        return (lat: pos.latitude, lng: pos.longitude);
      }
      return await _tryGetLastKnown();
    } catch (_) {
      return await _tryGetLastKnown();
    }
  }

  Future<({double lat, double lng})?> _tryGetLastKnown() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return (lat: last.latitude, lng: last.longitude);
      }
    } catch (_) {}
    return null;
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

  void _showHoldHint() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.sosHoldHint),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _openConfirmAndSend() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.sosConfirmTitle),
        content: Text(l10n.sosConfirmBody),
        actions: [
          TextButton(
            key: const ValueKey('sos_cancel_btn'),
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton.icon(
            key: const ValueKey('sos_confirm_send_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.sos_rounded),
            label: Text(l10n.sosConfirmSendButton),
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
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.sosSentMessage),
            backgroundColor: Colors.green.shade700,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
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

    return Semantics(
      button: true,
      enabled: !_isSending,
      label: l10n.sosButtonLabel,
      onLongPress: _isSending ? null : _openConfirmAndSend,
      child: GestureDetector(
        key: const ValueKey('sos_trigger_btn'),
        onTap: _isSending ? null : _showHoldHint,
        onLongPress: _isSending ? null : _openConfirmAndSend,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: _isSending
                ? Colors.red.shade800.withValues(alpha: 0.65)
                : Colors.red.shade800,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSending)
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              else
                const Icon(Icons.sos_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  l10n.sosButtonLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
