enum RiskLevel { safe, watch, highRisk, critical }

extension RiskLevelExtension on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.safe:
        return 'SAFE';
      case RiskLevel.watch:
        return 'WATCH';
      case RiskLevel.highRisk:
        return 'HIGH RISK';
      case RiskLevel.critical:
        return 'CRITICAL';
    }
  }

  static RiskLevel fromString(String val) {
    switch (val.toUpperCase()) {
      case 'SAFE':
        return RiskLevel.safe;
      case 'WATCH':
        return RiskLevel.watch;
      case 'HIGH_RISK':
      case 'HIGH RISK':
      case 'HIGH':
      case 'RISK_UNAVAILABLE':
      case 'UNAVAILABLE':
      case 'DATA INSUFFICIENT':
        return RiskLevel.highRisk;
      case 'CRITICAL':
        return RiskLevel.critical;
      default:
        return RiskLevel.safe;
    }
  }
}

class BatchModel {
  final String batchId;
  final String batchCode;
  final String plantId;
  final String plantName;
  final String projectId;
  final String projectName;
  final double volumeM3;
  final double targetSlumpMm;
  final double initialSlumpMm;
  final double currentSlumpMm;
  final double slumpRetentionRatio;
  final double concreteTempC;
  final double ambientTempC;
  final double elapsedMinutes;
  final double etaMinutes;
  final double originalEtaMinutes;
  final double distanceRemainingKm;
  final double totalDistanceKm;
  final double trafficIndex;
  final double precipitationProb;
  final String status;
  final RiskLevel riskLevel;
  final double heatRisk;
  final double travelRisk;
  final double deliveryRisk;
  final double compositeRisk;
  final String primaryDriver;
  final List<String> riskFactors;
  final String? recommendedAction;
  final String activeRouteId;
  final String concreteGrade;
  final String? retarderDose;
  final String createdAt;

  const BatchModel({
    required this.batchId,
    required this.batchCode,
    required this.plantId,
    required this.plantName,
    required this.projectId,
    required this.projectName,
    required this.volumeM3,
    required this.targetSlumpMm,
    required this.initialSlumpMm,
    required this.currentSlumpMm,
    required this.slumpRetentionRatio,
    required this.concreteTempC,
    required this.ambientTempC,
    required this.elapsedMinutes,
    required this.etaMinutes,
    required this.originalEtaMinutes,
    required this.distanceRemainingKm,
    required this.totalDistanceKm,
    required this.trafficIndex,
    required this.precipitationProb,
    required this.status,
    required this.riskLevel,
    required this.heatRisk,
    required this.travelRisk,
    required this.deliveryRisk,
    required this.compositeRisk,
    required this.primaryDriver,
    required this.riskFactors,
    this.recommendedAction,
    this.activeRouteId = 'route-a',
    this.concreteGrade = 'M35',
    this.retarderDose,
    required this.createdAt,
  });

  /// Computed total transit duration (elapsed + ETA)
  double get totalTransitMinutes => elapsedMinutes + etaMinutes;

