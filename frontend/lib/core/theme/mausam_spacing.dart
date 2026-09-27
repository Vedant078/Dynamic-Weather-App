import 'package:flutter/material.dart';

/// 4-point spacing grid, standardized radius values, and soft shadows
class MausamSpacing {
  MausamSpacing._();

  static const double micro = 4.0;
  static const double compact = 8.0;
  static const double small = 12.0;
  static const double standard = 16.0;
  static const double medium = 20.0;
  static const double section = 24.0;
  static const double major = 32.0;
  static const double large = 40.0;
  static const double screen = 48.0;

  // Radii
  static const double radiusControls = 8.0;
  static const double radiusButtons = 10.0;
  static const double radiusDataSurfaces = 12.0;
  static const double radiusLargeSurfaces = 16.0;
  static const double radiusBottomSheets = 20.0;
  static const double radiusModals = 24.0;
  static const double radiusPills = 999.0;

  // Soft Elevation Shadows (for premium product feel, not flat AI-cards)
  static List<BoxShadow> get cardShadowLight => [
        const BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
        const BoxShadow(
          color: Color(0x050F172A),
          blurRadius: 1,
          offset: Offset(0, 0),
        ),
      ];

  static List<BoxShadow> get cardShadowDark => [
        const BoxShadow(
          color: Color(0x30000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ];

  static List<BoxShadow> shadow(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardShadowDark
        : cardShadowLight;
  }
}
