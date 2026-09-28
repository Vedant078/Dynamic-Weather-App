import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/models/batch.dart';
import 'package:mausam/state/mausam_state.dart';

void main() {
  group('MAUSAM Golden Demo RMC Workflow', () {
    late MausamState state;

    setUp(() {
      state = MausamState();
    });

    test('Step 0: Initial Dispatch State is SAFE and Approved (PRD.md Section 3.2)', () {
      final batch = state.selectedBatch;
      expect(batch.batchCode, 'RMC-204');
      expect(batch.riskLevel, RiskLevel.safe);
      // Transit <= 78 min
      expect(batch.totalTransitMinutes, lessThanOrEqualTo(78.0));
      // Slump retention >= 92%
      expect(batch.slumpRetentionRatio, greaterThanOrEqualTo(0.92));
      // Evaluates to APPROVED
      expect(batch.isApproved, isTrue);
      expect(batch.concreteTempC, lessThanOrEqualTo(34.0));
    });

    test('Step 1: Moderate Traffic Transition increases Travel Risk to WATCH', () {
      state.setSimulationStep(1);
      final batch = state.selectedBatch;
      expect(batch.riskLevel, RiskLevel.watch);
      expect(batch.travelRisk, greaterThan(40));
      expect(batch.primaryDriver, contains('Traffic congestion'));
    });

    test('Step 2: Adverse Weather and Congestion triggers HIGH RISK & Exceeds Thresholds', () {
      state.setSimulationStep(2);
      final batch = state.selectedBatch;
      expect(batch.riskLevel, RiskLevel.highRisk);
      // Transit exceeds 78 min safe window (82 min)
      expect(batch.totalTransitMinutes, greaterThan(78.0));
      // Slump retention drops below 92% (89.1%)
      expect(batch.slumpRetentionRatio, lessThan(0.92));
      // No longer approved
      expect(batch.isApproved, isFalse);
      expect(batch.primaryDriver, contains('Transit delay'));
      expect(batch.recommendedAction, 'CALCULATE_NEW_ROUTE');
    });

    test('Step 3: Human-in-the-Loop Reroute to Route B restores batch to SAFE', () async {
      // Transition to high risk first
      state.setSimulationStep(2);
      expect(state.selectedBatch.riskLevel, RiskLevel.highRisk);

      // Execute Route B rerouting decision
      await state.applyAlternativeRoute();
      final batch = state.selectedBatch;

      // Restored within safe transit window (< 78 min) and safe retention (>= 92%)
      expect(batch.totalTransitMinutes, lessThanOrEqualTo(78.0));
      expect(batch.slumpRetentionRatio, greaterThanOrEqualTo(0.92));
      expect(batch.isApproved, isTrue);
      expect(batch.riskLevel, RiskLevel.safe);
      expect(batch.activeRouteId, 'route-b');
      expect(batch.primaryDriver, contains('Expressway applied'));
    });

    test('Step 4: Delivery Outcome records slump quality and avoided loss', () async {
      await state.submitOutcome(
        outcome: 'accepted',
        siteSlumpMm: 101.5,
        transitMinutes: 66.0,
        concreteTempC: 34.0,
      );

      final batch = state.selectedBatch;
      expect(batch.status, 'DELIVERED');
      expect(batch.distanceRemainingKm, 0.0);
      expect(state.outcomes.isNotEmpty, isTrue);

      final outcome = state.outcomes.first;
      expect(outcome.batchId, 'batch-rmc-204');
      expect(outcome.outcome, 'accepted');
      expect(outcome.financialImpactInr, greaterThan(0.0));
      expect(outcome.mlTrainingRecorded, isTrue);
    });
  });
}
