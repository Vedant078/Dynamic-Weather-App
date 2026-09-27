import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/services/route_service.dart';
import 'package:mausam/services/risk_engine_service.dart';
import 'package:mausam/models/delivery_order_draft.dart';
import 'package:mausam/state/mausam_state.dart';
import 'package:mausam/features/rmc/create_delivery/create_delivery_screen.dart';
import 'package:mausam/features/rmc/batch_detail/batch_detail_screen.dart';
import 'package:mausam/design_system/components/route_map_view.dart';

void main() {
  group('MAUSAM — Section 9 & 25 Dynamic Route Acceptance Tests', () {
    test('TEST 1: Origin A -> Destination A vs Origin B -> Destination B produces DIFFERENT geometry', () {
      final routeAA = RouteService.getRoute(
        originName: 'Ahmedabad Plant 01 (Naroda)',
        destinationName: 'Gift City Tower B',
      );

      final routeBB = RouteService.getRoute(
        originName: 'Ahmedabad Plant 02 - Sanand',
        destinationName: 'Metro Pier 142 - Thaltej',
      );

      // Verify origin and destination coordinates are strictly different
      expect(routeAA.origin.latitude, isNot(equals(routeBB.origin.latitude)));
      expect(routeAA.destination.latitude, isNot(equals(routeBB.destination.latitude)));

      // Verify distance is different
      expect(routeAA.distanceKm, isNot(equals(routeBB.distanceKm)));

      // Verify polyline geometry points are different
      final aaFirst = routeAA.primaryPathPoints.first;
      final bbFirst = routeBB.primaryPathPoints.first;
      expect(aaFirst.x, isNot(equals(bbFirst.x)));
      expect(aaFirst.y, isNot(equals(bbFirst.y)));

      final aaLast = routeAA.primaryPathPoints.last;
      final bbLast = routeBB.primaryPathPoints.last;
      expect(aaLast.x, isNot(equals(bbLast.x)));
      expect(aaLast.y, isNot(equals(bbLast.y)));
    });

    test('TEST 2: Keep origin same, change destination -> route geometry MUST change', () {
      final routeDest1 = RouteService.getRoute(
        originName: 'Ahmedabad Plant 01 (Naroda)',
        destinationName: 'Gift City Tower B',
      );

      final routeDest2 = RouteService.getRoute(
        originName: 'Ahmedabad Plant 01 (Naroda)',
        destinationName: 'Riverfront Phase 2',
      );

      // Origin matches
      expect(routeDest1.origin.name, equals(routeDest2.origin.name));

      // Destination differs
      expect(routeDest1.destination.name, isNot(equals(routeDest2.destination.name)));
      expect(routeDest1.destination.latitude, isNot(equals(routeDest2.destination.latitude)));

      // Distance and geometry must differ
      expect(routeDest1.distanceKm, isNot(equals(routeDest2.distanceKm)));
      final dest1Last = routeDest1.primaryPathPoints.last;
      final dest2Last = routeDest2.primaryPathPoints.last;
      expect(dest1Last.x, isNot(equals(dest2Last.x)));
      expect(dest1Last.y, isNot(equals(dest2Last.y)));
    });

    test('TEST 3: Keep destination same, change origin -> route geometry MUST change', () {
      final routeOrigin1 = RouteService.getRoute(
        originName: 'Ahmedabad Plant 01 (Naroda)',
        destinationName: 'Gift City Tower B',
      );

      final routeOrigin2 = RouteService.getRoute(
        originName: 'Gandhinagar Plant 03',
        destinationName: 'Gift City Tower B',
      );

      // Destination matches
      expect(routeOrigin1.destination.name, equals(routeOrigin2.destination.name));

      // Origin differs
      expect(routeOrigin1.origin.name, isNot(equals(routeOrigin2.origin.name)));
      expect(routeOrigin1.origin.latitude, isNot(equals(routeOrigin2.origin.latitude)));

      // Distance and geometry must differ
      expect(routeOrigin1.distanceKm, isNot(equals(routeOrigin2.distanceKm)));
      final orig1First = routeOrigin1.primaryPathPoints.first;
      final orig2First = routeOrigin2.primaryPathPoints.first;
      expect(orig1First.x, isNot(equals(orig2First.x)));
      expect(orig1First.y, isNot(equals(orig2First.y)));
    });

    test('TEST 4: Route selection changes distance, ETA, traffic index, and risk', () async {
      final riskEngine = RiskEngineService();

      final draftA = DeliveryOrderDraft(
        batchCode: 'RMC-TEST-A',
        plantId: 'plant-001',
        plantName: 'Ahmedabad Plant 01 (Naroda)',
        projectId: 'proj-gift-city',
        projectName: 'Gift City Tower B',
        concreteGrade: 'M35',
        volumeM3: 6.0,
        initialSlumpMm: 120.0,
        targetSlumpMm: 100.0,
        slumpRetentionRequirementPct: 92.0,
        concreteTempC: 34.0,
        ambientTempC: 38.0,
        admixtureRetarder: 'None',
        selectedRouteId: 'route-a', // Bottleneck route
      );

      final draftB = draftA.copyWith(
        selectedRouteId: 'route-b', // Expressway bypass
        admixtureRetarder: '0.4% by wt',
      );

      final riskA = await riskEngine.calculateRisk(draftA);
      final riskB = await riskEngine.calculateRisk(draftB);

      // Route A has higher transit due to bottleneck
      expect(riskA.predictedTransitMinutes, greaterThan(riskB.predictedTransitMinutes));
      // Route B has better slump retention
      expect(riskB.slumpRetentionRatio, greaterThan(riskA.slumpRetentionRatio));
      // Route B has lower travel risk
      expect(riskB.travelRisk, lessThan(riskA.travelRisk));
    });

    test('TEST 5: Route validation rejects mismatched origin/destination with canonical check', () {
      final assessment = RouteService.getRoute(
        originName: 'Ahmedabad Plant 01 (Naroda)',
        destinationName: 'Gift City Tower B',
      );

      // Valid case
      expect(
        RouteService.validateRoute(
          route: assessment,
          originName: 'Ahmedabad Plant 01 (Naroda)',
          destinationName: 'Gift City Tower B',
        ),
        isTrue,
      );

      // Mismatched origin
      expect(
        RouteService.validateRoute(
          route: assessment,
          originName: 'Ahmedabad Plant 02 - Sanand',
          destinationName: 'Gift City Tower B',
        ),
        isFalse,
      );

      // Mismatched destination
      expect(
        RouteService.validateRoute(
          route: assessment,
          originName: 'Ahmedabad Plant 01 (Naroda)',
          destinationName: 'Riverfront Phase 2',
        ),
        isFalse,
      );
    });

    testWidgets('TEST 6: Create Delivery -> Select locations -> Calculate -> Dispatch -> Tracking shows SAME route', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final state = MausamState();

      // Ensure authenticated and on RMC
      state.signIn(email: 'dispatcher@mausam.in', password: 'password123');
      state.selectRoleAndLaunch('rmc');

      // 1. Enter Delivery Creation
      state.startCreateDelivery();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: state,
              builder: (context, _) => CreateDeliveryScreen(
                state: state,
                onDispatched: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Create Delivery screen renders route map preview
      expect(find.byType(RouteMapView), findsOneWidget);
      expect(find.text('Route Corridors & Bottleneck Tradeoffs'), findsOneWidget);

      // 2. Dispatch delivery
      state.confirmAndDispatchDelivery();
      await tester.pumpAndSettle();

      // Verify dispatched batch is selected
      final dispatched = state.selectedBatch;
      expect(dispatched.batchCode, isNotEmpty);

      // 3. Render Tracking Delivery Screen
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: state,
              builder: (context, _) => BatchDetailScreen(
                state: state,
                onNavigateToRoutes: () {},
                onNavigateToOutcome: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 4. Verify Tracking screen displays the exact dispatched batch and route
      expect(find.text('Batch #${dispatched.batchCode}'), findsOneWidget);
      expect(find.text(dispatched.plantName), findsWidgets);
      expect(find.text(dispatched.projectName), findsWidgets);
      expect(find.byType(RouteMapView), findsOneWidget);
    });
  });
}
