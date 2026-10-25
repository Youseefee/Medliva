import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/vitals/data/vitals_repository.dart';
import 'package:medliva/features/vitals/domain/models/vital.dart';
import 'package:medliva/features/vitals/presentation/screens/vitals_screen.dart';
import 'package:medliva/l10n/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart';

abstract class SpeechCaptureService {
  Future<String?> captureTranscript({required String localeId});
}

class DeviceSpeechCaptureService implements SpeechCaptureService {
  DeviceSpeechCaptureService({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;

  @override
  Future<String?> captureTranscript({required String localeId}) async {
    try {
      final available = await _speech.initialize();
      if (!available) return null;

      var captured = '';
      await _speech.listen(
        listenOptions: SpeechListenOptions(localeId: localeId),
        onResult: (result) {
          captured = result.recognizedWords;
        },
      );
      await Future<void>.delayed(const Duration(seconds: 3));
      await _speech.stop();
      return captured.trim().isEmpty ? null : captured.trim();
    } catch (_) {
      return null;
    }
  }
}

final speechCaptureServiceProvider = Provider<SpeechCaptureService>((ref) {
  return DeviceSpeechCaptureService();
});

class VoiceVitalConfirmDialog extends ConsumerStatefulWidget {
  const VoiceVitalConfirmDialog({
    required this.parseResult,
    super.key,
  });

  final VoiceVitalsParseResult parseResult;

  @override
  ConsumerState<VoiceVitalConfirmDialog> createState() =>
      _VoiceVitalConfirmDialogState();
}

class _VoiceVitalConfirmDialogState
    extends ConsumerState<VoiceVitalConfirmDialog> {
  late final TextEditingController _primaryController;
  late final TextEditingController _secondaryController;
  late String _selectedType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.parseResult.type;
    _primaryController = TextEditingController(
      text: widget.parseResult.valuePrimary.toInt().toString(),
    );
    _secondaryController = TextEditingController(
      text: widget.parseResult.valueSecondary?.toInt().toString() ?? '',
    );
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSave() async {
    final primaryVal = double.tryParse(_primaryController.text.trim());
    if (primaryVal == null) return;
    final secondaryVal = _selectedType == 'bp'
        ? double.tryParse(_secondaryController.text.trim())
        : null;

    setState(() => _isSaving = true);
    try {
      await ref.read(vitalsNotifierProvider.notifier).addVital(
            VitalCreateInput(
              type: _selectedType,
              valuePrimary: primaryVal,
              valueSecondary: secondaryVal,
              mealContext: widget.parseResult.mealContext,
              rawTranscript: widget.parseResult.transcript,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.voiceVitalConfirmTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.parseResult.transcript,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('voice_confirm_primary_field'),
              controller: _primaryController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.vitalValuePrimaryLabel,
              ),
            ),
            if (_selectedType == 'bp') ...[
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('voice_confirm_secondary_field'),
                controller: _secondaryController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.vitalValueSecondaryLabel,
                ),
              ),
            ],
            if (widget.parseResult.messageAr.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.parseResult.messageAr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        SizedBox(
          height: 48,
          child: TextButton(
            key: const ValueKey('voice_confirm_cancel_btn'),
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
        ),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            key: const ValueKey('voice_confirm_save_btn'),
            onPressed: _isSaving ? null : _confirmAndSave,
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.confirmSaveButton),
          ),
        ),
      ],
    );
  }
}

Future<void> startVoiceVitalEntryFlow({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  try {
    final locale = Localizations.localeOf(context).languageCode;
    final localeId = locale == 'en' ? 'en_US' : 'ar_EG';
    final speechService = ref.read(speechCaptureServiceProvider);
    final transcript = await speechService.captureTranscript(localeId: localeId);
    if (!context.mounted) return;
    if (transcript == null || transcript.isEmpty) {
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.voiceVitalSubtitle),
          ),
        );
      }
      return;
    }

    final repo = ref.read(vitalsRepositoryProvider);
    final parsed = await repo.parseVoiceVitals(transcript);
    if (!context.mounted) return;

    await showDialog<bool>(
      context: context,
      builder: (_) => VoiceVitalConfirmDialog(parseResult: parsed),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class VoiceVitalsScreen extends ConsumerStatefulWidget {
  const VoiceVitalsScreen({super.key});

  @override
  ConsumerState<VoiceVitalsScreen> createState() => _VoiceVitalsScreenState();
}

class _VoiceVitalsScreenState extends ConsumerState<VoiceVitalsScreen> {
  bool _isListening = false;
  String _lastTranscript = '" الضغط النهارده 135 على 85 "';

  Future<void> _onMicTap() async {
    setState(() => _isListening = true);
    try {
      await startVoiceVitalEntryFlow(context: context, ref: ref);
    } finally {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final vitalsAsync = ref.watch(vitalsNotifierProvider);
    final vitals = vitalsAsync.value ?? const [];
    final latestBp =
        vitals.where((v) => v.type == 'bp').firstOrNull ??
        (vitals.isNotEmpty ? vitals.first : null);

    if (latestBp?.rawTranscript != null &&
        latestBp!.rawTranscript!.isNotEmpty) {
      _lastTranscript = '" ${latestBp.rawTranscript} "';
    }

    final displayReading = latestBp != null
        ? (latestBp.valueSecondary != null
              ? '${latestBp.valuePrimary.toInt()} / ${latestBp.valueSecondary!.toInt()}'
              : '${latestBp.valuePrimary.toInt()}')
        : '135 / 85';

    final isNormal = latestBp == null || latestBp.band == 'normal';

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
                l10n.voiceVitalTitle,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: const Color(0xFF0F2942),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.voiceVitalSubtitle,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Big Teal Microphone Button + Sound Waves
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      key: const ValueKey('voice_screen_mic_btn'),
                      onTap: _isListening ? null : _onMicTap,
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE0F2F1),
                          border: Border.all(
                            color: const Color(0xFFB2DFDB),
                            width: 10,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 128,
                            height: 128,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF26A69A), Color(0xFF00796B)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Icon(
                              _isListening
                                  ? Icons.graphic_eq_rounded
                                  : Icons.mic_rounded,
                              size: 68,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Sound Wave Bars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final h in <double>[
                          12,
                          22,
                          34,
                          18,
                          40,
                          26,
                          16,
                          36,
                          28,
                          14,
                          24,
                          12,
                        ])
                          Container(
                            width: 4,
                            height: h,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00897B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.pressAndSpeak,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F2942),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Transcript Bubble
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7F4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _lastTranscript,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF004D40),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 18),

              // Logged Reading Card
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF5FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.monitor_heart_rounded,
                          color: Color(0xFF1E88E5),
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.vitalLoggedSuccess,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              l10n.vitalTypeBp,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayReading,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: const Color(0xFF0F2942),
                              ),
                            ),
                            Text(
                              l10n.unitMmHg,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFF10B981),
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Reassuring Status Card
              Container(
                padding: const EdgeInsetsDirectional.all(18),
                decoration: BoxDecoration(
                  color: isNormal
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: isNormal
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFF59E0B),
                      child: Icon(
                        isNormal
                            ? Icons.sentiment_satisfied_alt_rounded
                            : Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isNormal
                                ? l10n.reassuringStatusTitle
                                : l10n.triageBorderline,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: isNormal
                                  ? const Color(0xFF1B5E20)
                                  : const Color(0xFFB45309),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.reassuringStatusSub,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
