import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/inventory/data/inventory_repository.dart';
import 'package:medliva/features/inventory/domain/models/inventory.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:medliva/features/medications/presentation/screens/medication_list_screen.dart';
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

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({this.embedded = false, super.key});

  final bool embedded;

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final Set<String> _loadingRefillIds = <String>{};

  Future<void> _showUpdateStockDialog(MedicationForecastModel item) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: '${item.stockCount}');
    String? errorText;

    final updatedStock = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('${l10n.inventoryAddStockTitle} — ${item.name}'),
          content: TextField(
            key: ValueKey('update_stock_input_${item.medicationId}'),
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.medicationStockLabel,
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              key: ValueKey('confirm_update_stock_${item.medicationId}'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed == null || parsed < 0) {
                  setDialogState(() => errorText = l10n.invalidStockNumber);
                  return;
                }
                Navigator.of(dialogContext).pop(parsed);
              },
              child: Text(l10n.saveButton),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    if (updatedStock == null) return;
    try {
      await ref
          .read(medicationsNotifierProvider.notifier)
          .updateMedication(
            item.medicationId,
            MedicationUpdateInput(stockCount: updatedStock),
          );
      ref.invalidate(inventoryForecastProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.medicationSavedSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _requestRefill(MedicationForecastModel item) async {
    if (_loadingRefillIds.contains(item.medicationId)) return;
    final patientId = ref.read(currentPatientIdProvider);
    if (patientId == null) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _loadingRefillIds.add(item.medicationId));
    RefillOrderResult? res;
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      res = l10n.localeName == 'ar'
          ? await repo.createRefillOrder(
              patientId: patientId,
              medicationName: item.name,
            )
          : await repo.createRefillOrder(
              patientId: patientId,
              medicationName: item.name,
              locale: l10n.localeName,
            );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _loadingRefillIds.remove(item.medicationId));
      }
    }

    if (!mounted) return;
    final order = res;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_pharmacy_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.inventoryRefillSheetTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsetsDirectional.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: SelectableText(
                    order.messageText,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    key: ValueKey('copy_refill_msg_${item.medicationId}'),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: order.messageText),
                      );
                      if (!sheetContext.mounted) return;
                      Navigator.of(sheetContext).pop();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.inventoryCopiedMessage)),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(l10n.inventoryCopyMessage),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await _showUpdateStockDialog(item);
                    },
                    icon: const Icon(Icons.inventory_rounded),
                    label: Text(l10n.inventoryUpdateStock),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final chevronIcon =
        isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded;
    final forecastAsync = ref.watch(inventoryForecastProvider);

    final body = SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(inventoryForecastProvider);
          await ref.read(inventoryForecastProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.currentInventoryHeader,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/medications'),
                    child: Text(l10n.manageMedicationsLink),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              forecastAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsetsDirectional.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          err.toString(),
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () =>
                              ref.invalidate(inventoryForecastProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Card(
                      key: const ValueKey('inventory_empty_card'),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 56,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.inventoryEmptyTitle,
                              style: theme.textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.inventoryEmptySubtitle,
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    context.push('/medications/new'),
                                icon: const Icon(Icons.add_rounded),
                                label: Text(l10n.addMedicationTitle),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isWarning = item.isUnderSevenDays || item.isExpired;
                      final isUnscheduled = item.daysRemaining >= 999;
                      final isLoadingRefill =
                          _loadingRefillIds.contains(item.medicationId);

                      return Card(
                        key: ValueKey('inventory_card_${item.medicationId}'),
                        elevation: 0,
                        color: theme.cardTheme.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: isWarning
                                ? (isDark
                                    ? Colors.red.shade400
                                    : Colors.red.shade600)
                                : theme.colorScheme.outlineVariant,
                            width: isWarning ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => context.push(
                            '/medications/${item.medicationId}',
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
                                            ? (isDark
                                                ? Colors.red.shade900
                                                    .withValues(alpha: 0.35)
                                                : Colors.red.shade50)
                                            : (isDark
                                                ? const Color(0xFF064E3B)
                                                    .withValues(alpha: 0.35)
                                                : const Color(0xFFE0F2F1)),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        isWarning
                                            ? Icons.warning_amber_rounded
                                            : Icons.medication_liquid_rounded,
                                        color: isWarning
                                            ? (isDark
                                                ? Colors.red.shade300
                                                : Colors.red.shade800)
                                            : theme.colorScheme.primary,
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
                                          Text(
                                            l10n.medicationStockCount(
                                              item.stockCount,
                                            ),
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                          if (item.isUnderSevenDays)
                                            Text(
                                              l10n.lowStockWarning,
                                              key: ValueKey(
                                                'low_stock_warn_${item.medicationId}',
                                              ),
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: isDark
                                                        ? Colors.red.shade300
                                                        : Colors.red.shade800,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          Text(
                                            isUnscheduled
                                                ? l10n.medicationNoSchedule
                                                : l10n.daysLeftLabel(
                                                    item.daysRemaining,
                                                  ),
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: item.isUnderSevenDays
                                                      ? (isDark
                                                          ? Colors.red.shade300
                                                          : Colors.red.shade800)
                                                      : theme
                                                          .colorScheme
                                                          .primary,
                                                ),
                                          ),
                                          if (item.isExpired ||
                                              item.isExpiringSoon) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsetsDirectional.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: item.isExpired
                                                    ? (isDark
                                                        ? const Color(
                                                            0xFF450A0A,
                                                          )
                                                        : Colors.red.shade50)
                                                    : (isDark
                                                        ? const Color(
                                                            0xFF45220A,
                                                          )
                                                        : Colors.amber.shade50),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.event_busy_rounded,
                                                    size: 18,
                                                    color: item.isExpired
                                                        ? (isDark
                                                            ? Colors
                                                                .red
                                                                .shade300
                                                            : Colors
                                                                .red
                                                                .shade800)
                                                        : (isDark
                                                            ? Colors
                                                                .amber
                                                                .shade300
                                                            : Colors
                                                                .orange
                                                                .shade900),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    item.isExpired
                                                        ? l10n.expiredBadge
                                                        : l10n.expiringSoonBadge,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: item.isExpired
                                                          ? (isDark
                                                              ? Colors
                                                                  .red
                                                                  .shade300
                                                              : Colors
                                                                  .red
                                                                  .shade800)
                                                          : (isDark
                                                              ? Colors
                                                                  .amber
                                                                  .shade300
                                                              : Colors
                                                                  .orange
                                                                  .shade900),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Icon(chevronIcon),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 50,
                                        child: ElevatedButton.icon(
                                          key: ValueKey(
                                            'refill_btn_${item.medicationId}',
                                          ),
                                          onPressed: isLoadingRefill
                                              ? null
                                              : () => _requestRefill(item),
                                          icon: isLoadingRefill
                                              ? const SizedBox.square(
                                                  dimension: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons
                                                      .shopping_cart_checkout_rounded,
                                                ),
                                          label: Text(l10n.refillOrderButton),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      height: 50,
                                      child: OutlinedButton.icon(
                                        key: ValueKey(
                                          'update_stock_btn_${item.medicationId}',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 50),
                                        ),
                                        onPressed: () =>
                                            _showUpdateStockDialog(item),
                                        icon: const Icon(
                                          Icons.edit_note_rounded,
                                        ),
                                        label: Text(l10n.inventoryUpdateStock),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),

              // Remote Adjust Doses Button
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF0C4A6E).withValues(alpha: 0.4)
                        : const Color(0xFFE0F2FE),
                    foregroundColor: isDark
                        ? const Color(0xFF7DD3FC)
                        : const Color(0xFF0369A1),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF0284C7).withValues(alpha: 0.5)
                          : const Color(0xFFBAE6FD),
                    ),
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

              // Communication Section
              Row(
                children: [
                  Icon(Icons.chat_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.communicationHeader,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Message Pharmacy Button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF064E3B).withValues(alpha: 0.5)
                        : const Color(0xFFD1FAE5),
                    foregroundColor: isDark
                        ? const Color(0xFF6EE7B7)
                        : const Color(0xFF065F46),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final items = forecastAsync.value ?? const [];
                    final lowStockMeds = items
                        .where((i) => i.isUnderSevenDays || i.isExpired)
                        .toList();
                    final names = lowStockMeds.isNotEmpty
                        ? lowStockMeds.map((m) => m.name).join(', ')
                        : (items.isNotEmpty
                            ? items.map((m) => m.name).join(', ')
                            : l10n.inventoryMedicationsCategory);
                    final msg = '${l10n.pharmacyRefillGreeting} $names';
                    await Clipboard.setData(ClipboardData(text: msg));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.inventoryCopiedMessage)),
                    );
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: Text(l10n.messagePharmacyButton),
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

    if (widget.embedded) {
      return Scaffold(body: body);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navInventoryComm)),
      body: body,
    );
  }
}
