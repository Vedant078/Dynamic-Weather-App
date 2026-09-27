import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/features/rbac/rbac_role_selection_screen.dart';
import 'package:mausam/models/persona.dart';
import 'package:mausam/models/workspace_definition.dart';
import 'package:mausam/state/mausam_state.dart';

void main() {
  group('RbacRoleSelectionScreen Tests', () {
    late List<PersonaModel> allPersonas;

    setUp(() {
      final state = MausamState();
      allPersonas = state.personas;
    });

    Widget createScreen({
      required WorkspaceOperationalSummary operationalSummary,
      required void Function(String) onSelectRole,
      String? userName,
    }) {
      return MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: RbacRoleSelectionScreen(
            personas: allPersonas,
            operationalSummary: operationalSummary,
            userName: userName,
            onSelectRole: onSelectRole,
            onSignOut: () {},
          ),
        ),
      );
    }

    testWidgets('New user empty state has NO fake telemetry, NO RMC-204 batch, and shows zero state', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? selectedRole;
      const emptySummary = WorkspaceOperationalSummary(
        activeDeliveries: 0,
        attentionCount: 0,
        hasLiveTelemetry: false,
      );

      await tester.pumpWidget(createScreen(
        operationalSummary: emptySummary,
        userName: 'Priya',
        onSelectRole: (role) => selectedRole = role,
      ));
      await tester.pumpAndSettle();

      // Welcome greeting and header
      expect(find.text('Welcome, Priya'), findsOneWidget);
      expect(find.text('How are you using Mausam?'), findsOneWidget);
      expect(
        find.text('Select your authorized workspace. Mausam adapts environmental intelligence and decision support to your workflow.'),
        findsOneWidget,
      );

      // Flagship section
      expect(find.text('FLAGSHIP OPERATIONAL WORKSPACE'), findsOneWidget);
      expect(find.text('RMC Logistics Manager'), findsOneWidget);
      expect(find.text('Ready-Mix Concrete Operations & Transit Loss Prevention'), findsOneWidget);

      // Crucial: NO fake batch RMC-204 or fake ETA or fake telemetry badge
      expect(find.text('LIVE TELEMETRY ACTIVE'), findsNothing);
      expect(find.textContaining('RMC-204'), findsNothing);
      expect(find.textContaining('ETA 21 min'), findsNothing);
      expect(find.textContaining('Plant A → GIFT City'), findsNothing);
      expect(find.textContaining('Slump 91.2%'), findsNothing);

      // Clean empty state
      expect(find.text('No active deliveries'), findsOneWidget);
      expect(find.text('Create and monitor your first RMC delivery.'), findsOneWidget);
      expect(find.text('Launch RMC Command Center'), findsOneWidget);

      // Concise capability tags
      expect(find.text('Dynamic Slump Risk'), findsOneWidget);
      expect(find.text('Route Intelligence'), findsOneWidget);
      expect(find.text('Transit Loss Prevention'), findsOneWidget);

      // Tap launch RMC
      await tester.tap(find.text('Launch RMC Command Center'));
      await tester.pump();
      expect(selectedRole, 'rmc');
    });

    testWidgets('Active account displays real delivery count and live telemetry badge', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const activeSummary = WorkspaceOperationalSummary(
        activeDeliveries: 3,
        attentionCount: 1,
        hasLiveTelemetry: true,
      );

      await tester.pumpWidget(createScreen(
        operationalSummary: activeSummary,
        onSelectRole: (_) {},
      ));
      await tester.pumpAndSettle();

      // Live telemetry badge should be visible only because activeDeliveries > 0
      expect(find.text('LIVE TELEMETRY ACTIVE'), findsOneWidget);
      expect(find.text('3 active deliveries'), findsOneWidget);
      expect(find.text('1 requires attention'), findsOneWidget);

      // Still no fake batch monitor
      expect(find.textContaining('RMC-204'), findsNothing);
      expect(find.textContaining('ETA 21 min'), findsNothing);
    });

    testWidgets('All 6 other personas are visible in EXPLORE OTHER WORKSPACES and clickable', (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final selectedRoles = <String>[];
      const emptySummary = WorkspaceOperationalSummary(
        activeDeliveries: 0,
        attentionCount: 0,
        hasLiveTelemetry: false,
      );

      await tester.pumpWidget(createScreen(
        operationalSummary: emptySummary,
        onSelectRole: (role) => selectedRoles.add(role),
      ));
      await tester.pumpAndSettle();

      // Section title
      expect(find.text('EXPLORE OTHER WORKSPACES'), findsOneWidget);
      expect(find.text('SECONDARY OPERATIONAL ROLES'), findsNothing);

      // Verify all 6 non-RMC personas are displayed
      expect(find.text('Health-Conscious Users'), findsOneWidget);
      expect(find.text('Outdoor Fitness Enthusiasts'), findsOneWidget);
      expect(find.text('Beachgoers & Surfers'), findsOneWidget);
      expect(find.text('Travelers & Commuters'), findsOneWidget);
      expect(find.text('Parents & Families'), findsOneWidget);
      expect(find.text('Agriculture & Gardeners'), findsOneWidget);

      // Key capability pills are rendered
      expect(find.text('AQI • Heat • Pollen'), findsOneWidget);
      expect(find.text('Best Running Hours • Heat Alerts • Wind'), findsOneWidget);
      expect(find.text('Tide • Wave Height • Water Temp'), findsOneWidget);
      expect(find.text('Corridor Weather • Travel Alerts • Traction'), findsOneWidget);
      expect(find.text('School Commute • Rain Advisory • Family Safety'), findsOneWidget);
      expect(find.text('Soil Moisture • Frost • Crop Guidance'), findsOneWidget);

      // Tap on Health card
      await tester.tap(find.text('Health-Conscious Users'));
      await tester.pump();
      expect(selectedRoles.last, 'health');

      // Tap on Fitness card
      await tester.tap(find.text('Outdoor Fitness Enthusiasts'));
      await tester.pump();
      expect(selectedRoles.last, 'fitness');

      // Tap on Beach card
      await tester.tap(find.text('Beachgoers & Surfers'));
      await tester.pump();
      expect(selectedRoles.last, 'beach');

      // Tap on Traveler card
      await tester.tap(find.text('Travelers & Commuters'));
      await tester.pump();
      expect(selectedRoles.last, 'traveler');

      // Tap on Family card
      await tester.tap(find.text('Parents & Families'));
      await tester.pump();
      expect(selectedRoles.last, 'family');

      // Tap on Agriculture card
      await tester.tap(find.text('Agriculture & Gardeners'));
      await tester.pump();
      expect(selectedRoles.last, 'agriculture');

      // None of them routed to rmc
      expect(selectedRoles.contains('rmc'), isFalse);
    });

    test('MausamState selectRoleAndLaunch updates selected persona and theme correctly', () {
      final state = MausamState();

      // Launch health
      state.selectRoleAndLaunch('health');
      expect(state.selectedPersonaId, 'health');
      expect(state.currentScreen, 'app');
      expect(state.themeMode, ThemeMode.light);

      // Launch rmc
      state.selectRoleAndLaunch('rmc');
      expect(state.selectedPersonaId, 'rmc');
      expect(state.currentScreen, 'app');
      expect(state.themeMode, ThemeMode.dark);

      // Launch traveler
      state.selectRoleAndLaunch('traveler');
      expect(state.selectedPersonaId, 'traveler');
      expect(state.currentScreen, 'app');
      expect(state.themeMode, ThemeMode.light);
    });

    test('MausamState rmcOperationalSummary reflects real deliveries without hardcoding', () {
      final state = MausamState();
      // Initially, clean state has 0 batches
      final summary = state.rmcOperationalSummary;
      expect(summary.activeDeliveries, state.batches.length);
      expect(summary.hasLiveTelemetry, state.batches.isNotEmpty);
    });
  });
}
