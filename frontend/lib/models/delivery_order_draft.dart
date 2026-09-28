import 'batch.dart';

/// Data transfer object representing a new RMC delivery order draft
/// before and during risk calculation and dispatch.
class DeliveryOrderDraft {
  final String batchCode;
  final String plantId;
  final String plantName;
  final String projectId;
  final String projectName;
  final String concreteGrade;
  final double volumeM3;
  final double initialSlumpMm;
  final double targetSlumpMm;
  final double slumpRetentionRequirementPct;
  final double concreteTempC;
  final double ambientTempC;
  final double humidityPct;
  final double precipitationProb;
  final String admixtureRetarder;
  final String selectedRouteId;
  final String dispatchTime;
  final double? plannedTransitMinutes;
  final double? expectedDelayMin;
  final String? operatorNotes;
  final double? plantLat;
  final double? plantLng;
  final double? projectLat;
  final double? projectLng;

  // Backwards-compatible aliases
  String get desiredDeliveryTime => dispatchTime;
  String get retarderAdmixture => admixtureRetarder;

  const DeliveryOrderDraft({
    required this.batchCode,
    required this.plantId,
    required this.plantName,
    required this.projectId,
    required this.projectName,
    this.concreteGrade = 'M35',
    this.volumeM3 = 6.0,
    this.initialSlumpMm = 110.0,
    this.targetSlumpMm = 105.0,
    this.slumpRetentionRequirementPct = 92.0,
    this.concreteTempC = 32.0,
    this.ambientTempC = 34.8,
    this.humidityPct = 50.0,
    this.precipitationProb = 0.0,
    this.admixtureRetarder = 'None',
    this.selectedRouteId = 'route_b',
    this.dispatchTime = '14:00',
    this.plannedTransitMinutes,
    this.expectedDelayMin,
    this.operatorNotes,
    this.plantLat,
    this.plantLng,
    this.projectLat,
    this.projectLng,
  });

  DeliveryOrderDraft copyWith({
    String? batchCode,
    String? plantId,
    String? plantName,
    String? projectId,
    String? projectName,
    String? concreteGrade,
    double? volumeM3,
    double? initialSlumpMm,
    double? targetSlumpMm,
    double? slumpRetentionRequirementPct,
    double? concreteTempC,
    double? ambientTempC,
    double? humidityPct,
    double? precipitationProb,
    String? admixtureRetarder,
    String? selectedRouteId,
    String? dispatchTime,
    String? desiredDeliveryTime,
    double? plannedTransitMinutes,
    double? expectedDelayMin,
    String? operatorNotes,
    double? plantLat,
    double? plantLng,
    double? projectLat,
    double? projectLng,
  }) {
    return DeliveryOrderDraft(
      batchCode: batchCode ?? this.batchCode,
      plantId: plantId ?? this.plantId,
      plantName: plantName ?? this.plantName,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      concreteGrade: concreteGrade ?? this.concreteGrade,
      volumeM3: volumeM3 ?? this.volumeM3,
      initialSlumpMm: initialSlumpMm ?? this.initialSlumpMm,
      targetSlumpMm: targetSlumpMm ?? this.targetSlumpMm,
      slumpRetentionRequirementPct: slumpRetentionRequirementPct ?? this.slumpRetentionRequirementPct,
      concreteTempC: concreteTempC ?? this.concreteTempC,
      ambientTempC: ambientTempC ?? this.ambientTempC,
      humidityPct: humidityPct ?? this.humidityPct,
      precipitationProb: precipitationProb ?? this.precipitationProb,
      admixtureRetarder: admixtureRetarder ?? this.admixtureRetarder,
      selectedRouteId: selectedRouteId ?? this.selectedRouteId,
      dispatchTime: dispatchTime ?? desiredDeliveryTime ?? this.dispatchTime,
      plannedTransitMinutes: plannedTransitMinutes ?? this.plannedTransitMinutes,
      expectedDelayMin: expectedDelayMin ?? this.expectedDelayMin,
      operatorNotes: operatorNotes ?? this.operatorNotes,
      plantLat: plantLat ?? this.plantLat,
      plantLng: plantLng ?? this.plantLng,
      projectLat: projectLat ?? this.projectLat,
      projectLng: projectLng ?? this.projectLng,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batch_id': batchCode,
      'batch_code': batchCode,
      'plant_id': plantId,
      'plant_name': plantName,
      'project_id': projectId,
      'project_name': projectName,
      'concrete_grade': concreteGrade,
      'mix_type': concreteGrade,
      'volume_m3': volumeM3,
      'concrete_volume_m3': volumeM3,
      'initial_slump_mm': initialSlumpMm,
      'target_slump_mm': targetSlumpMm,
      'concrete_temp_c': concreteTempC,
      'ambient_temp_c': ambientTempC,
      'relative_humidity': humidityPct,
      'humidity_pct': humidityPct,
      'precipitation_prob': precipitationProb,
      'admixture_retarder': admixtureRetarder,
      'retarder_admixture': admixtureRetarder,
      'selected_route_id': selectedRouteId,
      'route_id': selectedRouteId,
      'dispatch_time': dispatchTime,
      'desired_delivery_time': dispatchTime,
      'planned_transit_minutes': plannedTransitMinutes,
      'expected_delay_min': expectedDelayMin,
      'operator_notes': operatorNotes,
      if (plantLat != null) 'plant_lat': plantLat,
      if (plantLng != null) 'plant_lng': plantLng,
      if (projectLat != null) 'project_lat': projectLat,
      if (projectLng != null) 'project_lng': projectLng,
    };
  }
}

