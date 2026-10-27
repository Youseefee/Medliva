import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/inventory/domain/models/inventory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryRepository {
  InventoryRepository({SupabaseClient? supabaseClient})
    : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabaseClient;

  Future<List<MedicationForecastModel>> getForecast(String patientId) async {
    final rows = await _supabaseClient
        .from('medications')
        .select(
          'id, name, stock_count, alert_threshold_days, expiry_date, '
          'schedules(dose_amount, is_active)',
        )
        .eq('patient_id', patientId)
        .eq('is_active', true);

    final today = DateTime.now().toUtc();
    final todayDate = DateTime.utc(today.year, today.month, today.day);
    return (rows as List<dynamic>).map((raw) {
      final med = Map<String, dynamic>.from(raw as Map);
      final activeSchedules = (med['schedules'] as List<dynamic>? ?? const [])
          .map((schedule) => Map<String, dynamic>.from(schedule as Map))
          .where((schedule) => schedule['is_active'] as bool? ?? true);
      final dailyDose = activeSchedules.fold<double>(
        0,
        (total, schedule) =>
            total + ((schedule['dose_amount'] as num?)?.toDouble() ?? 1),
      );
      final stockCount = (med['stock_count'] as num?)?.toInt() ?? 0;
      final daysRemaining = dailyDose > 0
          ? (stockCount / dailyDose).floor()
          : 999;
      final threshold = (med['alert_threshold_days'] as num?)?.toInt() ?? 5;
      final expiryDate = DateTime.tryParse(
        med['expiry_date']?.toString() ?? '',
      );
      final normalizedExpiry = expiryDate == null
          ? null
          : DateTime.utc(expiryDate.year, expiryDate.month, expiryDate.day);
      final isExpired =
          normalizedExpiry != null && normalizedExpiry.isBefore(todayDate);
      final isExpiringSoon =
          normalizedExpiry != null &&
          !isExpired &&
          !normalizedExpiry.isAfter(todayDate.add(const Duration(days: 30)));

      return MedicationForecastModel(
        medicationId: med['id']?.toString() ?? '',
        name: med['name']?.toString() ?? '',
        stockCount: stockCount,
        daysRemaining: daysRemaining,
        isLowStock: daysRemaining <= threshold,
        isExpired: isExpired,
        isExpiringSoon: isExpiringSoon,
        expiryDate: normalizedExpiry,
      );
    }).toList();
  }

  Future<RefillOrderResult> createRefillOrder({
    required String patientId,
    required String medicationName,
    int quantity = 1,
  }) async {
    if (quantity < 1) throw ArgumentError.value(quantity, 'quantity');

    var patientName = 'المريض';
    String? address;
    final user = await _supabaseClient
        .from('users')
        .select('name, address')
        .eq('id', patientId)
        .maybeSingle();
    if (user != null) {
      final name = user['name'] as String?;
      if (name != null && name.trim().isNotEmpty) patientName = name.trim();
      address = user['address'] as String?;
    }

    final lines = [
      'السلام عليكم، أود طلب نواقص أدوية للمريض: $patientName',
      'الأدوية المطلوبة:',
      '• $medicationName: $quantity عبوة',
    ];
    if (address != null && address.trim().isNotEmpty) {
      lines.add('العنوان: ${address.trim()}');
    }
    lines.add('شكراً جزيلاً.');

    final messageText = lines.join('\n');
    return RefillOrderResult(
      messageText: messageText,
      whatsappUrl: 'https://wa.me/?text=${Uri.encodeComponent(messageText)}',
    );
  }
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(supabaseClient: ref.watch(supabaseClientProvider));
});
