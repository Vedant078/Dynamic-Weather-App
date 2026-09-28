import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/design_system/components/searchable_area_dropdown.dart';
import 'package:mausam/models/area.dart';

void main() {
  group('SearchableAreaDropdown Hierarchical Tests (City + Within-City Areas)', () {
    testWidgets('Opens dialog on desktop, shows alphabetical cities, drills into Ahmedabad, and selects Naroda', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      Area? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return SearchableAreaDropdown(
                      label: 'PLANT / ORIGIN',
                      hint: 'Select dispatch origin area',
                      selectedArea: selected,
                      onChanged: (area) {
                        setState(() {
                          selected = area;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Field displays hint initially
      expect(find.text('Select dispatch origin area'), findsOneWidget);

      // Tap the dropdown field using its dedicated key
      await tester.tap(find.byKey(const Key('searchable_dropdown_field_PLANT / ORIGIN')));
      await tester.pumpAndSettle();

      // Dialog is open and shows correct title
      expect(find.text('Select Origin Area'), findsOneWidget);
      expect(find.text('Select city to view localities, or search directly'), findsOneWidget);

      // Programmatic alphabetical city list has Ahmedabad and Gandhinagar at the top
      expect(find.text('Ahmedabad'), findsOneWidget);
      expect(find.text('Gandhinagar'), findsOneWidget);

      // Drill down into Ahmedabad by tapping the city item
      await tester.tap(find.byKey(const Key('city_item_area-ahmedabad')));
      await tester.pumpAndSettle();

      // Level 2: Header updates to "Select Area in Ahmedabad"
      expect(find.text('Select Area in Ahmedabad'), findsOneWidget);
      expect(find.byKey(const Key('back_to_cities_button')), findsOneWidget);

      // Localities within Ahmedabad are shown
      expect(find.text('Bopal'), findsOneWidget);
      expect(find.text('Naroda'), findsOneWidget);

      // Test Back button navigation
      await tester.tap(find.byKey(const Key('back_to_cities_button')));
      await tester.pumpAndSettle();

      // Back to Level 1 cities
      expect(find.text('Select Origin Area'), findsOneWidget);
      expect(find.text('Ahmedabad'), findsOneWidget);

      // Drill back into Ahmedabad
      await tester.tap(find.byKey(const Key('city_item_area-ahmedabad')));
      await tester.pumpAndSettle();

      // Tap Naroda locality
      await tester.tap(find.byKey(const Key('area_item_area-ahm-naroda')));
      await tester.pumpAndSettle();

      // Dialog is closed
      expect(find.text('Select Origin Area'), findsNothing);

      // Selected area has verified leaf coordinates and qualified name
      expect(selected, isNotNull);
      expect(selected?.id, 'area-ahm-naroda');
      expect(selected?.name, 'Naroda');
      expect(selected?.city, 'Ahmedabad');
      expect(selected?.qualifiedName, 'Ahmedabad / Naroda');
      expect(selected?.latitude, closeTo(23.0805, 0.001));
      expect(selected?.longitude, closeTo(72.6500, 0.001));

      // Dropdown trigger clearly displays qualified name
      expect(find.text('Ahmedabad / Naroda'), findsOneWidget);
    });

    testWidgets('Direct search resolves locality directly with parent city context', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      Area? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return SearchableAreaDropdown(
                      label: 'PROJECT SITE / DESTINATION',
                      hint: 'Select destination area',
                      selectedArea: selected,
                      onChanged: (area) {
                        setState(() {
                          selected = area;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap field to open picker
      await tester.tap(find.byKey(const Key('searchable_dropdown_field_PROJECT SITE / DESTINATION')));
      await tester.pumpAndSettle();

      // Search directly for "Bopal"
      await tester.enterText(find.byKey(const Key('area_search_input')), 'Bopal');
      await tester.pumpAndSettle();

      // Result shows Bopal tile and its parent city context "Ahmedabad, Gujarat"
      expect(find.byKey(const Key('area_item_area-ahm-bopal')), findsOneWidget);
      expect(find.text('Ahmedabad, Gujarat'), findsOneWidget);

      // Select Bopal
      await tester.tap(find.byKey(const Key('area_item_area-ahm-bopal')));
      await tester.pumpAndSettle();

      // Verify leaf location
      expect(selected?.id, 'area-ahm-bopal');
      expect(selected?.name, 'Bopal');
      expect(selected?.city, 'Ahmedabad');
      expect(selected?.qualifiedName, 'Ahmedabad / Bopal');
      expect(selected?.latitude, closeTo(23.0336, 0.001));
      expect(selected?.longitude, closeTo(72.4634, 0.001));

      // Trigger shows qualified name
      expect(find.text('Ahmedabad / Bopal'), findsOneWidget);
    });

    testWidgets('Direct city selection supports intercity routing', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      Area? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return SearchableAreaDropdown(
                      label: 'PLANT / ORIGIN',
                      hint: 'Select city',
                      selectedArea: selected,
                      onChanged: (area) {
                        setState(() {
                          selected = area;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open picker
      await tester.tap(find.byKey(const Key('searchable_dropdown_field_PLANT / ORIGIN')));
      await tester.pumpAndSettle();

      // Tap direct city selection button for Gandhinagar (visible at top of cities list)
      await tester.tap(find.byKey(const Key('select_city_direct_area-gandhinagar')));
      await tester.pumpAndSettle();

      // Gandhinagar city selected
      expect(selected?.id, 'area-gandhinagar');
      expect(selected?.name, 'Gandhinagar');
      expect(selected?.isCity, isTrue);
      expect(find.text('Gandhinagar'), findsOneWidget);
    });

    testWidgets('Opens bottom sheet on mobile (390x844) and searches Infocity in Gandhinagar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      Area? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 350,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return SearchableAreaDropdown(
                      label: 'PROJECT SITE / DESTINATION',
                      hint: 'Select project destination area',
                      selectedArea: selected,
                      onChanged: (area) {
                        setState(() {
                          selected = area;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the dropdown field
      await tester.tap(find.byKey(const Key('searchable_dropdown_field_PROJECT SITE / DESTINATION')));
      await tester.pumpAndSettle();

      // Search 'Infocity'
      await tester.enterText(find.byKey(const Key('area_search_input')), 'Infocity');
      await tester.pumpAndSettle();

      // Should show Infocity tile with Gandhinagar context
      expect(find.byKey(const Key('area_item_area-gn-infocity')), findsOneWidget);
      expect(find.text('Gandhinagar, Gujarat'), findsOneWidget);

      // Select Infocity
      await tester.tap(find.byKey(const Key('area_item_area-gn-infocity')));
      await tester.pumpAndSettle();

      // Sheet closed and Infocity selected
      expect(find.text('Select Destination Area'), findsNothing);
      expect(selected?.name, 'Infocity');
      expect(selected?.city, 'Gandhinagar');
      expect(selected?.qualifiedName, 'Gandhinagar / Infocity');
      expect(selected?.latitude, closeTo(23.1920, 0.001));
      expect(selected?.longitude, closeTo(72.6288, 0.001));
      expect(find.text('Gandhinagar / Infocity'), findsOneWidget);
    });
  });
}
