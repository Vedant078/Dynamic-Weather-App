import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/services/area_service.dart';
import 'package:mausam/services/route_service.dart';
import 'package:mausam/state/mausam_state.dart';
import 'package:mausam/design_system/components/route_map_view.dart';
import 'package:mausam/features/rmc/routes/route_intelligence_screen.dart';

void main() {
  group('MAUSAM — Location Hierarchy: City + Within-City Areas (Sections 1-28)', () {
    late MausamState state;

    setUp(() {
      state = MausamState();
    });

    // =========================================================================
    // SECTION 1, 4, 5, 6, 16: HIERARCHY, REAL COORDS & ALPHABETICAL ORDER
    // =========================================================================
    test('AreaService provides cities and within-city localities strictly sorted alphabetically', () {
      final cities = AreaService.getCities();
      expect(cities.length, greaterThanOrEqualTo(8));

      // Strictly alphabetical cities (case-insensitive)
      for (int i = 0; i < cities.length - 1; i++) {
        expect(
          cities[i].name.toLowerCase().compareTo(cities[i + 1].name.toLowerCase()) <= 0,
          isTrue,
          reason: 'City "${cities[i].name}" must precede "${cities[i + 1].name}"',
        );
      }

      // Localities within Ahmedabad strictly sorted alphabetically
      final ahmLocs = AreaService.getLocalitiesForCity('Ahmedabad');
      expect(ahmLocs.length, greaterThanOrEqualTo(8));
      for (int i = 0; i < ahmLocs.length - 1; i++) {
        expect(
          ahmLocs[i].name.toLowerCase().compareTo(ahmLocs[i + 1].name.toLowerCase()) <= 0,
          isTrue,
        );
      }

      // Check real coordinates for mandatory localities (Section 4 & 5)
      final naroda = AreaService.getAreaById('area-ahm-naroda')!;
      final bopal = AreaService.getAreaById('area-ahm-bopal')!;
      final vatva = AreaService.getAreaById('area-ahm-vatva')!;
      final sgHighway = AreaService.getAreaById('area-ahm-sg-highway')!;
      final chandkheda = AreaService.getAreaById('area-ahm-chandkheda')!;
      final infocity = AreaService.getAreaById('area-gn-infocity')!;

      expect(naroda.latitude, closeTo(23.0805, 0.001));
      expect(naroda.longitude, closeTo(72.6500, 0.001));
      expect(naroda.parentLocationId, equals('area-ahmedabad'));
      expect(naroda.qualifiedName, equals('Ahmedabad / Naroda'));

      expect(bopal.latitude, closeTo(23.0336, 0.001));
      expect(bopal.longitude, closeTo(72.4634, 0.001));
      expect(bopal.qualifiedName, equals('Ahmedabad / Bopal'));

      expect(vatva.latitude, closeTo(22.9555, 0.001));
      expect(vatva.longitude, closeTo(72.6348, 0.001));

      expect(sgHighway.latitude, closeTo(23.0525, 0.001));
      expect(sgHighway.longitude, closeTo(72.5085, 0.001));

      expect(chandkheda.latitude, closeTo(23.1118, 0.001));
      expect(chandkheda.longitude, closeTo(72.5841, 0.001));

      expect(infocity.latitude, closeTo(23.1920, 0.001));
      expect(infocity.longitude, closeTo(72.6288, 0.001));
      expect(infocity.parentLocationId, equals('area-gandhinagar'));
      expect(infocity.qualifiedName, equals('Gandhinagar / Infocity'));

      // Naroda, Bopal, Vatva coordinates must NOT be identical to city-center
      final ahmCity = AreaService.getAreaById('area-ahmedabad')!;
      expect(naroda.latitude, isNot(equals(ahmCity.latitude)));
      expect(bopal.latitude, isNot(equals(ahmCity.latitude)));
      expect(vatva.latitude, isNot(equals(ahmCity.latitude)));
    });

    // =========================================================================
    // SECTION 3, 17, 18: DIRECT SEARCH WITH PARENT CITY CONTEXT
    // =========================================================================
    test('Direct search understands locality and identifies parent city context', () {
      final narodaResults = AreaService.searchAreas('Naroda');
      expect(narodaResults, isNotEmpty);
      final naroda = narodaResults.first;
      expect(naroda.name, 'Naroda');
      expect(naroda.city, 'Ahmedabad');
      expect(naroda.state, 'Gujarat');

      final bopalResults = AreaService.searchAreas('Bopal');
      expect(bopalResults, isNotEmpty);
      expect(bopalResults.first.name, 'Bopal');
      expect(bopalResults.first.city, 'Ahmedabad');

      final giftResults = AreaService.searchAreas('GIFT');
      expect(giftResults, isNotEmpty);
      expect(giftResults.first.city, 'Gandhinagar');

      final ganResults = AreaService.searchAreas('Gan');
      expect(ganResults, isNotEmpty);
      expect(ganResults.any((a) => a.name == 'Gandhinagar'), isTrue);
    });

    // =========================================================================
    // SECTION 21: MANDATORY INTRACITY ROUTE TESTS
    // =========================================================================
    test('Intracity Route 1: Ahmedabad / Naroda -> Ahmedabad / Bopal uses leaf coords and urban speed', () {
      final naroda = AreaService.getAreaById('area-ahm-naroda')!;
      final bopal = AreaService.getAreaById('area-ahm-bopal')!;

      final route = RouteService.getRouteForAreas(origin: naroda, destination: bopal);

      // Verifies leaf coordinates (Section 10)
      expect(route.origin.latitude, naroda.latitude);
      expect(route.origin.longitude, naroda.longitude);
      expect(route.destination.latitude, bopal.latitude);
      expect(route.destination.longitude, bopal.longitude);

      // Distance across city ~25.3 km, urban transit time (Section 12)
      expect(route.distanceKm, closeTo(25.3, 2.0));
      expect(route.etaMinutes, inInclusiveRange(35.0, 60.0));
    });

    test('Intracity Route 2: Ahmedabad / Vatva -> Ahmedabad / SG Highway', () {
      final vatva = AreaService.getAreaById('area-ahm-vatva')!;
      final sgHighway = AreaService.getAreaById('area-ahm-sg-highway')!;

      final route = RouteService.getRouteForAreas(origin: vatva, destination: sgHighway);

      expect(route.origin.latitude, vatva.latitude);
      expect(route.destination.latitude, sgHighway.latitude);
      expect(route.distanceKm, closeTo(22.8, 3.0));
      expect(route.etaMinutes, inInclusiveRange(30.0, 55.0));
    });

    test('Intracity Route 3: Ahmedabad / Chandkheda -> Gandhinagar / Infocity', () {
      final chandkheda = AreaService.getAreaById('area-ahm-chandkheda')!;
      final infocity = AreaService.getAreaById('area-gn-infocity')!;

      final route = RouteService.getRouteForAreas(origin: chandkheda, destination: infocity);

      expect(route.origin.latitude, chandkheda.latitude);
      expect(route.destination.latitude, infocity.latitude);
      // North arterial corridor between Chandkheda and Infocity ~13.1 km
      expect(route.distanceKm, closeTo(13.1, 2.0));
      expect(route.distanceKm, isNot(equals(27.5))); // Must NOT fall back to city center
    });

    test('Intracity Route 4: Gandhinagar / Infocity -> Ahmedabad / Bopal', () {
      final infocity = AreaService.getAreaById('area-gn-infocity')!;
      final bopal = AreaService.getAreaById('area-ahm-bopal')!;

      final route = RouteService.getRouteForAreas(origin: infocity, destination: bopal);

      expect(route.origin.latitude, infocity.latitude);
      expect(route.destination.latitude, bopal.latitude);
      expect(route.distanceKm, closeTo(31.3, 2.0));
      expect(route.distanceKm, isNot(equals(27.5)));
    });

    // =========================================================================
    // SECTION 22: MANDATORY INTERCITY ROUTE TESTS
    // =========================================================================
    test('Intercity Route 1: Ahmedabad -> Gandhinagar works using city-level selection', () {
      final ahm = AreaService.getAreaById('area-ahmedabad')!;
      final gandhi = AreaService.getAreaById('area-gandhinagar')!;

      final route = RouteService.getRouteForAreas(origin: ahm, destination: gandhi);

      expect(route.origin.name, 'Ahmedabad');
      expect(route.destination.name, 'Gandhinagar');
      expect(route.distanceKm, equals(27.5));
      expect(route.etaMinutes, inInclusiveRange(30.0, 55.0));
      expect(route.primaryPathPoints.length, greaterThan(2));
    });

    test('Intercity Route 2: Ahmedabad -> Vadodara', () {
      final ahm = AreaService.getAreaById('area-ahmedabad')!;
      final vad = AreaService.getAreaById('area-vadodara')!;

      final route = RouteService.getRouteForAreas(origin: ahm, destination: vad);

      expect(route.distanceKm, equals(111.4));
      expect(route.etaMinutes, inInclusiveRange(90.0, 130.0));
    });

    test('Intercity Route 3: Ahmedabad -> Surat', () {
      final ahm = AreaService.getAreaById('area-ahmedabad')!;
      final surat = AreaService.getAreaById('area-surat')!;

      final route = RouteService.getRouteForAreas(origin: ahm, destination: surat);

      expect(route.distanceKm, equals(247.1));
      expect(route.etaMinutes, inInclusiveRange(200.0, 260.0));
    });

    test('Intercity Route 4: Gandhinagar -> Ahmedabad', () {
      final gandhi = AreaService.getAreaById('area-gandhinagar')!;
      final ahm = AreaService.getAreaById('area-ahmedabad')!;

      final route = RouteService.getRouteForAreas(origin: gandhi, destination: ahm);

      expect(route.distanceKm, equals(27.5));
      expect(route.etaMinutes, inInclusiveRange(30.0, 55.0));
    });

    // =========================================================================
    // SECTION 23: MANDATORY MIXED HIERARCHY TESTS
    // =========================================================================
    test('Mixed 1: City -> Locality (Ahmedabad -> Bopal)', () {
      final ahm = AreaService.getAreaById('area-ahmedabad')!;
      final bopal = AreaService.getAreaById('area-ahm-bopal')!;

      final route = RouteService.getRouteForAreas(origin: ahm, destination: bopal);

      expect(route.origin.latitude, ahm.latitude);
      expect(route.destination.latitude, bopal.latitude);
      expect(route.distanceKm, closeTo(14.2, 3.0));
    });

    test('Mixed 2: Locality -> City (Naroda -> Gandhinagar)', () {
      final naroda = AreaService.getAreaById('area-ahm-naroda')!;
      final gandhi = AreaService.getAreaById('area-gandhinagar')!;

      final route = RouteService.getRouteForAreas(origin: naroda, destination: gandhi);

      expect(route.origin.latitude, naroda.latitude);
      expect(route.destination.latitude, gandhi.latitude);
      expect(route.distanceKm, closeTo(20.5, 3.0));
    });

    test('Mixed 3: Locality -> Locality (Naroda -> Bopal)', () {
      final naroda = AreaService.getAreaById('area-ahm-naroda')!;
      final bopal = AreaService.getAreaById('area-ahm-bopal')!;

      final route = RouteService.getRouteForAreas(origin: naroda, destination: bopal);

      expect(route.origin.latitude, naroda.latitude);
      expect(route.destination.latitude, bopal.latitude);
      expect(route.distanceKm, closeTo(25.3, 2.0));
    });

    test('Mixed 4: City -> City (Ahmedabad -> Vadodara)', () {
      final ahm = AreaService.getAreaById('area-ahmedabad')!;
      final vad = AreaService.getAreaById('area-vadodara')!;

      final route = RouteService.getRouteForAreas(origin: ahm, destination: vad);

      expect(route.distanceKm, equals(111.4));
    });

    // =========================================================================
    // SECTION 16, 17, 18: EMPTY, LOADING, AND ERROR STATES IN ROUTE MAP VIEW
    // =========================================================================
    testWidgets('RouteMapView displays empty state when selections are missing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RouteMapView(
              isEmpty: true,
              height: 300,
            ),
          ),
        ),
      );

      expect(find.text('Select an origin and destination to view the route.'), findsOneWidget);
    });

    testWidgets('RouteMapView displays loading state when calculating route', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RouteMapView(
              isCalculating: true,
              height: 300,
            ),
          ),
        ),
      );

      expect(find.text('Calculating route...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('RouteMapView displays error state with Retry button on failure', (tester) async {
      bool retryClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteMapView(
              hasError: true,
              errorMessage: 'Please try another area combination.',
              onRetry: () {
                retryClicked = true;
              },
              height: 300,
            ),
          ),
        ),
      );

      expect(find.text('Unable to calculate route.'), findsOneWidget);
      expect(find.text('Please try another area combination.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retryClicked, isTrue);
    });

    // =========================================================================
    // SECTION 19 & 22: ROUTE INTELLIGENCE SCREEN INTERACTION & STALE ROUTE CLEARING
    // =========================================================================
    testWidgets('RouteIntelligenceScreen updates map, ETA, distance, and risk on area change', (tester) async {
      final ahm = AreaService.getAreaById('area-ahmedabad')!;
      final gandhi = AreaService.getAreaById('area-gandhinagar')!;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteIntelligenceScreen(
              state: state,
              initialOrigin: ahm,
              initialDestination: gandhi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen Header and UI Hierarchy
      expect(find.text('Route intelligence'), findsOneWidget);
      expect(find.text('FROM (PLANT / ORIGIN)'), findsOneWidget);
      expect(find.text('TO (PROJECT SITE / DESTINATION)'), findsOneWidget);

      // Verify initial route summary (Ahmedabad -> Gandhinagar)
      expect(find.text('27.5 km'), findsOneWidget);
      expect(find.text('TRAVEL RISK'), findsOneWidget);
      expect(find.text('DELIVERY RISK'), findsOneWidget);
      expect(find.text('OVERALL RISK'), findsOneWidget);

      // Verify Quick Corridor button for "Vadodara → Surat"
      final vadSuratBtn = find.text('Vadodara → Surat');
      expect(vadSuratBtn, findsOneWidget);

      // Tap "Vadodara → Surat" shortcut chip
      await tester.tap(vadSuratBtn);
      await tester.pumpAndSettle();

      // Verify distance and ETA immediately updated to Vadodara -> Surat
      expect(find.text('147.4 km'), findsOneWidget);
      expect(find.text('27.5 km'), findsNothing); // Old route must be gone!

      // Verify risk recalculated
      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data == 'HIGH DELIVERY RISK' || w.data == 'CRITICAL TRANSIT FAILURE IMMINENT')),
        findsOneWidget,
      );
    });
  });
}
