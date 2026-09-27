import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/models/batch.dart';
import 'package:mausam/models/delivery_order_draft.dart';
import 'package:mausam/services/risk_engine_service.dart';

void main() {
  group('MAUSAM — RMC Risk Engine Logic & Anti-False-Green Safeguards', () {
    late RiskEngineService riskEngine;

    setUp(() {
      riskEngine = RiskEngineService();
    });

    // =========================================================================
    // TEST 1 — SAFE (Path A in PRD)
    // =========================================================================
    test('TEST 1: Safe Path — Transit <= 78m, Slump >= 92%, On-time ETA, Moderate Weather evaluates to SAFE', () async {
      final safeDraft = DeliveryOrderDraft(
        batchCode: 'RMC-SAFE-01',
        plantId: 'plant-001',
        plantName: 'Ahmedabad Plant 01',
        projectId: 'project-007',
        projectName: 'Gift City Tower B',
        concreteGrade: 'M25',
        volumeM3: 6.0,
        initialSlumpMm: 125.0,
        targetSlumpMm: 110.0,
        slumpRetentionRequirementPct: 92.0,
        concreteTempC: 28.0,
        ambientTempC: 30.0,
        humidityPct: 65.0,
        admixtureRetarder: '0.4% by wt',
        selectedRouteId: 'route_b',
        dispatchTime: '08:30',
        plannedTransitMinutes: 50.0,
        expectedDelayMin: 2.0,
      );

      final assessment = await riskEngine.calculateRisk(safeDraft);

      expect(assessment.predictedTransitMinutes, lessThanOrEqualTo(78.0));
      expect(assessment.slumpRetentionRatio, greaterThanOrEqualTo(0.92));
      expect(assessment.slaStatus, anyOf('ON_TIME', 'COMPLIANT'));
      expect(assessment.travelRiskLevel, RiskLevel.safe);
      expect(assessment.deliveryRiskLevel, RiskLevel.safe);
      expect(assessment.heatRiskLevel, RiskLevel.safe);
      expect(assessment.overallRisk, 'SAFE');
      expect(assessment.riskLevel, RiskLevel.safe);
    });

    // =========================================================================
    // TEST 2 — SLA BREACH
    // =========================================================================
    test('TEST 2: SLA Breach — Planned Transit 95 min > 78 min SLA MUST produce Travel Risk HIGH and Overall Risk != SAFE', () async {
      final slaBreachDraft = DeliveryOrderDraft(
        batchCode: 'RMC-SLA-BREACH',
        plantId: 'plant-001',
        plantName: 'Ahmedabad Plant 01',
        projectId: 'project-007',
        projectName: 'Gift City Tower B',
        concreteGrade: 'M25',
        volumeM3: 6.0,
        initialSlumpMm: 130.0,
        targetSlumpMm: 100.0,
        slumpRetentionRequirementPct: 92.0,
        concreteTempC: 30.0,
        ambientTempC: 32.0,
        humidityPct: 60.0,
        admixtureRetarder: 'None',
        selectedRouteId: 'route_a',
        dispatchTime: '10:30',
        plannedTransitMinutes: 80.0,
        expectedDelayMin: 15.0, // Total = 95 min
      );

      final assessment = await riskEngine.calculateRisk(slaBreachDraft);

      expect(assessment.predictedTransitMinutes, 95.0);
      expect(assessment.slaStatus, anyOf('BREACH', 'CRITICAL_BREACH'));
      expect(assessment.travelRiskLevel, anyOf(RiskLevel.highRisk, RiskLevel.critical));
      expect(assessment.overallRisk, isNot('SAFE'));
      expect(assessment.worstMaterialFactor, contains('SLA breach'));
    });

    // =========================================================================
    // TEST 3 — SLUMP FAILURE
    // =========================================================================
    test('TEST 3: Slump Failure — Predicted Slump Retention < 92% MUST produce Delivery Risk HIGH and Overall Risk != SAFE', () async {
      final slumpFailureDraft = DeliveryOrderDraft(
        batchCode: 'RMC-SLUMP-FAIL',
        plantId: 'plant-001',
        plantName: 'Ahmedabad Plant 01',
        projectId: 'project-007',
        projectName: 'Gift City Tower B',
        concreteGrade: 'M40', // High grade faster decay
        volumeM3: 6.0,
        initialSlumpMm: 100.0,
        targetSlumpMm: 95.0,
        slumpRetentionRequirementPct: 92.0,
        concreteTempC: 36.0,
        ambientTempC: 38.0,
        humidityPct: 40.0,
        admixtureRetarder: 'None',
        selectedRouteId: 'route_a',
        dispatchTime: '14:00',
        plannedTransitMinutes: 70.0,
        expectedDelayMin: 0.0,
      );

      final assessment = await riskEngine.calculateRisk(slumpFailureDraft);

      expect(assessment.slumpRetentionRatio, lessThan(0.92));
      expect(assessment.deliveryRiskLevel, anyOf(RiskLevel.highRisk, RiskLevel.critical));
      expect(assessment.overallRisk, isNot('SAFE'));
    });

    // =========================================================================
    // TEST 4 — HEAT EXPOSURE
    // =========================================================================
    test('TEST 4: Heat Exposure — High temperature & solar peak MUST elevate Heat Risk and Worst Factor', () async {
      final highHeatDraft = DeliveryOrderDraft(
        batchCode: 'RMC-HEAT-01',
        plantId: 'plant-001',
        plantName: 'Ahmedabad Plant 01',
        projectId: 'project-007',
        projectName: 'Gift City Tower B',
        concreteGrade: 'M35',
        volumeM3: 6.0,
        initialSlumpMm: 120.0,
        targetSlumpMm: 100.0,
        slumpRetentionRequirementPct: 92.0,
        concreteTempC: 36.5,
        ambientTempC: 41.5,
        humidityPct: 35.0,
        admixtureRetarder: 'None',
        selectedRouteId: 'route_b',
        dispatchTime: '14:00', // Midday solar peak (+2.5°C offset)
        plannedTransitMinutes: 65.0,
        expectedDelayMin: 5.0,
      );

      final assessment = await riskEngine.calculateRisk(highHeatDraft);

      expect(assessment.heatRiskLevel, anyOf(RiskLevel.highRisk, RiskLevel.critical));
      expect(assessment.overallRisk, isNot('SAFE'));
    });

    // =========================================================================
    // TEST 5 — MULTI-FACTOR FAILURE (Worst Material Factor Principle)
    // =========================================================================
    test('TEST 5: Multi-Factor — Heat, Travel delay, and Slump loss compound to HIGH or CRITICAL, absolutely NOT SAFE', () async {
      final multiFactorDraft = DeliveryOrderDraft(
        batchCode: 'RMC-MULTI-FAIL',
        plantId: 'plant-001',
        plantName: 'Ahmedabad Plant 01',
        projectId: 'project-007',
        projectName: 'Gift City Tower B',
        concreteGrade: 'M40',
        volumeM3: 6.0,
        initialSlumpMm: 110.0,
        targetSlumpMm: 95.0,
        slumpRetentionRequirementPct: 92.0,
        concreteTempC: 37.0,
        ambientTempC: 42.0,
        humidityPct: 35.0,
        admixtureRetarder: 'None',
        selectedRouteId: 'route_a',
        dispatchTime: '14:00',
        plannedTransitMinutes: 75.0,
        expectedDelayMin: 22.0, // 97 min total
      );

      final assessment = await riskEngine.calculateRisk(multiFactorDraft);

      expect(assessment.overallRisk, anyOf('HIGH RISK', 'HIGH', 'CRITICAL'));
      expect(assessment.riskLevel, anyOf(RiskLevel.highRisk, RiskLevel.critical));
      expect(assessment.isApproved, isFalse);
      expect(assessment.groundedDrivers.length, greaterThanOrEqualTo(2));
    });

    // =========================================================================
    // TEST 6 — MITIGATION APPLICATION
    // =========================================================================
    test('TEST 6: Mitigation — Route B bypass + chemical retarder reduces transit and risk score', () async {
      final congestedDraft = DeliveryOrderDraft(
        batchCode: 'RMC-ROUTE-A',
        plantId: 'plant-001',
        plantName: 'Ahmedabad Plant 01',
        projectId: 'project-007',
        projectName: 'Gift City Tower B',
        concreteGrade: 'M30',
        volumeM3: 6.0,
        initialSlumpMm: 120.0,
        targetSlumpMm: 100.0,
        slumpRetentionRequirementPct: 92.0,
        concreteTempC: 33.0,
        ambientTempC: 35.0,
        humidityPct: 55.0,
        admixtureRetarder: 'None',
        selectedRouteId: 'route_a', // Direct via SP Ring Road with Nana Chiloda bottleneck
        dispatchTime: '11:30',
        plannedTransitMinutes: 69.0,
        expectedDelayMin: 17.0, // Total 86 min (SLA breach)
      );

      final assessmentA = await riskEngine.calculateRisk(congestedDraft);
      expect(assessmentA.predictedTransitMinutes, 86.0);
      expect(assessmentA.slaStatus, anyOf('BREACH', 'CRITICAL_BREACH'));

      // Apply mitigation: Switch to Route B + add retarder
      final mitigatedDraft = congestedDraft.copyWith(
        selectedRouteId: 'route_b',
        admixtureRetarder: '0.4% by wt',
        plannedTransitMinutes: 58.0,
        expectedDelayMin: 2.0, // Total 60 min (< 78m SLA)
      );

      final assessmentB = await riskEngine.calculateRisk(mitigatedDraft);
      expect(assessmentB.predictedTransitMinutes, 60.0);
      expect(assessmentB.slaStatus, anyOf('ON_TIME', 'COMPLIANT'));
      expect(assessmentB.compositeRiskScore, lessThan(assessmentA.compositeRiskScore));
      expect(assessmentB.slumpRetentionRatio, greaterThan(assessmentA.slumpRetentionRatio));
    });

    // =========================================================================
    // TEST 7 — RMC CONCRETE GRADE SENSITIVITY
    // =========================================================================
    test('TEST 7: RMC Grade Sensitivity — Higher cementitious grade (M45) exhibits accelerated slump loss vs M20', () async {
      final baseDraft = DeliveryOrderDraft(
        batchCode: 'RMC-COMPARE',
        plantId: 'plant-001',
        plantName: 'Ahmedabad Plant 01',
        projectId: 'project-007',
        projectName: 'Gift City Tower B',
        concreteGrade: 'M20',
        volumeM3: 6.0,
        initialSlumpMm: 120.0,
        targetSlumpMm: 100.0,
        slumpRetentionRequirementPct: 92.0,
        concreteTempC: 32.0,
        ambientTempC: 34.0,
        humidityPct: 55.0,
        admixtureRetarder: 'None',
        selectedRouteId: 'route_b',
        dispatchTime: '11:30',
        plannedTransitMinutes: 65.0,
        expectedDelayMin: 0.0,
      );

      final assessmentM20 = await riskEngine.calculateRisk(baseDraft.copyWith(concreteGrade: 'M20'));
      final assessmentM45 = await riskEngine.calculateRisk(baseDraft.copyWith(concreteGrade: 'M45'));

      expect(assessmentM45.slumpRetentionRatio, lessThan(assessmentM20.slumpRetentionRatio));
      expect(assessmentM45.deliveryRisk, greaterThanOrEqualTo(assessmentM20.deliveryRisk));
    });

    // =========================================================================
    // TEST 8 — TIME-OF-DAY DIURNAL EXPOSURE WINDOW
    // =========================================================================
    test('TEST 8: Diurnal Solar Heat Exposure — Midday 14:00 dispatch produces higher heat risk than 08:30 morning', () async {
      final baseDraft = DeliveryOrderDraft(
        batchCode: 'RMC-DIURNAL',
        plantId: 'plant-001',
        plantName: 'Ahmedabad Plant 01',
        projectId: 'project-007',
        projectName: 'Gift City Tower B',
        concreteGrade: 'M30',
        volumeM3: 6.0,
        initialSlumpMm: 120.0,
        targetSlumpMm: 100.0,
        slumpRetentionRequirementPct: 92.0,
        concreteTempC: 32.0,
        ambientTempC: 35.0,
        humidityPct: 50.0,
        admixtureRetarder: 'None',
        selectedRouteId: 'route_b',
        plannedTransitMinutes: 60.0,
        expectedDelayMin: 0.0,
      );

      final assessmentMorning = await riskEngine.calculateRisk(baseDraft.copyWith(dispatchTime: '08:30'));
      final assessmentMidday = await riskEngine.calculateRisk(baseDraft.copyWith(dispatchTime: '14:00'));

      expect(assessmentMidday.heatRisk, greaterThan(assessmentMorning.heatRisk));
    });

    // =========================================================================
    // TEST 9 — EDGE CASES & INSUFFICIENT DATA SAFEGUARDS
    // =========================================================================
    test('TEST 9: Edge Cases — Missing mandatory parameters MUST flag DATA INSUFFICIENT, NEVER SAFE', () async {
      final invalidDraft = DeliveryOrderDraft(
        batchCode: '',
        plantId: '',
        plantName: '',
        projectId: '',
        projectName: '',
        concreteGrade: 'M30',
        volumeM3: 0.0,
        initialSlumpMm: 120.0,
        targetSlumpMm: 100.0,
        slumpRetentionRequirementPct: 92.0,
        concreteTempC: 0.0,
        ambientTempC: 0.0,
        humidityPct: 0.0,
        admixtureRetarder: 'None',
        selectedRouteId: 'route_b',
      );

      final assessment = await riskEngine.calculateRisk(invalidDraft);

      expect(assessment.isDataInsufficient, isTrue);
      expect(assessment.overallRisk, isNot('SAFE'));
      expect(assessment.riskLevel, anyOf(RiskLevel.highRisk, RiskLevel.critical));
      expect(assessment.worstMaterialFactor, contains('DATA INSUFFICIENT'));
      expect(assessment.groundedDrivers.isNotEmpty, isTrue);
    });
  });
}
