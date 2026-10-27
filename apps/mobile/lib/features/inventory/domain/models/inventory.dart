class MedicationForecastModel {
  const MedicationForecastModel({
    required this.medicationId,
    required this.name,
    required this.stockCount,
    required this.daysRemaining,
    this.isLowStock = false,
    this.isExpired = false,
    this.isExpiringSoon = false,
    this.expiryDate,
  });

  factory MedicationForecastModel.fromJson(Map<String, dynamic> json) {
    return MedicationForecastModel(
      medicationId: json['medication_id'] as String,
      name: json['name'] as String,
      stockCount: json['stock_count'] as int? ?? 0,
      daysRemaining: json['days_remaining'] as int? ?? 0,
      isLowStock: json['is_low_stock'] as bool? ?? false,
      isExpired: json['is_expired'] as bool? ?? false,
      isExpiringSoon: json['is_expiring_soon'] as bool? ?? false,
      expiryDate: DateTime.tryParse(json['expiry_date']?.toString() ?? ''),
    );
  }

  final String medicationId;
  final String name;
  final int stockCount;
  final int daysRemaining;
  final bool isLowStock;
  final bool isExpired;
  final bool isExpiringSoon;
  final DateTime? expiryDate;

  bool get isUnderSevenDays => daysRemaining < 7 || isLowStock;
}

class RefillOrderResult {
  const RefillOrderResult({
    required this.messageText,
    required this.whatsappUrl,
  });

  factory RefillOrderResult.fromJson(Map<String, dynamic> json) {
    return RefillOrderResult(
      messageText: json['message_text'] as String,
      whatsappUrl: json['whatsapp_url'] as String,
    );
  }

  final String messageText;
  final String whatsappUrl;
}
