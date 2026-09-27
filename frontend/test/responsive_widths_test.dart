import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/main.dart';

void main() {
  final targetWidths = [360.0, 375.0, 390.0, 412.0, 430.0];

  for (final width in targetWidths) {
    testWidgets('MAUSAM operational app renders without overflow at ${width.toInt()}px phone width',
        (WidgetTester tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MausamApp(initialScreen: 'app'));
      await tester.pumpAndSettle();

      // Verify core operational elements
      expect(find.text('MAUSAM'), findsOneWidget);
      expect(find.text('Ahmedabad Central Corridor'), findsOneWidget);
      expect(find.text('No active deliveries'), findsOneWidget);
      expect(find.text('Active deliveries'), findsOneWidget);
      expect(find.text('Avoided loss'), findsOneWidget);
    });

    testWidgets('MAUSAM landing hero renders without overflow at ${width.toInt()}px phone width',
        (WidgetTester tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MausamApp(initialScreen: 'landing'));
      await tester.pumpAndSettle();

      expect(find.text('MAUSAM'), findsOneWidget);
      expect(find.text('Explore Intelligence'), findsOneWidget);
      expect(find.text('Get Started'), findsNothing);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('MAUSAM auth screen renders without overflow at ${width.toInt()}px phone width',
        (WidgetTester tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MausamApp(initialScreen: 'auth'));
      await tester.pumpAndSettle();

      expect(find.text('MAUSAM'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });
  }
}
