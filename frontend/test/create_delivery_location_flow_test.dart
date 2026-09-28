import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/state/mausam_state.dart';
import 'package:mausam/features/rmc/create_delivery/create_delivery_screen.dart';

void main() {
  group('CreateDeliveryScreen Location Dropdown & Dynamic Route Flow (Sections 1-19)', () {
    late MausamState state;

    setUp(() {
      state = MausamState();
    });

    testWidgets('Full flow: Open picker -> Search -> Select Origin -> Select Destination -> Dynamic Route & Risk', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool dispatched = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreateDeliveryScreen(
              state: state,
              onDispatched: () => dispatched = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Initial Fields show Ahmedabad and Gandhinagar
      expect(find.text('PLANT / ORIGIN'), findsOneWidget);
      expect(find.text('PROJECT SITE / DESTINATION'), findsOneWidget);
      expect(find.text('Ahmedabad'), findsAtLeastNWidgets(1));
      expect(find.text('Gandhinagar'), findsAtLeastNWidgets(1));

      // 1. Click PLANT / ORIGIN field
      await tester.tap(find.byKey(const Key('searchable_dropdown_field_PLANT / ORIGIN')));
      await tester.pumpAndSettle();

      // 2. Verify dialog opened with 'Select Origin Area'
      expect(find.text('Select Origin Area'), findsOneWidget);
      expect(find.text('Select city to view localities, or search directly'), findsOneWidget);

      // Verify alphabetical list starts with Ahmedabad, Anand, Bharuch...
      expect(find.text('Ahmedabad'), findsAtLeastNWidgets(1));
      expect(find.text('Anand'), findsOneWidget);

      // Search 'Vad' for Vadodara
      await tester.enterText(find.byKey(const Key('area_search_input')), 'Vad');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('area_item_area-vadodara')), findsOneWidget);
      expect(find.text('Anand'), findsNothing);

      // Select Vadodara
      await tester.tap(find.byKey(const Key('area_item_area-vadodara')));
      await tester.pumpAndSettle();

      // Dialog closed
      expect(find.text('Select Origin Area'), findsNothing);

      // Verify ONLY origin changed to Vadodara; destination is STILL Gandhinagar
      expect(state.currentDraft.plantName, 'Vadodara');
      expect(state.currentDraft.plantId, 'area-vadodara');
      expect(state.currentDraft.projectName, 'Gandhinagar');
      expect(state.currentDraft.projectId, 'area-gandhinagar');

      // 3. Click PROJECT SITE / DESTINATION field
      await tester.tap(find.byKey(const Key('searchable_dropdown_field_PROJECT SITE / DESTINATION')));
      await tester.pumpAndSettle();

      // 4. Verify dialog opened with 'Select Destination Area'
      expect(find.text('Select Destination Area'), findsOneWidget);

      // Search 'Sur' for Surat
      await tester.enterText(find.byKey(const Key('area_search_input')), 'Sur');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('area_item_area-surat')), findsOneWidget);

      // Select Surat
      await tester.tap(find.byKey(const Key('area_item_area-surat')));
      await tester.pumpAndSettle();

      // Dialog closed
      expect(find.text('Select Destination Area'), findsNothing);

      // Verify Vadodara -> Surat corridor is active in draft
      expect(state.currentDraft.plantName, 'Vadodara');
      expect(state.currentDraft.plantId, 'area-vadodara');
      expect(state.currentDraft.projectName, 'Surat');
      expect(state.currentDraft.projectId, 'area-surat');
      expect(state.currentDraft.plantLat, closeTo(22.3072, 0.01));
      expect(state.currentDraft.projectLat, closeTo(21.1702, 0.01));

      // 5. Test RMC Grade dynamicity: select M45
      await tester.ensureVisible(find.text('M45'));
      await tester.tap(find.text('M45'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(state.currentDraft.concreteGrade, 'M45');

      // 6. Test Volume dynamicity: enter 9.0
      await tester.ensureVisible(find.widgetWithText(TextField, '6.0'));
      await tester.enterText(find.widgetWithText(TextField, '6.0'), '9.0');
      await tester.pumpAndSettle();
      expect(state.currentDraft.volumeM3, 9.0);
      expect(dispatched, isFalse);
    });
  });
}
