import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/main.dart';

void main() {
  testWidgets('Reproduce crash at desktop width 1200x900', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MausamApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
    expect(find.text('Weather Intelligence\nfor Every Decision.'), findsOneWidget);
  });
}
