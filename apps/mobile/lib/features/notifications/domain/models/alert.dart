class AlertModel {
  const AlertModel({
    required this.id,
    required this.patientId,
    required this.type,
    required this.tier,
    required this.sentAt,
    required this.createdAt,
    this.payload,
    this.acknowledgedAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    final sentAt = DateTime.tryParse(json['sent_at']?.toString() ?? '');
    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '');

    return AlertModel(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'unknown',
      tier: (json['tier'] as num?)?.toInt() ?? 1,
      payload: rawPayload is Map<String, dynamic> ? rawPayload : null,
      sentAt: sentAt ?? DateTime.now().toUtc(),
      createdAt: createdAt ?? sentAt ?? DateTime.now().toUtc(),
      acknowledgedAt: DateTime.tryParse(json['acknowledged_at']?.toString() ?? ''),
    );
  }

  final String id;
  final String patientId;
  final String type;
  final int tier;
  final Map<String, dynamic>? payload;
  final DateTime sentAt;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;

  bool get isAcknowledged => acknowledgedAt != null;

  String? get note => payload?['note']?.toString();

  String? get medicationName => payload?['medication_name']?.toString();

  String? get timeOfDay => payload?['time_of_day']?.toString();

  String? get vitalType => payload?['type']?.toString();

  double? get vitalValuePrimary => (payload?['value_primary'] as num?)?.toDouble();

  double? get vitalValueSecondary =>
      (payload?['value_secondary'] as num?)?.toDouble();
}
