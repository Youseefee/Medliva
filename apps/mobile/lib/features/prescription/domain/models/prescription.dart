class ExtractedDrugModel {
  const ExtractedDrugModel({
    required this.drugTradeName,
    this.dosageMg,
    this.frequencyPerDay = 1,
    this.mealRelation = 'after_meal',
    this.times = const [],
    this.inventoryPills = 30,
    this.confidenceScore = 0.95,
    this.activeIngredient,
  });

  factory ExtractedDrugModel.fromJson(Map<String, dynamic> json) {
    final rawTimes = json['times'] as List<dynamic>? ?? const [];
    final rawDosage = json['dosage_mg'];
    return ExtractedDrugModel(
      drugTradeName: json['drug_trade_name'] as String,
      dosageMg: rawDosage?.toString(),
      frequencyPerDay: json['frequency_per_day'] as int? ?? 1,
      mealRelation: json['meal_relation'] as String? ?? 'after_meal',
      times: rawTimes.map((e) => e.toString()).toList(),
      inventoryPills: json['inventory_pills'] as int? ?? 30,
      confidenceScore:
          (json['confidence_score'] as num?)?.toDouble() ?? 0.95,
      activeIngredient: json['active_ingredient'] as String?,
    );
  }

  final String drugTradeName;
  final String? dosageMg;
  final int frequencyPerDay;
  final String mealRelation;
  final List<String> times;
  final int inventoryPills;
  final double confidenceScore;
  final String? activeIngredient;
}

class PrescriptionScanResult {
  const PrescriptionScanResult({
    required this.medications,
    this.confidence = 0.95,
  });

  factory PrescriptionScanResult.fromJson(Map<String, dynamic> json) {
    final rawMeds = json['medications'] as List<dynamic>? ?? const [];
    return PrescriptionScanResult(
      medications: rawMeds
          .map((e) => ExtractedDrugModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.95,
    );
  }

  final List<ExtractedDrugModel> medications;
  final double confidence;
}
