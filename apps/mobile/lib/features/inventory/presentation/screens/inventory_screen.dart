import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/inventory/data/inventory_repository.dart';
import 'package:medliva/features/inventory/domain/models/inventory.dart';
import 'package:medliva/l10n/app_localizations.dart';

final inventoryForecastProvider =
    FutureProvider<List<MedicationForecastModel>>((ref) {
  final patientId = ref.watch(currentPatientIdProvider);
  if (patientId == null || patientId.isEmpty) {
    return Future.value(const []);
  }
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getForecast(patientId);
});

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  Future<void> _requestRefill(
    BuildContext context,
    WidgetRef ref,
    MedicationForecastModel item,
  ) async {
    final patientId = ref.read(currentPatientIdProvider);
    if (patientId == null) return;
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final res = await repo.createRefillOrder(
        patientId: patientId,
        medicationName: item.name,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.messageText),
        ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final forecastAsync = ref.watch(inventoryForecastProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navInventoryComm),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_rounded,
                        color: Color(0xFF00796B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.currentInventoryHeader,
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/medications'),
                    child: Text(l10n.manageMedicationsLink),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              forecastAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(err.toString(), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(inventoryForecastProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (items) => ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isWarning = item.isUnderSevenDays;

                    return Card(
                      key: ValueKey('inventory_card_${item.medicationId}'),
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: isWarning
                              ? Colors.red.shade600
                              : Colors.grey.shade200,
                          width: isWarning ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isWarning
                                        ? Colors.red.shade50
                                        : const Color(0xFFE0F2F1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    isWarning
                                        ? Icons.warning_amber_rounded
                                        : Icons.medication_liquid_rounded,
                                    color: isWarning
                                        ? Colors.red.shade800
                                        : const Color(0xFF00796B),
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      if (isWarning)
                                        Text(
                                          l10n.lowStockWarning,
                                          key: ValueKey(
                                            'low_stock_warn_${item.medicationId}',
                                          ),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: Colors.red.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      Text(
                                        l10n.daysLeftLabel(item.daysRemaining),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isWarning
                                                  ? Colors.red.shade800
                                                  : Colors.teal.shade800,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                key: ValueKey(
                                  'refill_btn_${item.medicationId}',
                                ),
                                onPressed: () =>
                                    _requestRefill(context, ref, item),
                                icon: const Icon(
                                  Icons.shopping_cart_checkout_rounded,
                                ),
                                label: Text(l10n.refillOrderButton),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Remote Adjust Doses Button
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0F2FE),
                    foregroundColor: const Color(0xFF0369A1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => context.push('/medications'),
                  icon: const Icon(Icons.settings_suggest_rounded),
                  label: Text(
                    l10n.remoteAdjustDosesButton,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Communication Section (Image 2 Screen 3)
              Row(
                children: [
                  const Icon(
                    Icons.chat_outlined,
                    color: Color(0xFF00796B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.communicationHeader,
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Message Pharmacy Button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD1FAE5),
                    foregroundColor: const Color(0xFF065F46),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final items = forecastAsync.value ?? const [];
                    final lowStockMeds = items.where((i) => i.isUnderSevenDays).toList();
                    final names = lowStockMeds.isNotEmpty
                        ? lowStockMeds.map((m) => m.name).join('، ')
                        : (items.isNotEmpty ? items.first.name : 'الأدوية');
                    final msg =
                        'السلام عليكم، أود طلب إعادة صرف أدوية من الصيدلية: $names. شكراً جزيلاً.';
                    await Clipboard.setData(ClipboardData(text: msg));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تجهيز ونسخ رسالة طلب الصيدلية إلى الحافظة بنجاح'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: Text(l10n.messagePharmacyButton),
                ),
              ),
              const SizedBox(height: 14),

              // Voice Message from Grandchildren Card
              Container(
                padding: const EdgeInsetsDirectional.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF5FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.family_restroom_rounded,
                          color: Color(0xFF1D4ED8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.voiceMessageGrandchildrenTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF1E3A8A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFF2563EB),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (final h in <double>[
                                10,
                                20,
                                14,
                                26,
                                18,
                                24,
                                12,
                                22,
                                16,
                                28,
                                14,
                                18,
                              ])
                                Container(
                                  width: 4,
                                  height: h,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '0:28',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.voiceMessageGrandchildrenQuote,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Red Urgent Call Button
              SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => context.push('/emergency/sos'),
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 28),
                  label: Text(l10n.callNowUrgentButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
