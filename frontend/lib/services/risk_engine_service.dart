import 'dart:math';
import '../models/batch.dart';
import '../models/delivery_order_draft.dart';
import '../models/route_option.dart';
import 'api_service.dart';
import 'route_service.dart';

/// Centralized AI/ML Risk Prediction Engine Service
/// Implements the multi-factor operational decision model specified in PRD.md Section 3.2-3.4
/// Connects to FastAPI backend (/rmc/risk/predict or /rmc/risk/calculate) with deterministic local domain engine fallback.
class RiskEngineService {
  final ApiService _apiService;

  RiskEngineService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  static const Map<String, double> concreteGradeSensitivities = {
    'M20': 0.85,
    'M25': 0.92,
    'M30': 1.00,
    'M35': 1.08,
    'M40': 1.22,
    'M45': 1.35,
  };

  /// Executes the full delivery risk calculation pipeline:
  /// Input -> Route Context -> Weather Window -> Slump Kinetics -> 3D Risk Scores -> Worst Material Factor -> Decision
  Future<DeliveryRiskAssessment> calculateRisk(DeliveryOrderDraft draft) async {
    final routeAssessment = RouteService.getRoute(
      originName: draft.plantName,
      destinationName: draft.projectName,
      preferredRouteId: draft.selectedRouteId,
    );
    final route = routeAssessment.toRouteOptionModel(isRecommended: routeAssessment.routeId == 'route-b');

    // Dynamic route delay & transit calculation directly from the canonical RouteAssessment
    final double delayMin = draft.expectedDelayMin ?? routeAssessment.expectedDelayMin;
    final double baseTransitMin = draft.plannedTransitMinutes ?? routeAssessment.baseTransitMinutes;
    final double totalTransitMin = baseTransitMin + delayMin;

    final double trafficIndex = routeAssessment.trafficIndex;
    final double precipProb = routeAssessment.precipitationProb;

    // 1. Attempt backend prediction first
    try {
      final response = await _apiService.predictRisk({
        'batch_id': draft.batchCode,
        'plant_name': draft.plantName,
        'project_name': draft.projectName,
        'concrete_grade': draft.concreteGrade,
        'volume_m3': draft.volumeM3,
        'dispatch_time': draft.dispatchTime,
        'ambient_temp_c': draft.ambientTempC,
        'concrete_temp_c': draft.concreteTempC,
        'relative_humidity': draft.humidityPct,
        'traffic_index': trafficIndex,
        'eta_minutes': baseTransitMin,
        'elapsed_minutes': 0.0,
        'planned_transit_minutes': totalTransitMin,
        'expected_delay_min': delayMin,
        'initial_slump_mm': draft.initialSlumpMm,
        'target_slump_mm': draft.targetSlumpMm,
        'precipitation_prob': precipProb,
        'distance_km': route.distanceKm,
        'admixture_retarder': draft.admixtureRetarder,
        'route_id': draft.selectedRouteId,
      });

      if (response != null) {
        return DeliveryRiskAssessment.fromJson({
          ...response,
          'selected_route_name': route.routeName,
          'planned_transit_minutes': totalTransitMin,
          'estimated_loss_exposure': draft.volumeM3 * 28000.0,
        });
      }
    } catch (_) {
      // Fallback to deterministic local engine
    }

    // 2. Deterministic Local Model Engine (Exact parity with backend RMC Risk Engine)
    return _computeLocalRisk(draft, route, totalTransitMin, delayMin, trafficIndex, precipProb);
  }

  RouteOptionModel getRouteById(String routeId, {String? originName, String? destinationName}) {
    final assessment = RouteService.getRoute(
      originName: originName ?? 'Ahmedabad Plant 01',
      destinationName: destinationName ?? 'Gift City Tower B',
      preferredRouteId: routeId,
    );
    return assessment.toRouteOptionModel();
  }

