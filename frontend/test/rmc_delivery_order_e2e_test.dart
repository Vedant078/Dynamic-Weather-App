import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/main.dart';
import 'package:mausam/models/batch.dart';
import 'package:mausam/models/delivery_order_draft.dart';
import 'package:mausam/services/risk_engine_service.dart';
import 'package:mausam/state/mausam_state.dart';

void main() {
  group('MAUSAM — RMC Delivery Order Lifecycle & Risk Calculation Test', () {
    late MausamState state;
    late RiskEngineService riskEngine;

    setUp(() {
      state = MausamState();
      riskEngine = RiskEngineService();
    });

    test('Risk Engine calculates grounded slump kinetics and 3D risk dimensions', () async {
      final draftHighRisk = DeliveryOrderDraft(
        batchCode: 'RMC-205',
        plantId: 'plant-001',
        plantName: 'Ahmedabad Plant 01',
        projectId: 'project-007',
        projectName: 'Gift City Tower B',
        concreteGrade: 'M35',
        volumeM3: 6.0,
        initialSlumpMm: 120.0,
        targetSlumpMm: 100.0,
        slumpRetentionRequirementPct: 92.0,
        concreteTempC: 34.8,
        ambientTempC: 38.5,
        admixtureRetarder: 'None',
        selectedRouteId: 'route_a', // Direct via SP Ring Road with Nana Chiloda bottleneck
      );

      final assessmentRouteA = await riskEngine.calculateRisk(draftHighRisk);

      // Verify input -> calculation -> output relationships
      expect(assessmentRouteA.predictedTransitMinutes, greaterThan(65.0));
      expect(assessmentRouteA.overallRisk, anyOf('HIGH', 'CRITICAL', 'WATCH'));
      expect(assessmentRouteA.heatRisk, greaterThan(30.0));
      expect(assessmentRouteA.travelRisk, greaterThan(50.0));
      expect(assessmentRouteA.groundedDrivers.length, greaterThanOrEqualTo(2));

      // Test Route B alternative (Airport Bypass avoids bottleneck)
      final draftRouteB = draftHighRisk.copyWith(
        selectedRouteId: 'route_b',
        admixtureRetarder: '0.4% by wt',
      );

      final assessmentRouteB = await riskEngine.calculateRisk(draftRouteB);

      expect(assessmentRouteB.predictedTransitMinutes, lessThan(assessmentRouteA.predictedTransitMinutes));
      expect(assessmentRouteB.slumpRetentionRatio, greaterThan(assessmentRouteA.slumpRetentionRatio));
      expect(assessmentRouteB.travelRisk, lessThan(assessmentRouteA.travelRisk));
    });

    test('State management handles complete delivery creation, dispatch, and outcome logging', () async {
      final initialCount = state.batches.length;

      // 1. Dispatcher initiates delivery creation
      state.startCreateDelivery();
      expect(state.isCreatingDelivery, isTrue);
      expect(state.currentDraft.batchCode, contains('RMC-'));

      // 2. Dispatcher enters concrete parameters
      final draft = state.currentDraft.copyWith(
        batchCode: 'RMC-205',
        plantName: 'Ahmedabad Plant 01',
        projectName: 'Gift City Tower B',
        concreteGrade: 'M35',
        volumeM3: 6.0,
        selectedRouteId: 'route_b',
      );
      state.updateDeliveryDraft(draft);
      expect(state.currentDraft.batchCode, 'RMC-205');

      // 3. Dispatcher calculates risk
      final risk = await state.calculateDeliveryRisk(draft);
      expect(state.currentDraftRisk, isNotNull);
      expect(risk.selectedRouteName, contains('Airport Bypass'));

      // 4. Dispatcher confirms dispatch
      final dispatchedBatch = await state.confirmAndDispatchDelivery(draft, risk);
      expect(state.isCreatingDelivery, isFalse);
      expect(state.batches.length, initialCount + 1);
      expect(state.batches.first.batchCode, 'RMC-205');
      expect(state.selectedBatch.batchCode, 'RMC-205');
      expect(dispatchedBatch.status, 'DISPATCHED');
      expect(dispatchedBatch.concreteGrade, 'M35');

      // 5. Operator records arrival outcome
      await state.submitOutcome(
        outcome: 'accepted',
        siteSlumpMm: 98.0,
        transitMinutes: 58.0,
        concreteTempC: 33.2,
      );

      expect(state.selectedBatch.status, 'DELIVERED');
      expect(state.selectedBatch.riskLevel, RiskLevel.safe);
      expect(state.outcomes.length, greaterThanOrEqualTo(1));
      expect(state.outcomes.first.batchId, contains('rmc-205'));
    });

    testWidgets('Full User Journey UI: Landing -> Auth -> RBAC -> RMC -> Create Delivery -> Dispatch', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MausamApp());
      await tester.pumpAndSettle();

      // Step 1 & 2: Landing page renders
      expect(find.text('Weather Intelligence\nfor Every Decision.'), findsOneWidget);

      // Step 3: Click Sign In
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Step 4: Authentication screen renders credentials-only form
      expect(find.text('Welcome back'), findsOneWidget);
      final signInBtn = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.ensureVisible(signInBtn);
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      // Step 5: RBAC Role Selection Screen renders
      expect(find.text('How are you using Mausam?'), findsOneWidget);

      // Step 6: Select Launch RMC Command Center
      final launchBtn = find.text('Launch RMC Command Center');
      await tester.ensureVisible(launchBtn);
      await tester.tap(launchBtn);
      await tester.pumpAndSettle();

      // Step 7: We are inside RMC Logistics Command Center!
      expect(find.text('RMC Logistics'), findsWidgets);
      expect(find.text('Create Delivery'), findsOneWidget);

      // Step 8: Click Create Delivery
      await tester.tap(find.text('Create Delivery'));
      await tester.pumpAndSettle();

      // Step 9: Create Delivery Screen is presented
      expect(find.text('Create RMC Delivery Order'), findsOneWidget);
      expect(find.text('Delivery Information'), findsOneWidget);
      expect(find.text('Concrete / RMC Mix Specification'), findsOneWidget);
      expect(find.text('Route Corridors & Bottleneck Tradeoffs'), findsOneWidget);
      expect(find.text('Calculate Delivery Risk'), findsOneWidget);

      // Step 10: Tap Calculate Delivery Risk
      await tester.tap(find.text('Calculate Delivery Risk'));
      await tester.pumpAndSettle();

      // Step 11: Risk assessment results render
      expect(find.text('Contributing Risk Dimensions'), findsOneWidget);
      expect(find.text('Heat Risk'), findsOneWidget);
      expect(find.text('Travel Risk'), findsOneWidget);
      expect(find.text('Delivery Risk'), findsOneWidget);

      // Step 12: Confirm Dispatch
      final confirmBtn = find.textContaining('Confirm Dispatch');
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Step 13: Delivery is dispatched and live telemetry is active!
      expect(find.textContaining('Batch #'), findsWidgets);
    });
  });
}
