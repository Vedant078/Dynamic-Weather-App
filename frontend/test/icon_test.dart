import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  test('test icons', () {
    expect(LucideIcons.moon, isNotNull);
    expect(LucideIcons.cloudMoon, isNotNull);
    expect(LucideIcons.cloudSun, isNotNull);
    expect(LucideIcons.sun, isNotNull);
  });
}