  List<RouteOptionModel> getCandidateRoutes({String? originName, String? destinationName}) {
    return RouteService.getCandidateRouteOptions(
      originName: originName ?? 'Ahmedabad Plant 01',
      destinationName: destinationName ?? 'Gift City Tower B',
    );
  }

  int _parseTimeToMinutes(String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      final hours = int.parse(parts[0]);
      final minutes = parts.length > 1 ? int.parse(parts[1]) : 0;
      return (hours % 24) * 60 + (minutes % 60);
    } catch (_) {
      return 14 * 60; // 14:00 default
    }
  }

  String _formatMinutesToTime(int totalMin) {
    final normalized = totalMin % (24 * 60);
    final hours = normalized ~/ 60;
    final minutes = normalized % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  DeliveryRiskAssessment _computeLocalRisk(
    DeliveryOrderDraft draft,
    RouteOptionModel route,
    double totalTransitMin,
    double delayMin,
    double trafficIndex,
    double precipProb,
  ) {
    // 1. Validation & Sanity
    final List<String> validationErrors = [];
    if (draft.plantName.trim().isEmpty) validationErrors.add('Dispatch plant origin is required');
    if (draft.projectName.trim().isEmpty) validationErrors.add('Destination project site is required');
    if (totalTransitMin <= 0.0) validationErrors.add('Transit duration must be greater than zero');
    if (draft.initialSlumpMm <= 0.0) validationErrors.add('Initial slump must be positive');
    if (draft.volumeM3 <= 0.0) validationErrors.add('Batch volume must be positive');

    if (validationErrors.isNotEmpty) {
      return DeliveryRiskAssessment(
        predictedSlumpMm: 0.0,
        slumpRetentionRatio: 0.0,
        heatRisk: 50.0,
        travelRisk: 75.0,
        deliveryRisk: 75.0,
        compositeRisk: 70.0,
        riskLevel: RiskLevel.highRisk,
        isApproved: false,
        statusLabel: 'DATA INSUFFICIENT / RISK UNAVAILABLE',
        primaryDriver: 'Missing critical input telemetry: ${validationErrors.join("; ")}',
        contributingFactors: validationErrors,
        recommendedAction: 'RESCHEDULE_BATCH',
        estimatedLossExposure: 0.0,
        predictedTransitMinutes: 0.0,
        etaDelayMinutes: 0.0,
        selectedRouteName: route.routeName,
        heatRiskLevel: RiskLevel.highRisk,
        travelRiskLevel: RiskLevel.highRisk,
        deliveryRiskLevel: RiskLevel.highRisk,
        expectedArrivalTime: '--:--',
        slaStatus: 'DATA_INSUFFICIENT',
        worstMaterialFactor: 'DATA INSUFFICIENT: Incomplete input telemetry',
        isDataInsufficient: true,
      );
    }

    // 2. Concrete Mix Kinetics & Retarder Buffering
    final grade = draft.concreteGrade.toUpperCase().trim();
    final gradeSens = concreteGradeSensitivities[grade] ?? 1.08;

    final hasRetarder = draft.admixtureRetarder != 'None' &&
        draft.admixtureRetarder.isNotEmpty &&
        !draft.admixtureRetarder.toLowerCase().contains('none');
    final retarderStrength = draft.admixtureRetarder.contains('0.6') ? 0.070 : (hasRetarder ? 0.045 : 0.0);

    // 3. Time-Based Delivery Window & Diurnal Exposure
    final dispatchMin = _parseTimeToMinutes(draft.dispatchTime);
    final arrivalMin = dispatchMin + totalTransitMin.toInt();
    final arrivalTimeStr = _formatMinutesToTime(arrivalMin);

    // Sample diurnal temperature offset & solar factor
    final step = 15;
    final slices = max(1, (totalTransitMin / step).toInt());
    final List<double> offsets = [];
    final List<double> solarFactors = [];

    for (int i = 0; i < slices; i++) {
      final curMin = (dispatchMin + i * step) % (24 * 60);
      final curHour = curMin / 60.0;
      if (curHour >= 11.5 && curHour <= 16.5) {
        offsets.add(2.5); // Peak midday heat
        solarFactors.add(1.30);
      } else if ((curHour >= 10.0 && curHour < 11.5) || (curHour > 16.5 && curHour <= 18.0)) {
        offsets.add(1.0);
        solarFactors.add(1.05);
      } else if (curHour >= 6.0 && curHour < 10.0) {
        offsets.add(-1.5);
        solarFactors.add(0.80);
      } else if (curHour > 18.0 && curHour <= 21.0) {
        offsets.add(-1.5);
        solarFactors.add(0.70);
      } else {
        offsets.add(-3.5); // Night
        solarFactors.add(0.50);
      }
    }

    final avgOffset = offsets.reduce((a, b) => a + b) / offsets.length;
    final avgSolar = solarFactors.reduce((a, b) => a + b) / solarFactors.length;
    final solarExposureIdx = double.parse((avgSolar * (totalTransitMin / 60.0)).toStringAsFixed(2));

    final effectiveAmbientTemp = double.parse((draft.ambientTempC + avgOffset).toStringAsFixed(1));
    final concreteTemp = draft.concreteTempC;

    // 4. Slump Retention Decay Kinetics
    final decayTime = totalTransitMin * 0.00115 * gradeSens;
    final decayConcTemp = max(0.0, concreteTemp - 30.0) * 0.0042 * gradeSens;
    final decayAmbTemp = max(0.0, effectiveAmbientTemp - 33.0) * 0.0028;
    final decayHumidity = max(0.0, 52.0 - draft.humidityPct) * 0.0006;

    double rawDecay = decayTime + decayConcTemp + decayAmbTemp + decayHumidity;
    if (hasRetarder) {
      rawDecay = max(0.015, rawDecay - retarderStrength);
    }

    final slumpRetention = double.parse((1.0 - rawDecay).clamp(0.68, 0.99).toStringAsFixed(3));
    final predictedSlumpMm = double.parse((draft.initialSlumpMm * slumpRetention).toStringAsFixed(1));

    // 5. Dimension 1: HEAT RISK (0 - 100)
    double heatScore = ((effectiveAmbientTemp - 28.0) / 16.0) * 45.0 +
        ((concreteTemp - 26.0) / 12.0) * 40.0 +
        (solarExposureIdx / 2.0) * 15.0;
    if (hasRetarder) {
      heatScore -= 16.0;
    }
    final heatRisk = double.parse(heatScore.clamp(10.0, 98.0).toStringAsFixed(1));

    RiskLevel heatRiskLevel;
    if (heatRisk >= 80.0) {
      heatRiskLevel = RiskLevel.critical;
    } else if (heatRisk >= 65.0) {
      heatRiskLevel = RiskLevel.highRisk;
    } else if (heatRisk >= 45.0) {
      heatRiskLevel = RiskLevel.watch;
    } else {
      heatRiskLevel = RiskLevel.safe;
    }

    // SAFEGUARD: Severe heat exposure cannot be SAFE
    if ((effectiveAmbientTemp >= 40.0 || concreteTemp >= 35.0) && totalTransitMin > 45.0) {
      if (heatRiskLevel == RiskLevel.safe) {
        heatRiskLevel = RiskLevel.watch;
      }
    }

    // 6. Dimension 2: TRAVEL RISK (0 - 100)
    const double slaMinutes = 78.0;
    final trafficComp = trafficIndex * 50.0;
    final delayComp = (delayMin / 25.0) * 35.0;
    final timeComp = max(0.0, (totalTransitMin - 60.0) / 20.0) * 30.0;

    final travelScore = trafficComp + delayComp + timeComp;
    double travelRisk = double.parse(travelScore.clamp(12.0, 98.0).toStringAsFixed(1));

    RiskLevel travelRiskLevel;
    String slaStatus;
    if (totalTransitMin > 85.0 || delayMin > 20.0) {
      travelRiskLevel = RiskLevel.critical;
      travelRisk = max(travelRisk, 84.0);
      slaStatus = 'CRITICAL_BREACH';
    } else if (totalTransitMin > slaMinutes || delayMin > 8.0) {
      travelRiskLevel = RiskLevel.highRisk;
      travelRisk = max(travelRisk, 70.0);
      slaStatus = 'BREACH';
    } else if (totalTransitMin > 65.0 || delayMin > 4.0 || trafficIndex > 0.60) {
      travelRiskLevel = RiskLevel.watch;
      travelRisk = max(travelRisk, 48.0);
      slaStatus = 'APPROACHING_LIMIT';
    } else {
      travelRiskLevel = RiskLevel.safe;
      slaStatus = 'COMPLIANT';
    }

    // SAFEGUARD: If transit > SLA, travelRisk CANNOT be SAFE!
    if (totalTransitMin > slaMinutes && travelRiskLevel == RiskLevel.safe) {
      travelRiskLevel = RiskLevel.highRisk;
      travelRisk = max(travelRisk, 70.0);
    }

    // 7. Dimension 3: DELIVERY / SLUMP RISK (0 - 100)
    const double safeSlumpMin = 0.92;
    final slumpDeficit = max(0.0, (safeSlumpMin - slumpRetention) / 0.15) * 60.0;
    final timeSlumpOverage = max(0.0, (totalTransitMin - slaMinutes) / 20.0) * 30.0;
    final precipPenalty = (precipProb / 100.0) * 15.0;

    final deliveryScore = slumpDeficit + timeSlumpOverage + precipPenalty + 18.0;
    double deliveryRisk = double.parse(deliveryScore.clamp(10.0, 98.0).toStringAsFixed(1));

    RiskLevel deliveryRiskLevel;
    if (slumpRetention < 0.85 || predictedSlumpMm < (draft.targetSlumpMm - 15.0)) {
      deliveryRiskLevel = RiskLevel.critical;
      deliveryRisk = max(deliveryRisk, 86.0);
    } else if (slumpRetention < safeSlumpMin || predictedSlumpMm < (draft.targetSlumpMm - 8.0)) {
      deliveryRiskLevel = RiskLevel.highRisk;
      deliveryRisk = max(deliveryRisk, 72.0);
    } else if (slumpRetention < 0.94 || totalTransitMin > 70.0) {
      deliveryRiskLevel = RiskLevel.watch;
      deliveryRisk = max(deliveryRisk, 48.0);
    } else {
      deliveryRiskLevel = RiskLevel.safe;
    }

    // SAFEGUARD: If predicted slump retention < 92%, deliveryRisk CANNOT be SAFE!
    if (slumpRetention < safeSlumpMin && deliveryRiskLevel == RiskLevel.safe) {
      deliveryRiskLevel = RiskLevel.highRisk;
      deliveryRisk = max(deliveryRisk, 72.0);
    }

    // 8. WORST MATERIAL FACTOR OPERATIONAL DECISION (PRD Section 3.4 & Prompt Section 5)
    int rankOf(RiskLevel level) {
      switch (level) {
        case RiskLevel.critical:
          return 4;
        case RiskLevel.highRisk:
          return 3;
        case RiskLevel.watch:
          return 2;
        case RiskLevel.safe:
          return 1;
      }
    }

    final dimLevels = [heatRiskLevel, travelRiskLevel, deliveryRiskLevel];
    final maxRank = dimLevels.map(rankOf).reduce(max);
    final watchCount = dimLevels.where((l) => l == RiskLevel.watch).length;
    final highCount = dimLevels.where((l) => l == RiskLevel.highRisk).length;
    final criticalCount = dimLevels.where((l) => l == RiskLevel.critical).length;

    RiskLevel decision;
    if (maxRank == 4 || criticalCount >= 1) {
      decision = RiskLevel.critical;
    } else if (maxRank == 3 || highCount >= 1) {
      if (highCount >= 2 && totalTransitMin > 85.0) {
        decision = RiskLevel.critical;
      } else {
        decision = RiskLevel.highRisk;
      }
    } else if (watchCount >= 2) {
      // Compounding: multiple WATCH dimensions elevate to HIGH RISK
      decision = RiskLevel.highRisk;
    } else if (maxRank == 2 || watchCount == 1) {
      decision = RiskLevel.watch;
    } else {
      decision = RiskLevel.safe;
    }

    // PRD Path A Strict Compliance Check
    final isPathAEligible = totalTransitMin <= slaMinutes &&
        slumpRetention >= safeSlumpMin &&
        delayMin <= 5.0 &&
        heatRiskLevel != RiskLevel.highRisk &&
        heatRiskLevel != RiskLevel.critical &&
        travelRiskLevel == RiskLevel.safe &&
        deliveryRiskLevel == RiskLevel.safe;

    if (!isPathAEligible && decision == RiskLevel.safe) {
      decision = (totalTransitMin <= slaMinutes && slumpRetention >= 0.90) ? RiskLevel.watch : RiskLevel.highRisk;
    }

    final isApproved = (decision == RiskLevel.safe);

    // Composite risk score reflects final decision level
    final weighted = 0.30 * heatRisk + 0.30 * travelRisk + 0.40 * deliveryRisk;
    double compositeRisk;
    if (decision == RiskLevel.critical) {
      compositeRisk = max(weighted, 82.0);
    } else if (decision == RiskLevel.highRisk) {
      compositeRisk = max(weighted, 68.0);
    } else if (decision == RiskLevel.watch) {
      compositeRisk = min(64.9, max(weighted, 45.0));
    } else {
      compositeRisk = min(38.0, weighted);
    }
    compositeRisk = double.parse(compositeRisk.toStringAsFixed(1));

    // Grounded Explainability & Fact-Based Drivers (WHY)
    final List<String> contributors = [];
    final List<String> worstFactors = [];

    if (totalTransitMin > slaMinutes) {
      final overage = (totalTransitMin - slaMinutes).toInt();
      contributors.add('Predicted transit (${totalTransitMin.toInt()} min) breaches 78 min operational SLA (+$overage min)');
      worstFactors.add('Transit duration SLA breach');
    } else if (totalTransitMin > 65.0) {
      contributors.add('Planned transit (${totalTransitMin.toInt()} min) approaches 78 min safe window');
    }

    if (delayMin > 0.0) {
      contributors.add('+${delayMin.toInt()} min traffic bottleneck delay along ${route.routeName}');
      if (delayMin > 8.0) worstFactors.add('Severe traffic delay (+${delayMin.toInt()}m)');
    }

    if (effectiveAmbientTemp >= 38.0) {
      contributors.add('${effectiveAmbientTemp.toStringAsFixed(1)}°C effective ambient heat during ${draft.dispatchTime}–$arrivalTimeStr window');
      worstFactors.add('High ambient heat exposure');
    } else if (effectiveAmbientTemp >= 35.0) {
      contributors.add('${effectiveAmbientTemp.toStringAsFixed(1)}°C elevated corridor temperature during transit');
    }

    if (concreteTemp >= 33.5) {
      contributors.add('${concreteTemp.toStringAsFixed(1)}°C concrete mix temperature accelerates hydration');
      if (concreteTemp >= 34.5) worstFactors.add('High concrete mix temperature');
    }

    if (slumpRetention < safeSlumpMin) {
      final lossPct = ((1.0 - slumpRetention) * 100).toStringAsFixed(1);
      contributors.add('Slump retention ${(slumpRetention * 100).toStringAsFixed(1)}% drops below 92.0% quality SLA (-$lossPct% loss)');
      worstFactors.add('Slump retention deficit (<92%)');
    } else {
      contributors.add('Predicted slump retention: ${(slumpRetention * 100).toStringAsFixed(1)}% ($predictedSlumpMm mm vs ${draft.targetSlumpMm.toInt()} mm target)');
    }

    if (grade == 'M40' || grade == 'M45') {
      contributors.add('$grade high-strength mix exhibits accelerated thermal hydration kinetics');
    }

    if (hasRetarder) {
      contributors.add('Chemical retarder (${draft.admixtureRetarder}) active; hydration window extended by +25 min');
    }

    if (precipProb > 25.0) {
      contributors.add('${precipProb.toInt()}% precipitation probability along route');
    }

    // Status Label & Primary Driver
    String statusLabel;
    String primaryDriver;
    String? recommendedAction;
    String worstMaterialFactor;

    if (decision == RiskLevel.safe) {
      statusLabel = 'DELIVERY ON TRACK';
      primaryDriver = 'Within operational tolerance (Transit <= 78m, Slump >= 92%)';
      worstMaterialFactor = 'None (All dimensions compliant)';
      recommendedAction = null;
    } else if (decision == RiskLevel.watch) {
      statusLabel = 'MONITOR CLOSELY';
      primaryDriver = worstFactors.isNotEmpty ? worstFactors.first : 'Approaching operational limits';
      worstMaterialFactor = worstFactors.isNotEmpty ? worstFactors.first : 'Thermal/transit margin';
      recommendedAction = null;
    } else if (decision == RiskLevel.highRisk) {
      statusLabel = 'HIGH DELIVERY RISK';
      primaryDriver = worstFactors.isNotEmpty ? worstFactors.first : 'Operational threshold violation';
      worstMaterialFactor = worstFactors.isNotEmpty ? worstFactors.first : 'Excessive transit / slump deterioration';
      if (totalTransitMin > slaMinutes || delayMin > 8.0) {
        recommendedAction = 'CALCULATE_NEW_ROUTE';
      } else if (heatRiskLevel == RiskLevel.highRisk && !hasRetarder) {
        recommendedAction = 'ADD_RETARDER';
      } else {
        recommendedAction = 'RESCHEDULE_BATCH';
      }
    } else {
      statusLabel = 'CRITICAL TRANSIT FAILURE IMMINENT';
      primaryDriver = worstFactors.isNotEmpty ? worstFactors.first : 'Critical quality & SLA breach';
      worstMaterialFactor = worstFactors.isNotEmpty ? worstFactors.first : 'Probable batch rejection';
      recommendedAction = 'CALCULATE_NEW_ROUTE';
    }

    final double rate = (grade == 'M15')
        ? 3600.0
        : ((grade == 'M20')
            ? 3950.0
            : ((grade == 'M25')
                ? 4350.0
                : ((grade == 'M30')
                    ? 4800.0
                    : ((grade == 'M35') ? 5300.0 : 5900.0))));
    final double materialVal = draft.volumeM3 * rate;
    final double transportVal = route.distanceKm * 75.0;
    final double disposalVal = draft.volumeM3 * 850.0;
    final double fullLossLiability = (materialVal * 2.0) + transportVal + disposalVal;
    final double lossExposure = fullLossLiability * (compositeRisk.clamp(0.0, 100.0) / 100.0);

    return DeliveryRiskAssessment(
      predictedSlumpMm: predictedSlumpMm,
      slumpRetentionRatio: slumpRetention,
      heatRisk: heatRisk,
      travelRisk: travelRisk,
      deliveryRisk: deliveryRisk,
      compositeRisk: compositeRisk,
      riskLevel: decision,
      isApproved: isApproved,
      statusLabel: statusLabel,
      primaryDriver: primaryDriver,
      contributingFactors: contributors,
      recommendedAction: recommendedAction,
      estimatedLossExposure: lossExposure,
      predictedTransitMinutes: totalTransitMin,
      etaDelayMinutes: delayMin,
      selectedRouteName: route.routeName,
      heatRiskLevel: heatRiskLevel,
      travelRiskLevel: travelRiskLevel,
      deliveryRiskLevel: deliveryRiskLevel,
      expectedArrivalTime: arrivalTimeStr,
      slaStatus: slaStatus,
      worstMaterialFactor: worstMaterialFactor,
      isDataInsufficient: false,
    );
  }
}
