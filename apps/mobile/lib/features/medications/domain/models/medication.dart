/// Canonical days_mask bitmask shared with Supabase RPCs:
/// Sat=1 (bit 0), Sun=2 (bit 1), Mon=4 (bit 2), Tue=8 (bit 3),
/// Wed=16 (bit 4), Thu=32 (bit 5), Fri=64 (bit 6).
int medicationDayBitForDate(DateTime localDate) =>
    1 << ((localDate.weekday + 1) % 7);

/// Counts how many days per week (0..7) are enabled in [daysMask].
int countDaysInMask(int daysMask) {
  final masked = daysMask & 0x7F;
  var count = 0;
  for (var bit = 0; bit < 7; bit++) {
    if ((masked & (1 << bit)) != 0) count++;
  }
  return count;
}

class ScheduleModel {
  const ScheduleModel({
    required this.id,
    required this.medicationId,
    required this.timeOfDay,
    this.doseAmount = 1.0,
    this.mealRelation = 'after_meal',
    this.daysMask = 127,
    this.instructionsAr,
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    final rawTime = json['time_of_day'] as String;
    final timeOfDay = rawTime.length >= 5 ? rawTime.substring(0, 5) : rawTime;
    return ScheduleModel(
      id: json['id'].toString(),
      medicationId: json['medication_id'].toString(),
      timeOfDay: timeOfDay,
      doseAmount: (json['dose_amount'] as num?)?.toDouble() ?? 1.0,
      mealRelation: json['meal_relation'] as String? ?? 'after_meal',
      daysMask: (json['days_mask'] as num?)?.toInt() ?? 127,
      instructionsAr: json['instructions_ar'] as String?,
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final String id;
  final String medicationId;
  final String timeOfDay;
  final double doseAmount;
  final String mealRelation;
  final int daysMask;
  final String? instructionsAr;
  final String? startDate;
  final String? endDate;
  final bool isActive;

  bool isScheduledOn(DateTime localDate) {
    if (!isActive) return false;
    final dayBit = medicationDayBitForDate(localDate);
    if ((daysMask & dayBit) == 0) return false;

    final dateOnly = DateTime(localDate.year, localDate.month, localDate.day);
    if (startDate != null && startDate!.isNotEmpty) {
      final parsedStart = DateTime.tryParse(startDate!);
      if (parsedStart != null) {
        final startOnly = DateTime(
          parsedStart.year,
          parsedStart.month,
          parsedStart.day,
        );
        if (dateOnly.isBefore(startOnly)) return false;
      }
    }
    if (endDate != null && endDate!.isNotEmpty) {
      final parsedEnd = DateTime.tryParse(endDate!);
      if (parsedEnd != null) {
        final endOnly = DateTime(parsedEnd.year, parsedEnd.month, parsedEnd.day);
        if (dateOnly.isAfter(endOnly)) return false;
      }
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'medication_id': medicationId,
    'time_of_day': timeOfDay,
    'dose_amount': doseAmount,
    'meal_relation': mealRelation,
    'days_mask': daysMask,
    'instructions_ar': instructionsAr,
    if (startDate != null) 'start_date': startDate,
    if (endDate != null) 'end_date': endDate,
    'is_active': isActive,
  };
}

class ScheduleUpdateInput {
  const ScheduleUpdateInput({
    this.timeOfDay,
    this.doseAmount,
    this.mealRelation,
    this.daysMask,
    this.instructionsAr,
    this.isActive,
  });

  final String? timeOfDay;
  final double? doseAmount;
  final String? mealRelation;
  final int? daysMask;
  final String? instructionsAr;
  final bool? isActive;

  Map<String, dynamic> toJson() => {
    if (timeOfDay != null) 'time_of_day': timeOfDay,
    if (doseAmount != null) 'dose_amount': doseAmount,
    if (mealRelation != null) 'meal_relation': mealRelation,
    if (daysMask != null) 'days_mask': daysMask,
    if (instructionsAr != null) 'instructions_ar': instructionsAr,
    if (isActive != null) 'is_active': isActive,
  };
}

class ScheduleCreateInput {
  const ScheduleCreateInput({
    required this.timeOfDay,
    this.doseAmount = 1.0,
    this.mealRelation = 'after_meal',
    this.daysMask = 127,
    this.instructionsAr,
  });

  final String timeOfDay;
  final double doseAmount;
  final String mealRelation;
  final int daysMask;
  final String? instructionsAr;

  Map<String, dynamic> toJson() => {
    'time_of_day': timeOfDay,
    'dose_amount': doseAmount,
    'meal_relation': mealRelation,
    'days_mask': daysMask,
    if (instructionsAr != null) 'instructions_ar': instructionsAr,
  };
}

class MedicationModel {
  const MedicationModel({
    required this.id,
    required this.patientId,
    required this.name,
    this.tradeName,
    this.activeIngredient,
    this.form = 'قرص',
    this.strength,
    this.stockCount = 0,
    this.alertThresholdDays = 5,
    this.expiryDate,
    this.isActive = true,
    this.schedules = const [],
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    final rawSchedules = json['schedules'] as List<dynamic>? ?? const [];
    return MedicationModel(
      id: json['id'].toString(),
      patientId: json['patient_id'].toString(),
      name: json['name'] as String,
      tradeName: json['trade_name'] as String?,
      activeIngredient: json['active_ingredient'] as String?,
      form: json['form'] as String? ?? 'قرص',
      strength: json['strength'] as String?,
      stockCount: (json['stock_count'] as num?)?.toInt() ?? 0,
      alertThresholdDays: (json['alert_threshold_days'] as num?)?.toInt() ?? 5,
      expiryDate: json['expiry_date']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      schedules: rawSchedules
          .map(
            (e) => ScheduleModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }

  final String id;
  final String patientId;
  final String name;
  final String? tradeName;
  final String? activeIngredient;
  final String form;
  final String? strength;
  final int stockCount;
  final int alertThresholdDays;
  final String? expiryDate;
  final bool isActive;
  final List<ScheduleModel> schedules;

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'name': name,
    'trade_name': tradeName,
    'active_ingredient': activeIngredient,
    'form': form,
    'strength': strength,
    'stock_count': stockCount,
    'alert_threshold_days': alertThresholdDays,
    'expiry_date': expiryDate,
    'is_active': isActive,
    'schedules': schedules.map((s) => s.toJson()).toList(),
  };
}

class MedicationCreateInput {
  const MedicationCreateInput({
    required this.name,
    this.tradeName,
    this.activeIngredient,
    this.form = 'قرص',
    this.strength,
    this.stockCount = 0,
    this.alertThresholdDays = 5,
    this.expiryDate,
    this.schedules = const [],
  });

  final String name;
  final String? tradeName;
  final String? activeIngredient;
  final String form;
  final String? strength;
  final int stockCount;
  final int alertThresholdDays;
  final String? expiryDate;
  final List<ScheduleCreateInput> schedules;

  Map<String, dynamic> toJson() => {
    'name': name,
    if (tradeName != null) 'trade_name': tradeName,
    if (activeIngredient != null) 'active_ingredient': activeIngredient,
    'form': form,
    if (strength != null) 'strength': strength,
    'stock_count': stockCount,
    'alert_threshold_days': alertThresholdDays,
    if (expiryDate != null) 'expiry_date': expiryDate,
    'schedules': schedules.map((s) => s.toJson()).toList(),
  };
}

class MedicationUpdateInput {
  const MedicationUpdateInput({
    this.name,
    this.tradeName,
    this.activeIngredient,
    this.form,
    this.strength,
    this.stockCount,
    this.alertThresholdDays,
    this.expiryDate,
    this.clearExpiryDate = false,
    this.isActive,
  });

  final String? name;
  final String? tradeName;
  final String? activeIngredient;
  final String? form;
  final String? strength;
  final int? stockCount;
  final int? alertThresholdDays;
  final String? expiryDate;
  final bool clearExpiryDate;
  final bool? isActive;

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (tradeName != null) 'trade_name': tradeName,
    if (activeIngredient != null) 'active_ingredient': activeIngredient,
    if (form != null) 'form': form,
    if (strength != null) 'strength': strength,
    if (stockCount != null) 'stock_count': stockCount,
    if (alertThresholdDays != null) 'alert_threshold_days': alertThresholdDays,
    if (clearExpiryDate)
      'expiry_date': null
    else if (expiryDate != null)
      'expiry_date': expiryDate,
    if (isActive != null) 'is_active': isActive,
  };
}

class TodayDoseModel {
  const TodayDoseModel({
    required this.scheduleId,
    required this.medicationId,
    required this.medicationName,
    required this.timeOfDay,
    required this.doseAmount,
    required this.mealRelation,
    required this.status,
    this.instructionsAr,
    this.intakeLogId,
    this.actualTime,
  });

  factory TodayDoseModel.fromJson(Map<String, dynamic> json) {
    final rawTime = json['time_of_day'] as String;
    final timeOfDay = rawTime.length >= 5 ? rawTime.substring(0, 5) : rawTime;
    return TodayDoseModel(
      scheduleId: json['schedule_id'].toString(),
      medicationId: json['medication_id'].toString(),
      medicationName: json['medication_name'] as String,
      timeOfDay: timeOfDay,
      doseAmount: (json['dose_amount'] as num?)?.toDouble() ?? 1.0,
      mealRelation: json['meal_relation'] as String? ?? 'after_meal',
      instructionsAr: json['instructions_ar'] as String?,
      status: json['status'] as String? ?? 'pending',
      intakeLogId: json['intake_log_id']?.toString(),
      actualTime: json['actual_time'] != null
          ? DateTime.parse(json['actual_time'] as String)
          : null,
    );
  }

  final String scheduleId;
  final String medicationId;
  final String medicationName;
  final String timeOfDay;
  final double doseAmount;
  final String mealRelation;
  final String? instructionsAr;
  final String status;
  final String? intakeLogId;
  final DateTime? actualTime;

  bool get isActionable =>
      status == 'pending' || status == 'snoozed' || status == 'missed';

  Map<String, dynamic> toJson() => {
    'schedule_id': scheduleId,
    'medication_id': medicationId,
    'medication_name': medicationName,
    'time_of_day': timeOfDay,
    'dose_amount': doseAmount,
    'meal_relation': mealRelation,
    if (instructionsAr != null) 'instructions_ar': instructionsAr,
    'status': status,
    if (intakeLogId != null) 'intake_log_id': intakeLogId,
    if (actualTime != null)
      'actual_time': actualTime!.toUtc().toIso8601String(),
  };

  TodayDoseModel copyWith({
    String? status,
    String? intakeLogId,
    DateTime? actualTime,
  }) {
    return TodayDoseModel(
      scheduleId: scheduleId,
      medicationId: medicationId,
      medicationName: medicationName,
      timeOfDay: timeOfDay,
      doseAmount: doseAmount,
      mealRelation: mealRelation,
      instructionsAr: instructionsAr,
      status: status ?? this.status,
      intakeLogId: intakeLogId ?? this.intakeLogId,
      actualTime: actualTime ?? this.actualTime,
    );
  }
}

class IntakeLogCreateInput {
  const IntakeLogCreateInput({
    required this.clientUuid,
    required this.scheduleId,
    required this.scheduledTime,
    this.patientId,
    this.actualTime,
    this.status = 'taken',
    this.reason,
    this.loggedOffline = false,
  });

  final String clientUuid;
  final String scheduleId;
  final DateTime scheduledTime;
  final String? patientId;
  final DateTime? actualTime;
  final String status;
  final String? reason;
  final bool loggedOffline;

  Map<String, dynamic> toJson() => {
    'client_uuid': clientUuid,
    'schedule_id': scheduleId,
    'scheduled_time': scheduledTime.toUtc().toIso8601String(),
    if (patientId != null) 'patient_id': patientId,
    if (actualTime != null)
      'actual_time': actualTime!.toUtc().toIso8601String(),
    'status': status,
    if (reason != null) 'reason': reason,
    'logged_offline': loggedOffline,
  };
}

class IntakeLogModel {
  const IntakeLogModel({
    required this.id,
    required this.clientUuid,
    required this.scheduleId,
    required this.patientId,
    required this.scheduledTime,
    required this.status,
    this.actualTime,
    this.reason,
    this.loggedOffline = false,
  });

  factory IntakeLogModel.fromJson(Map<String, dynamic> json) {
    return IntakeLogModel(
      id: json['id'].toString(),
      clientUuid: json['client_uuid'].toString(),
      scheduleId: json['schedule_id'].toString(),
      patientId: json['patient_id'].toString(),
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      actualTime: json['actual_time'] != null
          ? DateTime.parse(json['actual_time'] as String)
          : null,
      status: json['status'] as String? ?? 'taken',
      reason: json['reason'] as String?,
      loggedOffline: json['logged_offline'] as bool? ?? false,
    );
  }

  final String id;
  final String clientUuid;
  final String scheduleId;
  final String patientId;
  final DateTime scheduledTime;
  final DateTime? actualTime;
  final String status;
  final String? reason;
  final bool loggedOffline;

  Map<String, dynamic> toJson() => {
    'id': id,
    'client_uuid': clientUuid,
    'schedule_id': scheduleId,
    'patient_id': patientId,
    'scheduled_time': scheduledTime.toUtc().toIso8601String(),
    if (actualTime != null)
      'actual_time': actualTime!.toUtc().toIso8601String(),
    'status': status,
    if (reason != null) 'reason': reason,
    'logged_offline': loggedOffline,
  };
}
