import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/main.dart';
import 'package:mausam/models/batch.dart';
import 'package:mausam/models/delivery_order_draft.dart';
import 'package:mausam/features/auth/authentication_screen.dart';
import 'package:mausam/services/risk_engine_service.dart';
import 'package:mausam/services/weather_service.dart';

/// Exhaustive Test Suite for Section 32 Acceptance Tests A through J
void main() {
  group('MAUSAM — Section 32 Acceptance Tests A through J', () {
    late RiskEngineService riskEngine;
    late WeatherService weatherService;
    setUp(() {
      riskEngine = RiskEngineService();
      weatherService = WeatherService();
    });

    test('TEST A — SAFE DELIVERY: Transit <= 78m, Slump >= 92%, Moderate Weather -> SAFE', () async {
      final safeDraft = DeliveryOrderDraft(
        batchCode: 'RMC-SAFE',
        plantId: 'plant-001',
        plantName: 'Ahmedabad Plant 01',
        projectId: 'project-007',
        projectName: 'Gift City Tower B',
        concreteGrade: 'M25',
        volumeM3: 6.0,
        initialSlumpMm: 110.0,
        targetSlumpMm: 105.0,
        slumpRetentionRequirementPct: 92.0,
        concreteTempC: 30.0,
        ambientTempC: 32.0,
        humidityPct: 60.0,
        admixtureRetarder: 'None',
        selectedRouteId: 'route_b',
        dispatchTime: '08:30', // Morning cool
        plannedTransitMinutes: 52.0,
        expectedDelayMin: 4.0, // Total 56 min <= 78 min SLA
      );

      final assessment = await riskEngine.calculateRisk(safeDraft);

      expect(assessment.predictedTransitMinutes, lessThanOrEqualTo(78.0));
      expect(assessment.slumpRetentionRatio, greaterThanOrEqualTo(0.92));
      expect(assessment.travelRiskLevel, RiskLevel.safe);
      expect(assessment.overallRisk, 'SAFE');
      expect(assessment.riskLevel, RiskLevel.safe);
      expect(assessment.isApproved, isTrue);
    });

    test('TEST B — SLA BREACH: Transit 95 min > 78 min SLA -> Travel Risk HIGH, Overall != SAFE', () async {
      final breachDraft = DeliveryOrderDraft(
        batchCode: 'RMC-BREACH',
        plantId: 'plant-001',
        plantName: 'Ahmedabad Plant 01',
        projectId: 'project-007',
        projectName: 'Gift City Tower B',
        concreteGrade: 'M25',
        volumeM3: 6.0,
        initialSlumpMm: 120.0,
        targetSlumpMm: 100.0,
        slumpRetentionRequirementPct: 92.0,
        concreteTempC: 30.0,
        ambientTempC: 32.0,
        humidityPct: 60.0,
        admixtureRetarder: 'None',
        selectedRouteId: 'route_a',
        dispatchTime: '14:00',
        plannedTransitMinutes: 75.0,
        expectedDelayMin: 20.0, // Total 95 min > 78 min SLA!
      );

      final assessment = await riskEngine.calculateRisk(breachDraft);

      expect(assessment.predictedTransitMinutes, greaterThan(78.0));
      expect(assessment.travelRiskLevel, anyOf(RiskLevel.highRisk, RiskLevel.critical));
      expect(assessment.overallRisk, isNot('SAFE'));
      expect(assessment.riskLevel, anyOf(RiskLevel.highRisk, RiskLevel.critical));
      expect(assessment.isApproved, isFalse);
    });

    test('TEST C — LOW SLUMP: Transit 60 min, Slump Retention < 92% -> Delivery Risk HIGH, Overall != SAFE', () async {
      final lowSlumpDraft = DeliveryOrderDraft(
        batchCode: 'RMC-LOWSLUMP',
        plantId: 'plant-001',
        plantName: 'Ahmedabad Plant 01',
        projectId: 'project-007',
        projectName: 'Gift City Tower B',
        concreteGrade: 'M45', // High cementitious grade decays rapidly
        volumeM3: 6.0,
        initialSlumpMm: 100.0,
        targetSlumpMm: 95.0,
        slumpRetentionRequirementPct: 92.0,
        concreteTempC: 37.0, // Hot concrete accelerates decay
        ambientTempC: 41.0,
        humidityPct: 35.0,
        admixtureRetarder: 'None',
        selectedRouteId: 'route_b',
        dispatchTime: '14:00',
        plannedTransitMinutes: 55.0,
        expectedDelayMin: 5.0, // 60 min transit
      );

      final assessment = await riskEngine.calculateRisk(lowSlumpDraft);

      expect(assessment.slumpRetentionRatio, lessThan(0.92));
      expect(assessment.deliveryRiskLevel, anyOf(RiskLevel.highRisk, RiskLevel.critical));
      expect(assessment.overallRisk, isNot('SAFE'));
      expect(assessment.isApproved, isFalse);
    });

    test('TEST D — HIGH HEAT: Long transit & high environmental exposure elevates Heat Risk', () async {
      final heatDraft = DeliveryOrderDraft(
        batchCode: 'RMC-HEAT',
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
        ambientTempC: 42.0,
        humidityPct: 38.0,
        admixtureRetarder: 'None',
        selectedRouteId: 'route_a',
        dispatchTime: '14:00', // Midday solar peak
        plannedTransitMinutes: 70.0,
        expectedDelayMin: 5.0,
      );

      final assessment = await riskEngine.calculateRisk(heatDraft);

      expect(assessment.heatRisk, greaterThan(60.0));
      expect(assessment.heatRiskLevel, anyOf(RiskLevel.highRisk, RiskLevel.critical));
      expect(assessment.overallRisk, isNot('SAFE'));
    });

    test('TEST E — MULTI FACTOR: Heat, traffic, SLA breach & slump loss -> HIGH or CRITICAL, NEVER SAFE', () async {
      final compoundDraft = DeliveryOrderDraft(
        batchCode: 'RMC-COMPOUND',
        plantId: 'plant-001',
        plantName: 'Ahmedabad Plant 01',
        projectId: 'project-007',
        projectName: 'Gift City Tower B',
        concreteGrade: 'M40',
        volumeM3: 6.0,
        initialSlumpMm: 110.0,
        targetSlumpMm: 100.0,
        slumpRetentionRequirementPct: 92.0,
        concreteTempC: 36.0,
        ambientTempC: 41.5,
        humidityPct: 40.0,
        admixtureRetarder: 'None',
        selectedRouteId: 'route_a',
        dispatchTime: '14:00',
        plannedTransitMinutes: 75.0,
        expectedDelayMin: 20.0, // 95 min
      );

      final assessment = await riskEngine.calculateRisk(compoundDraft);

      expect(assessment.overallRisk, anyOf('HIGH', 'CRITICAL'));
      expect(assessment.riskLevel, anyOf(RiskLevel.highRisk, RiskLevel.critical));
      expect(assessment.isApproved, isFalse);
    });

    test('TEST F — MISSING DATA: Incomplete inputs -> RISK UNAVAILABLE, NEVER SAFE', () async {
      final missingDraft = DeliveryOrderDraft(
        batchCode: '',
        plantId: '',
        plantName: '',
        projectId: '',
        projectName: '',
        concreteGrade: '',
        volumeM3: 0.0,
        initialSlumpMm: 0.0,
        targetSlumpMm: 0.0,
        slumpRetentionRequirementPct: 0.0,
        concreteTempC: 0.0,
        ambientTempC: 0.0,
        humidityPct: 0.0,
        admixtureRetarder: 'None',
        selectedRouteId: 'route_a',
      );

      final assessment = await riskEngine.calculateRisk(missingDraft);

      expect(assessment.isDataInsufficient, isTrue);
      expect(assessment.overallRisk, isNot('SAFE'));
      expect(assessment.statusLabel, contains('DATA INSUFFICIENT'));
      expect(assessment.worstMaterialFactor, contains('DATA INSUFFICIENT'));
    });

    test('TEST G — WEATHER CONSISTENCY: Same location and time yields identical telemetry', () {
      final snap1 = weatherService.getDeterministicWeather(
        location: 'Ahmedabad Central Corridor',
        timeOfDay: '14:00',
      );
      final snap2 = weatherService.getDeterministicWeather(
        location: 'Ahmedabad Central Corridor',
        timeOfDay: '14:00',
      );

      expect(snap1.ambientTempC, equals(snap2.ambientTempC));
      expect(snap1.humidityPct, equals(snap2.humidityPct));
      expect(snap1.precipitationProbabilityPct, equals(snap2.precipitationProbabilityPct));
      expect(snap1.weatherCondition, equals(snap2.weatherCondition));
      expect(snap1.apparentTempC, equals(snap2.apparentTempC));
    });

    testWidgets('TEST H — AUTH: Contains credentials only, NO weather, NO RMC telemetry', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthenticationScreen(
            onBackToLanding: () {},
            onSignIn: (e, p) {},
            onSignUp: (n, e, p) {},
            onGoogleSignIn: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified credentials fields exist
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byType(TextField), findsAtLeastNWidgets(2)); // Email & Password

      // Verified ZERO weather / RMC telemetry appears
      expect(find.textContaining('°C'), findsNothing);
      expect(find.textContaining('Slump'), findsNothing);
      expect(find.textContaining('Telemetry'), findsNothing);
      expect(find.textContaining('RMC'), findsNothing);
    });

    testWidgets('TEST I — RESPONSIVE: Renders cleanly across phone, tablet, and desktop viewports', (tester) async {
      // 1. Mobile (360px)
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MausamApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('MAUSAM'), findsOneWidget);

      // 2. Tablet (768px)
      tester.view.physicalSize = const Size(768, 1024);
      await tester.pumpWidget(const MausamApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 3. Desktop (1280px)
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpWidget(const MausamApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('TEST J — NAVIGATION: Hero -> Auth -> Role -> App with working Back transitions', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MausamApp());
      await tester.pumpAndSettle();

      // 1. Start at Hero/Landing
      expect(find.text('Weather Intelligence\nfor Every Decision.'), findsOneWidget);

      // 2. Navigate to Auth
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);

      // 3. Back to Landing works
      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();
      expect(find.text('Weather Intelligence\nfor Every Decision.'), findsOneWidget);

      // 4. Navigate back to Auth and Sign In
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      final signInBtn = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.ensureVisible(signInBtn);
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      // 5. Dedicated RBAC Role Selection Screen
      expect(find.text('How are you using Mausam?'), findsOneWidget);
      final launchBtn = find.text('Launch RMC Command Center');
      await tester.ensureVisible(launchBtn);
      await tester.tap(launchBtn);
      await tester.pumpAndSettle();

      // 6. Operational RMC App Loaded
      expect(find.text('Ahmedabad Central Corridor'), findsOneWidget);
      expect(find.text('Create Delivery'), findsOneWidget);

      // 7. Start Create Delivery
      await tester.tap(find.text('Create Delivery'));
      await tester.pumpAndSettle();
      expect(find.text('Create RMC Delivery Order'), findsOneWidget);
      expect(find.text('Calculate Delivery Risk'), findsOneWidget);
    });
  });
}
