import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/main.dart';

void main() {
  testWidgets('MAUSAM Landing Hero smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MausamApp());
    await tester.pumpAndSettle();

    // Verify brand header and landing hero presence
    expect(find.text('MAUSAM'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Built Around the Way You Use Weather'), findsOneWidget);
  });

  testWidgets('MAUSAM full flow: Landing -> Auth -> RBAC Role Selection -> RMC Command', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MausamApp());
    await tester.pumpAndSettle();

    // 1. Tap 'Get Started' on Landing
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Verify Auth Screen (credentials only, NO persona selection!)
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Work email'), findsOneWidget);

    // 2. Scroll and tap 'Sign In'
    final signInBtn = find.widgetWithText(ElevatedButton, 'Sign In');
    await tester.ensureVisible(signInBtn);
    await tester.tap(signInBtn);
    await tester.pumpAndSettle();

    // Verify Dedicated RBAC Role Selection Screen
    expect(find.text('How are you using Mausam?'), findsOneWidget);
    expect(find.text('RMC Logistics Manager'), findsOneWidget);

    // 3. Scroll and tap 'Launch RMC Command Center'
    final launchBtn = find.text('Launch RMC Command Center');
    await tester.ensureVisible(launchBtn);
    await tester.tap(launchBtn);
    await tester.pumpAndSettle();

    // Verify Operational RMC App Loaded
    expect(find.text('Ahmedabad Central Corridor'), findsOneWidget);
    expect(find.text('RMC-204'), findsWidgets);
    expect(find.text('Active deliveries'), findsOneWidget);
  });

  testWidgets('MAUSAM Back Navigation: Hero -> Auth -> Back returns to Hero', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MausamApp());
    await tester.pumpAndSettle();

    // Navigate to Auth
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);

    // Tap Back to Home
    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();

    // Must be back on Hero!
    expect(find.text('Weather Intelligence\nfor Every Decision.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
