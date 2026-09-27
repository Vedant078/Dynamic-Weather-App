import 'package:flutter/material.dart';

/// Centralized Design Tokens for MAUSAM according to design/skills.md & reference guidelines
class MausamColors {
  MausamColors._();

  // Light Mode Surfaces (Default Editorial Presentation)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceSecondaryLight = Color(0xFFF1F5F9);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color surfaceInteractiveLight = Color(0xFFE2E8F0);

  // Light Mode Borders
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderSubtleLight = Color(0xFFEDF2F7);
  static const Color borderBrightLight = Color(0xFFCBD5E1);

  // Light Mode Typography
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Dark Mode Surfaces
  static const Color backgroundDark = Color(0xFF0B0F14);
  static const Color surfaceDark = Color(0xFF111820);
  static const Color surfaceSecondaryDark = Color(0xFF161E27);
  static const Color surfaceElevatedDark = Color(0xFF1C2631);
  static const Color surfaceInteractiveDark = Color(0xFF222F3D);

  // Dark Mode Borders
  static const Color borderDark = Color(0xFF27323D);
  static const Color borderSubtleDark = Color(0xFF1B242E);
  static const Color borderBrightDark = Color(0xFF384654);

  // Dark Mode Typography
  static const Color textPrimaryDark = Color(0xFFF3F6F8);
  static const Color textSecondaryDark = Color(0xFF9BA8B5);
  static const Color textMutedDark = Color(0xFF667481);

  // Static Fallback Defaults (Preserved for compatibility)
  static const Color background = backgroundLight;
  static const Color surface = surfaceLight;
  static const Color surfaceSecondary = surfaceSecondaryLight;
  static const Color surfaceElevated = surfaceElevatedLight;
  static const Color surfaceInteractive = surfaceInteractiveLight;

  static const Color border = borderLight;
  static const Color borderSubtle = borderSubtleLight;
  static const Color borderBright = borderBrightLight;

  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textMuted = textMutedLight;

  // Semantic Risk Tokens (Restrained, functional, bound to outcome meaning)
  static const Color safe = Color(0xFF15803D);          // Clean restrained emerald
  static const Color safeSubtle = Color(0x1815803D);
  
  static const Color watch = Color(0xFFD97706);         // Amber / Attention
  static const Color watchSubtle = Color(0x18D97706);
  
  static const Color highRisk = Color(0xFFDC2626);      // Red / Urgent Triage
  static const Color highRiskSubtle = Color(0x18DC2626);
  
  static const Color critical = Color(0xFFB91C1C);      // Immediate Failure
  static const Color criticalSubtle = Color(0x18B91C1C);
  
  static const Color info = Color(0xFF2563EB);          // Primary Logistics Blue
  static const Color infoSubtle = Color(0x182563EB);
  static const Color accent = info;                     // Primary interactive accent

  // Environmental & Atmosphere Palette (sky / atmosphere + rain / water + vegetation + warmth / heat)
  static const Color atmospherePrimary = Color(0xFF0284C7);   // Clear sky & telemetry blue
  static const Color atmosphereSecondary = Color(0xFF0891B2); // Cool atmospheric cyan
  static const Color vegetativeEmerald = Color(0xFF059669);   // Environmental signal / agriculture / safe
  static const Color thermalAmber = Color(0xFFD97706);        // Solar / hydration thermal warning
  static const Color criticalCrimson = Color(0xFFDC2626);     // Threshold breach & delivery risk
  static const Color corridorIndigo = Color(0xFF4F46E5);      // Infrastructure & freight route

  // Concrete Specific Accents
  static const Color concreteSlump = atmospherePrimary;      // Sky/cyan for slump retention
  static const Color concreteTemp = Color(0xFFEA580C);        // Orange for thermal hydration

  // Context-aware color resolution helpers
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      isDark(context) ? backgroundDark : backgroundLight;

  static Color surf(BuildContext context) =>
      isDark(context) ? surfaceDark : surfaceLight;

  static Color surfSecondary(BuildContext context) =>
      isDark(context) ? surfaceSecondaryDark : surfaceSecondaryLight;

  static Color surfElevated(BuildContext context) =>
      isDark(context) ? surfaceElevatedDark : surfaceElevatedLight;

  static Color brd(BuildContext context) =>
      isDark(context) ? borderDark : borderLight;

  static Color brdSubtle(BuildContext context) =>
      isDark(context) ? borderSubtleDark : borderSubtleLight;

  static Color txtPrimary(BuildContext context) =>
      isDark(context) ? textPrimaryDark : textPrimaryLight;

  static Color txtSecondary(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textSecondaryLight;

  static Color txtMuted(BuildContext context) =>
      isDark(context) ? textMutedDark : textMutedLight;
}