/// Structured AI/ML Risk Assessment result for a planned delivery order
class DeliveryRiskAssessment {
  final double predictedSlumpMm;
  final double slumpRetentionRatio;
  final double heatRisk;
  final double travelRisk;
  final double deliveryRisk;
  final double compositeRisk;
  final RiskLevel riskLevel;
  final bool isApproved;
  final String statusLabel;
  final String primaryDriver;
  final List<String> contributingFactors;
  final String? recommendedAction;
  final double estimatedLossExposure;
  final double predictedTransitMinutes;
  final double etaDelayMinutes;
  final String selectedRouteName;
  final RiskLevel heatRiskLevel;
  final RiskLevel travelRiskLevel;
  final RiskLevel deliveryRiskLevel;
  final String expectedArrivalTime;
  final String slaStatus;
  final String worstMaterialFactor;
  final bool isDataInsufficient;

  const DeliveryRiskAssessment({
    required this.predictedSlumpMm,
    required this.slumpRetentionRatio,
    required this.heatRisk,
    required this.travelRisk,
    required this.deliveryRisk,
    required this.compositeRisk,
    required this.riskLevel,
    required this.isApproved,
    required this.statusLabel,
    required this.primaryDriver,
    required this.contributingFactors,
    this.recommendedAction,
    required this.estimatedLossExposure,
    required this.predictedTransitMinutes,
    required this.etaDelayMinutes,
    required this.selectedRouteName,
    this.heatRiskLevel = RiskLevel.safe,
    this.travelRiskLevel = RiskLevel.safe,
    this.deliveryRiskLevel = RiskLevel.safe,
    this.expectedArrivalTime = '--:--',
    this.slaStatus = 'COMPLIANT',
    this.worstMaterialFactor = 'None',
    this.isDataInsufficient = false,
  });

