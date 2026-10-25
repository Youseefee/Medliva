class EmergencyContactModel {
  const EmergencyContactModel({
    required this.id,
    required this.patientId,
    required this.name,
    required this.phone,
    this.relationship,
    this.isPrimary = false,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      relationship: json['relationship'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  final String id;
  final String patientId;
  final String name;
  final String phone;
  final String? relationship;
  final bool isPrimary;
}

class EmergencyContactCreateInput {
  const EmergencyContactCreateInput({
    required this.name,
    required this.phone,
    this.relationship,
    this.isPrimary = false,
  });

  final String name;
  final String phone;
  final String? relationship;
  final bool isPrimary;

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        if (relationship != null) 'relationship': relationship,
        'is_primary': isPrimary,
      };
}

class SosResponseModel {
  const SosResponseModel({
    required this.status,
    required this.alertId,
    required this.notifiedContactsCount,
  });

  factory SosResponseModel.fromJson(Map<String, dynamic> json) {
    return SosResponseModel(
      status: json['status'] as String,
      alertId: json['alert_id'] as String,
      notifiedContactsCount: json['notified_contacts_count'] as int? ?? 0,
    );
  }

  final String status;
  final String alertId;
  final int notifiedContactsCount;
}
