import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Semantic Icon System for MAUSAM (design/skills.md Section 6 & prompt Section 7)
/// Enforces a single, coherent line-based icon family (Lucide) with consistent optical sizes
/// and domain mappings for environmental and infrastructure intelligence.
class MausamIcons {
  MausamIcons._();

  // Optical standard sizes
  static const double sizeMicro = 12.0;
  static const double sizeSmall = 15.0;
  static const double sizeStandard = 18.0;
  static const double sizeMedium = 20.0;
  static const double sizeLarge = 24.0;
  static const double sizeHero = 32.0;

  // Domain Mappings: Environmental & Weather
  static const IconData weather = LucideIcons.cloudSun;
  static const IconData rain = LucideIcons.cloudRain;
  static const IconData wind = LucideIcons.wind;
  static const IconData temperature = LucideIcons.thermometer;
  static const IconData humidity = LucideIcons.droplets;
  static const IconData sun = LucideIcons.sun;
  static const IconData moon = LucideIcons.moon;
  static const IconData atmosphericPressure = LucideIcons.gauge;
  static const IconData airQuality = LucideIcons.sparkles;

  // Domain Mappings: Infrastructure, Fleet & Logistics
  static const IconData truck = LucideIcons.truck;
  static const IconData plant = LucideIcons.factory;
  static const IconData project = LucideIcons.hardHat;
  static const IconData route = LucideIcons.milestone;
  static const IconData navigation = LucideIcons.navigation;
  static const IconData compass = LucideIcons.compass;
  static const IconData mapPin = LucideIcons.mapPin;
  static const IconData batch = LucideIcons.packageCheck;
  static const IconData slump = LucideIcons.activity;
  static const IconData admixture = LucideIcons.flaskConical;
  static const IconData verifiedOutcome = LucideIcons.checkCheck;

  // Domain Mappings: Risk & Operational Intelligence
  static const IconData riskSafe = LucideIcons.shieldCheck;
  static const IconData riskWatch = LucideIcons.alertCircle;
  static const IconData riskHigh = LucideIcons.triangleAlert;
  static const IconData riskCritical = LucideIcons.shieldAlert;
  static const IconData alert = LucideIcons.bell;
  static const IconData trendUp = LucideIcons.trendingUp;
  static const IconData trendDown = LucideIcons.trendingDown;
  static const IconData time = LucideIcons.clock;
  static const IconData timer = LucideIcons.timer;
  static const IconData currencyRupee = LucideIcons.indianRupee;

  // UI Navigation & Actions
  static const IconData back = LucideIcons.arrowLeft;
  static const IconData next = LucideIcons.arrowRight;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData close = LucideIcons.x;
  static const IconData check = LucideIcons.check;
  static const IconData search = LucideIcons.search;
  static const IconData filter = LucideIcons.slidersHorizontal;
  static const IconData eye = LucideIcons.eye;
  static const IconData eyeOff = LucideIcons.eyeOff;
  static const IconData play = LucideIcons.playCircle;
  static const IconData reset = LucideIcons.rotateCcw;
  static const IconData external = LucideIcons.externalLink;

  // Personas
  static const IconData personaRmc = LucideIcons.truck;
  static const IconData personaHealth = LucideIcons.heartPulse;
  static const IconData personaFitness = LucideIcons.bike;
  static const IconData personaBeach = LucideIcons.waves;
  static const IconData personaTraveler = LucideIcons.route;
  static const IconData personaFamily = LucideIcons.users;
  static const IconData personaAgriculture = LucideIcons.sprout;

  /// Helper widget for rendering semantic MAUSAM icons with consistent optical standards
  static Widget icon(
    IconData data, {
    double size = sizeStandard,
    Color? color,
  }) {
    return Icon(
      data,
      size: size,
      color: color,
    );
  }
}
