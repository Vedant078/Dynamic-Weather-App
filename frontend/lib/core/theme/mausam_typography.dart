import 'package:flutter/material.dart';
import 'mausam_colors.dart';

/// Centralized Typography System for MAUSAM (design/skills.md Section 4 & prompt Section 4)
/// Communicates precision, environmental intelligence, infrastructure rigor, and calm trust.
/// Uses a deliberate hierarchical scale and tabular figures for all real-time telemetry.
class MausamTypography {
  MausamTypography._();

  static const String fontFamily = 'Inter';

  // 1. BRAND WORDMARK
  static const TextStyle brand = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.0,
    color: MausamColors.textPrimaryLight,
    height: 1.1,
  );

  static const TextStyle brandHero = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.5,
    color: MausamColors.textPrimaryLight,
    height: 1.1,
  );

  // 2. HERO & DISPLAY STATEMENTS
  static const TextStyle displayXL = TextStyle(
    fontSize: 34.0,
    fontWeight: FontWeight.w700,
    color: MausamColors.textPrimaryLight,
    letterSpacing: -0.9,
    height: 1.18,
  );

  static const TextStyle display = TextStyle(
    fontSize: 26.0,
    fontWeight: FontWeight.w700,
    color: MausamColors.textPrimaryLight,
    letterSpacing: -0.6,
    height: 1.22,
  );

  // 3. SCREEN & SECTION HEADLINES
  static const TextStyle headline = TextStyle(
    fontSize: 21.0,
    fontWeight: FontWeight.w700,
    color: MausamColors.textPrimaryLight,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static const TextStyle title = TextStyle(
    fontSize: 16.5,
    fontWeight: FontWeight.w600,
    color: MausamColors.textPrimaryLight,
    letterSpacing: -0.15,
    height: 1.3,
  );

  static const TextStyle section = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: MausamColors.textPrimaryLight,
    letterSpacing: 0.1,
    height: 1.35,
  );

  // 4. BODY CONTENT
  static const TextStyle body = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: MausamColors.textSecondaryLight,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: MausamColors.textPrimaryLight,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: MausamColors.textSecondaryLight,
    height: 1.4,
  );

  // 5. LABELS & METADATA
  static const TextStyle label = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: MausamColors.textSecondaryLight,
    letterSpacing: 0.2,
    height: 1.3,
  );

  static const TextStyle labelBold = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    color: MausamColors.textPrimaryLight,
    letterSpacing: 0.2,
    height: 1.3,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    color: MausamColors.textMutedLight,
    letterSpacing: 0.25,
    height: 1.25,
  );

  static const TextStyle micro = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    color: MausamColors.textMutedLight,
    letterSpacing: 0.2,
    height: 1.2,
  );

  // 6. OPERATIONAL METRICS & TABULAR NUMERALS (Prevents UI jump during live updates)
  static const TextStyle metric = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    color: MausamColors.textPrimaryLight,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -0.4,
  );

  static const TextStyle metricLarge = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w700,
    color: MausamColors.textPrimaryLight,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -0.8,
  );

  static const TextStyle metricSmall = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w700,
    color: MausamColors.textPrimaryLight,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // 7. SYSTEM STATUS & TELEMETRY TAGS
  static const TextStyle systemStatus = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    height: 1.1,
  );

  // Backward compatibility aliases
  static const TextStyle heading = title;
  static const TextStyle headingXL = headline;
  static const TextStyle tabularData = metric;
  static const TextStyle tabularDataLarge = metricLarge;

  // Context-aware dynamic resolution helpers
  static TextStyle brandOf(BuildContext context) =>
      brand.copyWith(color: MausamColors.txtPrimary(context));

  static TextStyle displayOf(BuildContext context) =>
      display.copyWith(color: MausamColors.txtPrimary(context));

  static TextStyle displayXLOf(BuildContext context) =>
      displayXL.copyWith(color: MausamColors.txtPrimary(context));

  static TextStyle headlineOf(BuildContext context) =>
      headline.copyWith(color: MausamColors.txtPrimary(context));

  static TextStyle headingOf(BuildContext context) =>
      title.copyWith(color: MausamColors.txtPrimary(context));

  static TextStyle titleOf(BuildContext context) =>
      title.copyWith(color: MausamColors.txtPrimary(context));

  static TextStyle sectionOf(BuildContext context) =>
      section.copyWith(color: MausamColors.txtPrimary(context));

  static TextStyle bodyOf(BuildContext context) =>
      body.copyWith(color: MausamColors.txtSecondary(context));

  static TextStyle bodyMediumOf(BuildContext context) =>
      bodyMedium.copyWith(color: MausamColors.txtPrimary(context));

  static TextStyle bodySmallOf(BuildContext context) =>
      bodySmall.copyWith(color: MausamColors.txtSecondary(context));

  static TextStyle labelOf(BuildContext context) =>
      label.copyWith(color: MausamColors.txtSecondary(context));

  static TextStyle labelBoldOf(BuildContext context) =>
      labelBold.copyWith(color: MausamColors.txtPrimary(context));

  static TextStyle captionOf(BuildContext context) =>
      caption.copyWith(color: MausamColors.txtMuted(context));

  static TextStyle microOf(BuildContext context) =>
      micro.copyWith(color: MausamColors.txtMuted(context));

  static TextStyle metricOf(BuildContext context) =>
      metric.copyWith(color: MausamColors.txtPrimary(context));

  static TextStyle metricLargeOf(BuildContext context) =>
      metricLarge.copyWith(color: MausamColors.txtPrimary(context));

  static TextStyle tabularOf(BuildContext context) =>
      metric.copyWith(color: MausamColors.txtPrimary(context));
}