  factory DeliveryRiskAssessment.fromJson(Map<String, dynamic> json) {
    final overallDecision = json['decision'] as String? ?? 'SAFE';
    final parsedRiskLevel = RiskLevelExtension.fromString(overallDecision);

    final heatScore = (json['heat_risk'] as num?)?.toDouble() ?? 35.0;
    final travelScore = (json['travel_risk'] as num?)?.toDouble() ?? 30.0;
    final deliveryScore = (json['delivery_risk'] as num?)?.toDouble() ?? 32.0;

    RiskLevel parseDimension(dynamic raw, double score) {
      if (raw != null) {
        return RiskLevelExtension.fromString(raw.toString());
      }
      if (score >= 80.0) return RiskLevel.critical;
      if (score >= 65.0) return RiskLevel.highRisk;
      if (score >= 45.0) return RiskLevel.watch;
      return RiskLevel.safe;
    }

    return DeliveryRiskAssessment(
      predictedSlumpMm: (json['predicted_slump_mm'] as num?)?.toDouble() ?? 102.0,
      slumpRetentionRatio: (json['slump_retention'] as num?)?.toDouble() ?? 0.94,
      heatRisk: heatScore,
      travelRisk: travelScore,
      deliveryRisk: deliveryScore,
      compositeRisk: (json['composite_risk'] as num?)?.toDouble() ?? 32.0,
      riskLevel: parsedRiskLevel,
      isApproved: json['is_approved'] as bool? ?? (parsedRiskLevel == RiskLevel.safe),
      statusLabel: json['status_label'] as String? ?? 'DELIVERY ON TRACK',
      primaryDriver: json['primary_driver'] as String? ?? 'Within operational tolerance',
      contributingFactors: (json['contributors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      recommendedAction: json['recommended_action'] as String?,
      estimatedLossExposure: (json['estimated_loss_exposure'] as num?)?.toDouble() ?? 0.0,
      predictedTransitMinutes: (json['planned_transit_minutes'] as num?)?.toDouble() ??
          (json['predicted_transit_minutes'] as num?)?.toDouble() ?? 52.0,
      etaDelayMinutes: (json['expected_delay_min'] as num?)?.toDouble() ??
          (json['eta_delay_minutes'] as num?)?.toDouble() ?? 0.0,
      selectedRouteName: json['selected_route_name'] as String? ?? 'Route B (Airport Bypass Expressway)',
      heatRiskLevel: parseDimension(json['heat_risk_level'], heatScore),
      travelRiskLevel: parseDimension(json['travel_risk_level'], travelScore),
      deliveryRiskLevel: parseDimension(json['delivery_risk_level'], deliveryScore),
      expectedArrivalTime: json['expected_arrival_time'] as String? ?? '--:--',
      slaStatus: json['sla_status'] as String? ?? 'COMPLIANT',
      worstMaterialFactor: json['worst_material_factor'] as String? ?? 'None',
      isDataInsufficient: json['is_data_insufficient'] as bool? ?? false,
    );
  }

  double get slumpRetentionPct => slumpRetentionRatio * 100.0;
  double get compositeRiskScore => compositeRisk;
  String get overallRisk {
    if (riskLevel == RiskLevel.critical) return 'CRITICAL';
    if (riskLevel == RiskLevel.highRisk) return 'HIGH';
    if (riskLevel == RiskLevel.watch) return 'WATCH';
    return 'SAFE';
  }

  String get heatRiskLabel {
    if (heatRiskLevel == RiskLevel.critical) return 'CRITICAL';
    if (heatRiskLevel == RiskLevel.highRisk) return 'HIGH';
    if (heatRiskLevel == RiskLevel.watch) return 'WATCH';
    return 'SAFE';
  }

  String get travelRiskLabel {
    if (travelRiskLevel == RiskLevel.critical) return 'CRITICAL';
    if (travelRiskLevel == RiskLevel.highRisk) return 'HIGH';
    if (travelRiskLevel == RiskLevel.watch) return 'WATCH';
    return 'SAFE';
  }

  String get deliveryRiskLabel {
    if (deliveryRiskLevel == RiskLevel.critical) return 'CRITICAL';
    if (deliveryRiskLevel == RiskLevel.highRisk) return 'HIGH';
    if (deliveryRiskLevel == RiskLevel.watch) return 'WATCH';
    return 'SAFE';
  }

  List<String> get groundedDrivers => contributingFactors;
  String get recommendationText =>
      recommendedAction ??
      (isApproved
          ? 'Proceed with standard dispatch via recommended route.'
          : 'Apply Route B bypass or dose 0.4% retarder admixture before dispatching.');
  String get financialLossExposure => '₹${(estimatedLossExposure / 100000.0).toStringAsFixed(2)}L';
}
