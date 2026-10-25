class ReportSummaryModel {
  const ReportSummaryModel({
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.fromDate,
    required this.toDate,
    required this.adherenceRatePct,
    required this.totalDoses,
    required this.takenDoses,
    required this.skippedDoses,
    required this.missedDosesCount,
    this.activeMedications = const [],
    this.adherenceHistory = const [],
    this.vitalsHistory = const [],
  });

  factory ReportSummaryModel.fromJson(Map<String, dynamic> json) {
    final meds = json['active_medications'] as List<dynamic>? ?? const [];
    final adherence = json['adherence_history'] as List<dynamic>? ?? const [];
    final vitals = json['vitals_history'] as List<dynamic>? ?? const [];

    return ReportSummaryModel(
      patientId: json['patient_id'] as String,
      patientName: json['patient_name'] as String,
      patientPhone: json['patient_phone'] as String?,
      fromDate: json['from_date'] as String,
      toDate: json['to_date'] as String,
      adherenceRatePct: (json['adherence_rate_pct'] as num).toDouble(),
      totalDoses: json['total_doses'] as int? ?? 0,
      takenDoses: json['taken_doses'] as int? ?? 0,
      skippedDoses: json['skipped_doses'] as int? ?? 0,
      missedDosesCount: json['missed_doses_count'] as int? ?? 0,
      activeMedications: meds
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      adherenceHistory: adherence
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      vitalsHistory: vitals
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  final String patientId;
  final String patientName;
  final String? patientPhone;
  final String fromDate;
  final String toDate;
  final double adherenceRatePct;
  final int totalDoses;
  final int takenDoses;
  final int skippedDoses;
  final int missedDosesCount;
  final List<Map<String, dynamic>> activeMedications;
  final List<Map<String, dynamic>> adherenceHistory;
  final List<Map<String, dynamic>> vitalsHistory;
}
