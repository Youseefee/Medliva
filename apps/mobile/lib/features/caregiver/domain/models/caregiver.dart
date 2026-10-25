class PairingCodeModel {
  const PairingCodeModel({required this.code, required this.expiresAt});

  factory PairingCodeModel.fromJson(Map<String, dynamic> json) {
    return PairingCodeModel(
      code: json['code'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  final String code;
  final DateTime expiresAt;
}

class LinkedPatientModel {
  const LinkedPatientModel({
    required this.patientId,
    required this.phone,
    required this.status,
    this.name,
    this.linkedAt,
    this.todayTakenCount = 0,
    this.todayMissedCount = 0,
    this.activeAlertsCount = 0,
  });

  factory LinkedPatientModel.fromJson(Map<String, dynamic> json) {
    return LinkedPatientModel(
      patientId: json['patient_id'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      status: json['status'] as String,
      linkedAt: json['linked_at'] != null
          ? DateTime.parse(json['linked_at'] as String)
          : null,
      todayTakenCount: json['today_taken_count'] as int? ?? 0,
      todayMissedCount: json['today_missed_count'] as int? ?? 0,
      activeAlertsCount: json['active_alerts_count'] as int? ?? 0,
    );
  }

  final String patientId;
  final String? name;
  final String? phone;
  final String status;
  final DateTime? linkedAt;
  final int todayTakenCount;
  final int todayMissedCount;
  final int activeAlertsCount;
}

class LinkedCaregiverModel {
  const LinkedCaregiverModel({
    required this.caregiverId,
    required this.status,
    this.name,
    this.phone,
    this.linkedAt,
  });

  factory LinkedCaregiverModel.fromJson(Map<String, dynamic> json) {
    return LinkedCaregiverModel(
      caregiverId: json['caregiver_id'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      status: json['status'] as String,
      linkedAt: json['linked_at'] != null
          ? DateTime.parse(json['linked_at'] as String)
          : null,
    );
  }

  final String caregiverId;
  final String? name;
  final String? phone;
  final String status;
  final DateTime? linkedAt;

  String get displayName => name?.trim().isNotEmpty == true ? name! : phone ?? '';
}
