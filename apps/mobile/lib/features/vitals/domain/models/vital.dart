class VitalReadingModel {
  const VitalReadingModel({
    required this.id,
    required this.patientId,
    required this.type,
    required this.valuePrimary,
    required this.band,
    required this.recordedAt,
    this.clientUuid,
    this.valueSecondary,
    this.mealContext,
    this.rawTranscript,
  });

  factory VitalReadingModel.fromJson(Map<String, dynamic> json) {
    return VitalReadingModel(
      id: json['id'].toString(),
      clientUuid: json['client_uuid']?.toString(),
      patientId: json['patient_id'].toString(),
      type: json['type'] as String,
      valuePrimary: (json['value_primary'] as num).toDouble(),
      valueSecondary: (json['value_secondary'] as num?)?.toDouble(),
      mealContext: json['meal_context'] as String?,
      band: json['band'] as String? ?? 'normal',
      rawTranscript: json['raw_transcript'] as String?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  final String id;
  final String? clientUuid;
  final String patientId;
  final String type;
  final double valuePrimary;
  final double? valueSecondary;
  final String? mealContext;
  final String band;
  final String? rawTranscript;
  final DateTime recordedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        if (clientUuid != null) 'client_uuid': clientUuid,
        'patient_id': patientId,
        'type': type,
        'value_primary': valuePrimary,
        if (valueSecondary != null) 'value_secondary': valueSecondary,
        if (mealContext != null) 'meal_context': mealContext,
        'band': band,
        if (rawTranscript != null) 'raw_transcript': rawTranscript,
        'recorded_at': recordedAt.toIso8601String(),
      };
}

class VitalCreateInput {
  const VitalCreateInput({
    required this.type,
    required this.valuePrimary,
    this.valueSecondary,
    this.mealContext,
    this.rawTranscript,
    this.clientUuid,
  });

  final String type;
  final double valuePrimary;
  final double? valueSecondary;
  final String? mealContext;
  final String? rawTranscript;
  final String? clientUuid;

  Map<String, dynamic> toJson() => {
        if (clientUuid != null) 'client_uuid': clientUuid,
        'type': type,
        'value_primary': valuePrimary,
        if (valueSecondary != null) 'value_secondary': valueSecondary,
        if (mealContext != null) 'meal_context': mealContext,
        if (rawTranscript != null) 'raw_transcript': rawTranscript,
      };
}

class VoiceVitalsParseResult {
  const VoiceVitalsParseResult({
    required this.transcript,
    required this.type,
    required this.valuePrimary,
    required this.band,
    required this.messageAr,
    this.valueSecondary,
    this.mealContext,
  });

  factory VoiceVitalsParseResult.fromJson(Map<String, dynamic> json) {
    return VoiceVitalsParseResult(
      transcript: json['transcript'] as String,
      type: json['type'] as String,
      valuePrimary: (json['value_primary'] as num).toDouble(),
      valueSecondary: (json['value_secondary'] as num?)?.toDouble(),
      mealContext: json['meal_context'] as String?,
      band: json['band'] as String,
      messageAr: json['message_ar'] as String? ?? '',
    );
  }

  final String transcript;
  final String type;
  final double valuePrimary;
  final double? valueSecondary;
  final String? mealContext;
  final String band;
  final String messageAr;
}