  /// PRD Section 3.2 Core Approved State:
  /// Transit <= 78 min AND Slump Retention >= 92% -> APPROVED
  bool get isApproved => totalTransitMinutes <= 78.0 && slumpRetentionRatio >= 0.92;

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      batchId: json['batch_id'] as String? ?? 'batch-default',
      batchCode: json['batch_code'] as String? ?? 'RMC-204',
      plantId: json['plant_id'] as String? ?? 'plant-001',
      plantName: json['plant_name'] as String? ?? 'Ahmedabad Plant 01',
      projectId: json['project_id'] as String? ?? 'project-007',
      projectName: json['project_name'] as String? ?? 'Project Site 07',
      volumeM3: (json['volume_m3'] as num?)?.toDouble() ?? 6.0,
      targetSlumpMm: (json['target_slump_mm'] as num?)?.toDouble() ?? 105.0,
      initialSlumpMm: (json['initial_slump_mm'] as num?)?.toDouble() ?? 110.0,
      currentSlumpMm: (json['current_slump_mm'] as num?)?.toDouble() ?? 105.0,
      slumpRetentionRatio: (json['slump_retention_ratio'] as num?)?.toDouble() ?? 0.95,
      concreteTempC: (json['concrete_temp_c'] as num?)?.toDouble() ?? 32.4,
      ambientTempC: (json['ambient_temp_c'] as num?)?.toDouble() ?? 35.0,
      elapsedMinutes: (json['elapsed_minutes'] as num?)?.toDouble() ?? 25.0,
      etaMinutes: (json['eta_minutes'] as num?)?.toDouble() ?? 32.0,
      originalEtaMinutes: (json['original_eta_minutes'] as num?)?.toDouble() ?? 32.0,
      distanceRemainingKm: (json['distance_remaining_km'] as num?)?.toDouble() ?? 16.4,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 28.5,
      trafficIndex: (json['traffic_index'] as num?)?.toDouble() ?? 0.45,
      precipitationProb: (json['precipitation_prob'] as num?)?.toDouble() ?? 10.0,
      status: json['status'] as String? ?? 'IN_TRANSIT',
      riskLevel: RiskLevelExtension.fromString(json['risk_level'] as String? ?? 'SAFE'),
      heatRisk: (json['heat_risk'] as num?)?.toDouble() ?? 30.0,
      travelRisk: (json['travel_risk'] as num?)?.toDouble() ?? 30.0,
      deliveryRisk: (json['delivery_risk'] as num?)?.toDouble() ?? 30.0,
      compositeRisk: (json['composite_risk'] as num?)?.toDouble() ?? 30.0,
      primaryDriver: json['primary_driver'] as String? ?? 'Nominal transit parameters',
      riskFactors: (json['risk_factors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      recommendedAction: json['recommended_action'] as String?,
      activeRouteId: json['active_route_id'] as String? ?? 'route-a',
      concreteGrade: json['concrete_grade'] as String? ?? 'M35',
      retarderDose: json['retarder_dose'] as String?,
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  BatchModel copyWith({
    String? status,
    RiskLevel? riskLevel,
    double? elapsedMinutes,
    double? etaMinutes,
    double? distanceRemainingKm,
    double? concreteTempC,
    double? ambientTempC,
    double? currentSlumpMm,
    double? slumpRetentionRatio,
    double? heatRisk,
    double? travelRisk,
    double? deliveryRisk,
    double? compositeRisk,
    String? primaryDriver,
    List<String>? riskFactors,
    String? recommendedAction,
    String? activeRouteId,
    String? concreteGrade,
    String? retarderDose,
  }) {
    return BatchModel(
      batchId: batchId,
      batchCode: batchCode,
      plantId: plantId,
      plantName: plantName,
      projectId: projectId,
      projectName: projectName,
      volumeM3: volumeM3,
      targetSlumpMm: targetSlumpMm,
      initialSlumpMm: initialSlumpMm,
      currentSlumpMm: currentSlumpMm ?? this.currentSlumpMm,
      slumpRetentionRatio: slumpRetentionRatio ?? this.slumpRetentionRatio,
      concreteTempC: concreteTempC ?? this.concreteTempC,
      ambientTempC: ambientTempC ?? this.ambientTempC,
      elapsedMinutes: elapsedMinutes ?? this.elapsedMinutes,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      originalEtaMinutes: originalEtaMinutes,
      distanceRemainingKm: distanceRemainingKm ?? this.distanceRemainingKm,
      totalDistanceKm: totalDistanceKm,
      trafficIndex: trafficIndex,
      precipitationProb: precipitationProb,
      status: status ?? this.status,
      riskLevel: riskLevel ?? this.riskLevel,
      heatRisk: heatRisk ?? this.heatRisk,
      travelRisk: travelRisk ?? this.travelRisk,
      deliveryRisk: deliveryRisk ?? this.deliveryRisk,
      compositeRisk: compositeRisk ?? this.compositeRisk,
      primaryDriver: primaryDriver ?? this.primaryDriver,
      riskFactors: riskFactors ?? this.riskFactors,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      activeRouteId: activeRouteId ?? this.activeRouteId,
      concreteGrade: concreteGrade ?? this.concreteGrade,
      retarderDose: retarderDose ?? this.retarderDose,
      createdAt: createdAt,
    );
  }
}
