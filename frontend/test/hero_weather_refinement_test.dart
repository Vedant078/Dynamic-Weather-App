import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/main.dart';
import 'package:mausam/state/mausam_state.dart';
import 'package:mausam/services/location_service.dart';
import 'package:mausam/features/landing/landing_hero_screen.dart';
import 'package:mausam/features/landing/components/hero_weather_card.dart';

void main() {
  group('MAUSAM — Section 19 Hero Refinement & Dynamic Weather Acceptance Tests', () {
    late MausamState state;

    setUp(() {
      state = MausamState();
    });

    testWidgets('TEST 1: Single primary CTA "Explore Intelligence" exists, "Get Started" is removed', (tester) async {
      await tester.pumpWidget(const MausamApp());
      await tester.pumpAndSettle();

      // Verify single primary CTA
      expect(find.text('Explore Intelligence'), findsOneWidget);
      expect(find.text('Get Started'), findsNothing);

      // Verify Hero Headline & Multi-Persona Messaging
      expect(find.text('Weather Intelligence\nfor Every Decision.'), findsOneWidget);
      expect(find.text('Built Around the Way You Use Weather'), findsOneWidget);
    });

    testWidgets('TEST 2: Hero weather is dynamic; NO fake hardcoded sensor telemetry (AWS-04, etc.)', (tester) async {
      await tester.pumpWidget(const MausamApp());
      await tester.pumpAndSettle();

      // Verify weather card is rendered
      expect(find.byType(HeroWeatherCard), findsOneWidget);

      // Verify hardcoded fake sensor values are NOT present
      expect(find.text('AWS-04'), findsNothing);
      expect(find.text('Western Basin • AWS-04'), findsNothing);
      expect(find.text('Ahmedabad Metropolitan & Transit Basin'), findsNothing);
      expect(find.text('OPTIMAL AIR MASS'), findsNothing);
      expect(find.text('1013 hPa'), findsNothing);

      // Verify template elements from reference are present (5-day forecast row)
      expect(
        find.byWidgetPredicate((w) => w is Text && ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].contains(w.data)),
        findsWidgets,
      );
      expect(find.text('More details'), findsOneWidget);
    });

    testWidgets('TEST 3: Location change dynamically updates city name and weather telemetry', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: state,
              builder: (context, _) => LandingHeroScreen(
                state: state,
                onGetStarted: () {},
                onSignIn: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state is Ahmedabad
      expect(find.text('Ahmedabad'), findsOneWidget);
      final initialWeather = state.heroWeather;
      expect(initialWeather, isNotNull);

      // Change location to Mumbai
      const mumbai = LocationData(
        cityName: 'Mumbai',
        regionName: 'Maharashtra, India',
        latitude: 19.0760,
        longitude: 72.8777,
      );
      await state.changeLocation(mumbai);
      await tester.pumpAndSettle();

      // Verify location changed to Mumbai
      expect(find.text('Mumbai'), findsOneWidget);
      expect(state.heroWeather!.locationName, equals('Mumbai'));

      // Change location to Delhi
      const delhi = LocationData(
        cityName: 'Delhi',
        regionName: 'Delhi, India',
        latitude: 28.6139,
        longitude: 77.2090,
      );
      await state.changeLocation(delhi);
      await tester.pumpAndSettle();

      // Verify location changed to Delhi
      expect(find.text('Delhi'), findsOneWidget);
      expect(state.heroWeather!.locationName, equals('Delhi'));
    });

    testWidgets('TEST 4 & 5: Deterministic fallback preserves usability without random data', (tester) async {
      final fallbackWeather = state.heroWeather;
      expect(fallbackWeather, isNotNull);
      expect(fallbackWeather!.temperature, greaterThan(0));
      expect(fallbackWeather.humidity, greaterThan(0));
      expect(fallbackWeather.forecastDays.length, equals(5));

      // Re-fetching same location produces consistent deterministic values
      final weatherAgain = await state.weatherService.getCurrentWeather(
        location: state.currentLocation,
        forceRefresh: false,
      );
      expect(weatherAgain.temperature, equals(fallbackWeather.temperature));
      expect(weatherAgain.locationName, equals(fallbackWeather.locationName));
    });

    testWidgets('TEST 7: Navigation flow: Hero -> Explore Intelligence -> Auth -> Back', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MausamApp());
      await tester.pumpAndSettle();

      // Click single primary CTA "Explore Intelligence"
      await tester.tap(find.text('Explore Intelligence'));
      await tester.pumpAndSettle();

      // Should be on Auth
      expect(find.text('Welcome back'), findsOneWidget);

      // Click Back to Home
      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();

      // Should be back on Landing Hero
      expect(find.text('Weather Intelligence\nfor Every Decision.'), findsOneWidget);
      expect(find.text('Explore Intelligence'), findsOneWidget);
    });

    testWidgets('TEST 8: Mobile viewport (375x812) stacks cleanly without overflow', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MausamApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Explore Intelligence'), findsOneWidget);
      expect(find.byType(HeroWeatherCard), findsOneWidget);
    });

    testWidgets('TEST 9: Tapping "More details" expands secondary metrics and location chips', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MausamApp());
      await tester.pumpAndSettle();

      // Initially secondary details are collapsed
      expect(find.text('Feels like'), findsNothing);
      expect(find.text('Switch Location:'), findsNothing);

      // Tap "More details"
      await tester.tap(find.text('More details'));
      await tester.pumpAndSettle();

      // Now expanded!
      expect(find.text('Feels like'), findsOneWidget);
      expect(find.text('Switch Location:'), findsOneWidget);
      expect(find.text('Less details'), findsOneWidget);

      // Tap a location preset chip (e.g. Pune)
      await tester.tap(find.text('Pune'));
      await tester.pumpAndSettle();

      // Weather card updates to Pune!
      expect(find.text('Pune'), findsWidgets);
    });
  });
}
