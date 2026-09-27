import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/features/rmc/batch_detail/batch_detail_screen.dart';
import 'package:mausam/design_system/components/route_map_view.dart';
import 'package:mausam/models/batch.dart';
import 'package:mausam/state/mausam_state.dart';

void main() {
  group('MAUSAM — Tracking Delivery Screen (UI/UX Reference Implementation Tests)', () {
    late MausamState state;

    setUp(() {
      state = MausamState();
    });

    testWidgets('BatchDetailScreen renders desktop master-detail layout with visual anchor map', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchDetailScreen(
              state: state,
              onNavigateToRoutes: () {},
              onNavigateToOutcome: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Tracking Header
      expect(find.text('Batch #RMC-204'), findsOneWidget);
      expect(find.text('TRC-042'), findsOneWidget);
      expect(find.textContaining('Plant 01'), findsWidgets);
      expect(find.textContaining('Site 07'), findsWidgets);

      // 2. Verify Visual Anchor: RouteMapView is present with Legend
      expect(find.byType(RouteMapView), findsOneWidget);
      expect(find.text('Traversed route'), findsOneWidget);
      expect(find.text('Remaining route'), findsOneWidget);
      expect(find.text('Risk bottleneck'), findsOneWidget);

      // 3. Verify Linear Journey Progress Bar (Lesson 6)
      expect(find.textContaining('Elapsed:'), findsOneWidget);
      expect(find.textContaining('left'), findsWidgets);

      // 4. Verify Critical Live Telemetry Grid
      expect(find.text('Live hydration & transit telemetry'), findsOneWidget);
      expect(find.text('Concrete temp'), findsOneWidget);
      expect(find.text('Slump retention'), findsOneWidget);
      expect(find.text('Elapsed transit'), findsOneWidget);
      expect(find.text('Remaining distance'), findsOneWidget);

      // 5. Verify Delivery Risk State & Grounded "WHY"
      expect(find.text('Delivery risk state'), findsOneWidget);
      expect(find.text('PRIMARY RISK DRIVER'), findsOneWidget);
      expect(find.text('Contributing risk factors'), findsOneWidget);

      // 6. Verify Corridor Microclimate Exposure
      expect(find.text('Corridor microclimate context'), findsOneWidget);
      expect(find.text('Ambient temp'), findsOneWidget);
      expect(find.text('Humidity'), findsOneWidget);
      expect(find.text('Wind velocity'), findsOneWidget);
    });

    testWidgets('BatchDetailScreen renders mobile single-column layout without overflow', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchDetailScreen(
              state: state,
              onNavigateToRoutes: () {},
              onNavigateToOutcome: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Batch #RMC-204'), findsOneWidget);
      expect(find.byType(RouteMapView), findsOneWidget);
      expect(find.text('Live hydration & transit telemetry'), findsOneWidget);
    });

    testWidgets('Active fleet switcher changes selected batch', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return ListenableBuilder(
                listenable: state,
                builder: (context, _) {
                  return Scaffold(
                    body: BatchDetailScreen(
                      state: state,
                      onNavigateToRoutes: () {},
                      onNavigateToOutcome: () {},
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(state.selectedBatch.batchCode, 'RMC-204');

      // Tap on second batch chip in active fleet switcher (#RMC-201)
      final rmc201Chip = find.text('#RMC-201');
      expect(rmc201Chip, findsOneWidget);
      await tester.tap(rmc201Chip);
      await tester.pumpAndSettle();
      expect(state.selectedBatch.batchCode, 'RMC-201');
    });

    testWidgets('Critical risk state displays intervention buttons and triggers actions', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Advance simulation step to step 2 (High Risk)
      state.setSimulationStep(2);
      expect(state.selectedBatch.riskLevel, RiskLevel.highRisk);

      bool didNavigateRoutes = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ListenableBuilder(
            listenable: state,
            builder: (context, _) {
              return Scaffold(
                body: BatchDetailScreen(
                  state: state,
                  onNavigateToRoutes: () => didNavigateRoutes = true,
                  onNavigateToOutcome: () {},
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OPERATIONAL INTERVENTION REQUIRED'), findsOneWidget);
      final applyButton = find.text('Apply Route B Bypass (-9 min)');
      expect(applyButton, findsOneWidget);
      expect(find.text('Inject retarder'), findsOneWidget);
      expect(find.text('Log override'), findsOneWidget);

      // Scroll to button if needed and tap
      await tester.ensureVisible(applyButton);
      await tester.pumpAndSettle();
      await tester.tap(applyButton);
      await tester.pumpAndSettle();
      expect(didNavigateRoutes, isTrue);
    });
  });
}
