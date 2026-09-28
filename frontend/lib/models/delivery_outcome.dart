class DeliveryOutcomeModel {
  final String outcomeId;
  final String batchId;
  final String outcome; // "accepted", "accepted_with_warning", "rejected"
  final String qualityGrade;
  final double slumpVarianceMm;
  final double financialImpactInr;
  final String financialType; // "AVOIDED_LOSS", "MATERIAL_LOSS", "NOMINAL_COST"
  final bool mlTrainingRecorded;
  final String recordedAt;

  const DeliveryOutcomeModel({
    required this.outcomeId,
    required this.batchId,
    required this.outcome,
    required this.qualityGrade,
    required this.slumpVarianceMm,
    required this.financialImpactInr,
    required this.financialType,
    required this.mlTrainingRecorded,
    required this.recordedAt,
  });

  factory DeliveryOutcomeModel.fromJson(Map<String, dynamic> json) {
    return DeliveryOutcomeModel(
      outcomeId: json['outcome_id'] as String? ?? 'outcome-001',
      batchId: json['batch_id'] as String,
      outcome: json['outcome'] as String,
      qualityGrade: json['quality_grade'] as String? ?? 'HIGH_SPEC_DELIVERY',
      slumpVarianceMm: (json['slump_variance_mm'] as num?)?.toDouble() ?? 0.0,
      financialImpactInr: (json['financial_impact_inr'] as num?)?.toDouble() ?? 0.0,
      financialType: json['financial_type'] as String? ?? 'NOMINAL_DELIVERY',
      mlTrainingRecorded: json['ml_training_recorded'] as bool? ?? true,
      recordedAt: json['recorded_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
