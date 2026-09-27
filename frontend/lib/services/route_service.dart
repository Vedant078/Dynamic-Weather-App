import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/route_option.dart';

/// Canonical Geographic Location for RMC Operations in Ahmedabad / Gandhinagar
class LocationPoint {
  final String id;
  final String name;
  final String shortName;
  final double latitude;
  final double longitude;
  final bool isPlant;

  const LocationPoint({
    required this.id,
    required this.name,
    required this.shortName,
    required this.latitude,
    required this.longitude,
    required this.isPlant,
  });
}

/// Normalized 2D coordinate on a [0.0 .. 1.0] unit square for map canvas rendering
class MapPoint {
  final double x;
  final double y;
  const MapPoint(this.x, this.y);

  Offset toOffset(Size size) => Offset(x * size.width, y * size.height);
}

/// Canonical Route Assessment Data Model (PRD.md Section 3 & 8)
/// Single source of truth feeding Map, Distance, ETA, Traffic, and Risk Engine.
class RouteAssessment {
  final LocationPoint origin;
  final LocationPoint destination;
  final String routeId;
  final String routeName;
  final double distanceKm;
  final double baseTransitMinutes;
  final double expectedDelayMin;
  final double etaMinutes;
  final double trafficIndex;
  final String trafficLevel;
  final double ambientTempC;
  final double precipitationProb;
  final String primaryDriver;
  final List<String> riskFactors;

  // Normalized visual trajectory control points [0..1]
  final MapPoint originPoint;
  final MapPoint destinationPoint;
  final List<MapPoint> primaryPathPoints;
  final List<MapPoint>? alternatePathPoints;
  final String? alternateRouteId;
  final String? alternateRouteName;
  final double? alternateEtaMinutes;
  final double? alternateDistanceKm;

  // Congestion bottleneck range along path [startRatio..endRatio]
  final double? bottleneckStart;
  final double? bottleneckEnd;
  final String? bottleneckDescription;

  const RouteAssessment({
    required this.origin,
    required this.destination,
    required this.routeId,
    required this.routeName,
    required this.distanceKm,
    required this.baseTransitMinutes,
    required this.expectedDelayMin,
    required this.etaMinutes,
    required this.trafficIndex,
    required this.trafficLevel,
    required this.ambientTempC,
    required this.precipitationProb,
    required this.primaryDriver,
    required this.riskFactors,
    required this.originPoint,
    required this.destinationPoint,
    required this.primaryPathPoints,
    this.alternatePathPoints,
    this.alternateRouteId,
    this.alternateRouteName,
    this.alternateEtaMinutes,
    this.alternateDistanceKm,
    this.bottleneckStart,
    this.bottleneckEnd,
    this.bottleneckDescription,
  });

  bool get hasBottleneck => bottleneckStart != null && bottleneckEnd != null;

  RouteOptionModel toRouteOptionModel({bool isRecommended = false}) {
    return RouteOptionModel(
      routeId: routeId,
      routeName: routeName,
      isRecommended: isRecommended,
      etaMinutes: etaMinutes,
      distanceKm: distanceKm,
      deliveryRisk: etaMinutes > 78.0 ? 76.0 : (etaMinutes > 65.0 ? 48.0 : 28.0),
      heatRisk: ambientTempC > 38.0 ? 70.0 : 38.0,
      travelRisk: expectedDelayMin > 10.0 ? 78.0 : (expectedDelayMin > 4.0 ? 45.0 : 22.0),
      trafficLevel: trafficLevel,
      weatherSummary: precipitationProb > 40.0 ? 'Overcast / High Rain Prob' : '${ambientTempC.toInt()}°C Moderate Heat',
      tradeOffExplanation: primaryDriver,
      waypoints: [
        WaypointModel(lat: origin.latitude, lng: origin.longitude, name: origin.name),
        WaypointModel(lat: destination.latitude, lng: destination.longitude, name: destination.name),
      ],
    );
  }
}

/// Canonical Route Service for MAUSAM.
/// Provides deterministic, location-driven routing and geography across Ahmedabad-Gandhinagar.
class RouteService {
  // ---------------------------------------------------------------------------
  // CANONICAL PLANTS CATALOGUE
  // ---------------------------------------------------------------------------
  static const LocationPoint plantNaroda = LocationPoint(
    id: 'plant-001',
    name: 'Ahmedabad Plant 01 (Naroda)',
    shortName: 'Plant 01 (Naroda)',
    latitude: 23.0650,
    longitude: 72.6450,
    isPlant: true,
  );

  static const LocationPoint plantSanand = LocationPoint(
    id: 'plant-002',
    name: 'Ahmedabad Plant 02 - Sanand',
    shortName: 'Plant 02 (Sanand)',
    latitude: 22.9900,
    longitude: 72.3800,
    isPlant: true,
  );

  static const LocationPoint plantGandhinagar = LocationPoint(
    id: 'plant-003',
    name: 'Gandhinagar Plant 03',
    shortName: 'Plant 03 (Gandhinagar)',
    latitude: 23.2500,
    longitude: 72.6500,
    isPlant: true,
  );

  // ---------------------------------------------------------------------------
  // CANONICAL PROJECT SITES CATALOGUE
  // ---------------------------------------------------------------------------
  static const LocationPoint siteGiftCity = LocationPoint(
    id: 'proj-gift-city',
    name: 'Gift City Tower B',
    shortName: 'Gift City (Site 07)',
    latitude: 23.1600,
    longitude: 72.6850,
    isPlant: false,
  );

  static const LocationPoint siteThaltej = LocationPoint(
    id: 'proj-thaltej',
    name: 'Metro Pier 142 - Thaltej',
    shortName: 'Thaltej Pier 142',
    latitude: 23.0500,
    longitude: 72.5100,
    isPlant: false,
  );

  static const LocationPoint siteRiverfront = LocationPoint(
    id: 'proj-riverfront',
    name: 'Riverfront Phase 2',
    shortName: 'Riverfront (Site 03)',
    latitude: 23.0300,
    longitude: 72.5750,
    isPlant: false,
  );

  static const LocationPoint siteRingRoad = LocationPoint(
    id: 'proj-ring-road',
    name: 'Ring Road Overbridge',
    shortName: 'Ring Road (Site 12)',
    latitude: 22.9700,
    longitude: 72.5900,
    isPlant: false,
  );

  static List<LocationPoint> get allPlants => [
        plantNaroda,
        plantSanand,
        plantGandhinagar,
      ];

  static List<LocationPoint> get allProjects => [
        siteGiftCity,
        siteThaltej,
        siteRiverfront,
        siteRingRoad,
      ];

  /// Resolves any string query (name or ID) to a canonical plant point
  static LocationPoint resolvePlant(String query) {
    final q = query.toLowerCase().trim();
    if (q.contains('sanand') || q.contains('plant-002') || q.contains('02')) {
      return plantSanand;
    }
    if (q.contains('gandhinagar') || q.contains('plant-003') || q.contains('03')) {
      return plantGandhinagar;
    }
    return plantNaroda;
  }

  /// Resolves any string query (name or ID) to a canonical project site point
  static LocationPoint resolveProject(String query) {
    final q = query.toLowerCase().trim();
    if (q.contains('thaltej') || q.contains('pier') || q.contains('metro')) {
      return siteThaltej;
    }
    if (q.contains('riverfront') || q.contains('site 03') || q.contains('sabarmati')) {
      return siteRiverfront;
    }
    if (q.contains('ring road') || q.contains('site 12') || q.contains('overbridge') || q.contains('logistics')) {
      return siteRingRoad;
    }
    return siteGiftCity;
  }

  /// Converts geographic lat/lng to normalized map canvas coordinates [0.1 .. 0.9]
  /// Bounds: Lat [22.92 .. 23.30], Lng [72.34 .. 72.74]
  static MapPoint toMapPoint(double lat, double lng) {
    const minLat = 22.94;
    const maxLat = 23.28;
    const minLng = 72.35;
    const maxLng = 72.72;

    final double normX = ((lng - minLng) / (maxLng - minLng)).clamp(0.08, 0.92);
    // Invert Y because canvas Y=0 is top (North), Y=1 is bottom (South)
    final double normY = (1.0 - ((lat - minLat) / (maxLat - minLat))).clamp(0.08, 0.92);

    return MapPoint(normX, normY);
  }

  /// Generates the canonical RouteAssessment for any origin and destination pair
  static RouteAssessment getRoute({
    required String originName,
    required String destinationName,
    String? preferredRouteId,
  }) {
    final plant = resolvePlant(originName);
    final project = resolveProject(destinationName);

    final originPt = toMapPoint(plant.latitude, plant.longitude);
    final destPt = toMapPoint(project.latitude, project.longitude);

    // Calculate realistic geographic straight-line and road distance
    final double crowFlyKm = _haversineKm(
      plant.latitude,
      plant.longitude,
      project.latitude,
      project.longitude,
    );
    // Real roads in urban/peri-urban Gujarat are ~1.28x crow-fly distance
    final double distanceKm = double.parse((crowFlyKm * 1.28).clamp(12.0, 48.0).toStringAsFixed(1));

    final normRoute = (preferredRouteId ?? 'route-a').replaceAll('_', '-').toLowerCase();
    final bool isRouteB = normRoute.contains('route-b');
    final bool isRouteC = normRoute.contains('route-c');
    final String routeId = isRouteB ? 'route-b' : (isRouteC ? 'route-c' : 'route-a');

    // Determine corridor characteristics based on geography
    final bool isNarodaToGift = plant.id == plantNaroda.id && project.id == siteGiftCity.id;
    final bool isSanandOrigin = plant.id == plantSanand.id;
    final bool isGandhinagarOrigin = plant.id == plantGandhinagar.id;

    String routeName;
    double baseTransitMin;
    double delayMin = 0.0;
    double trafficIdx = 0.35;
    double effectiveDistKm = distanceKm;
    String trafficLevel = 'Nominal flow';
    double ambientTemp = 36.0;
    double rainProb = 5.0;
    String primaryDriver = 'Transit on schedule within safe slump envelope';
    List<String> riskFactors = ['Route moving normally', 'Slump retention nominal'];

    // Generate dynamic spline control points between origin and destination
    List<MapPoint> primaryPath;
    List<MapPoint>? alternatePath;
    String? altRouteId;
    String? altRouteName;
    double? altEtaMin;
    double? altDistKm;
    double? botStart;
    double? botEnd;
    String? botDesc;

    if (isNarodaToGift) {
      if (isRouteB) {
        routeName = 'Route B (Airport Bypass Expressway)';
        effectiveDistKm = 26.8;
        baseTransitMin = 48.0;
        delayMin = 2.0;
        trafficIdx = 0.28;
        trafficLevel = 'Free flow (Expressway)';
        primaryDriver = 'Airport Bypass active; clear expressway transit';
        riskFactors = ['Alternative Route B active (-9 min transit saving)', 'Slump retention protected'];
        primaryPath = [
          originPt,
          MapPoint(originPt.x + 0.02, originPt.y - 0.20),
          MapPoint((originPt.x + destPt.x) / 2 + 0.10, (originPt.y + destPt.y) / 2 - 0.08),
          destPt,
        ];
        alternatePath = [
          originPt,
          MapPoint(originPt.x + 0.08, originPt.y - 0.12),
          MapPoint((originPt.x + destPt.x) / 2 - 0.04, (originPt.y + destPt.y) / 2),
          destPt,
        ];
        altRouteId = 'route-a';
        altRouteName = 'Route A (SP Ring Road)';
        altEtaMin = 68.0;
        altDistKm = 24.2;
      } else if (isRouteC) {
        routeName = 'Route C (Outer Ring Road Express)';
        effectiveDistKm = 31.4;
        baseTransitMin = 62.0;
        delayMin = 4.0;
        trafficIdx = 0.40;
        trafficLevel = 'Moderate Outer Flow';
        primaryDriver = 'Outer Ring Road corridor bypasses urban congestion';
        riskFactors = ['Longer transit buffer', 'Pavement temperature 37°C'];
        primaryPath = [
          originPt,
          MapPoint(originPt.x + 0.12, originPt.y - 0.10),
          MapPoint((originPt.x + destPt.x) / 2 + 0.14, (originPt.y + destPt.y) / 2 - 0.04),
          destPt,
        ];
        altRouteId = 'route-b';
        altRouteName = 'Route B (Airport Bypass)';
        altEtaMin = 50.0;
        altDistKm = 26.8;
      } else {
        routeName = 'Route A (SP Ring Road via Chiloda)';
        effectiveDistKm = 24.2;
        baseTransitMin = 54.0;
        delayMin = 14.0;
        trafficIdx = 0.72;
        trafficLevel = 'Severe Congestion (+14m bottleneck)';
        ambientTemp = 39.5;
        rainProb = 62.0;
        primaryDriver = 'Congestion bottleneck near Nana Chiloda adds 14m delay';
        riskFactors = ['SP Ring Road congestion (+14 min)', 'Hydration temperature accelerating'];
        botStart = 0.38;
        botEnd = 0.65;
        botDesc = '⚠️ Nana Chiloda Congestion (+14m)';
        primaryPath = [
          originPt,
          MapPoint(originPt.x + 0.08, originPt.y - 0.12),
          MapPoint((originPt.x + destPt.x) / 2 - 0.04, (originPt.y + destPt.y) / 2),
          destPt,
        ];
        alternatePath = [
          originPt,
          MapPoint(originPt.x + 0.02, originPt.y - 0.20),
          MapPoint((originPt.x + destPt.x) / 2 + 0.10, (originPt.y + destPt.y) / 2 - 0.08),
          destPt,
        ];
        altRouteId = 'route-b';
        altRouteName = 'Route B (Airport Bypass)';
        altEtaMin = 50.0;
        altDistKm = 26.8;
      }
    } else if (isSanandOrigin) {
      if (isRouteB) {
        routeName = 'Route B (SP Ring Road Bypass)';
        effectiveDistKm = distanceKm + 3.2;
        baseTransitMin = double.parse((effectiveDistKm * 1.35).toStringAsFixed(0));
        delayMin = 2.0;
        trafficIdx = 0.25;
        trafficLevel = 'Free flow bypass';
        primaryDriver = 'Outer arterial bypass avoiding industrial junction';
        riskFactors = ['Bypass active', 'Nominal hydration window'];
        primaryPath = [
          originPt,
          MapPoint(originPt.x + 0.10, originPt.y - 0.08),
          MapPoint((originPt.x + destPt.x) / 2 + 0.02, (originPt.y + destPt.y) / 2 - 0.05),
          destPt,
        ];
        altRouteId = 'route-a';
        altRouteName = 'Route A (Sanand Arterial)';
        altEtaMin = baseTransitMin + 6.0;
        altDistKm = distanceKm;
      } else if (isRouteC) {
        routeName = 'Route C (Viramgam Outer Highway)';
        effectiveDistKm = distanceKm + 6.5;
        baseTransitMin = double.parse((effectiveDistKm * 1.4).toStringAsFixed(0));
        delayMin = 3.0;
        trafficIdx = 0.32;
        trafficLevel = 'Wide highway transit';
        primaryDriver = 'Extended highway corridor with consistent speed';
        riskFactors = ['Long distance corridor', 'Target SLA within margin'];
        primaryPath = [
          originPt,
          MapPoint(originPt.x + 0.05, originPt.y + 0.10),
          MapPoint((originPt.x + destPt.x) / 2, (originPt.y + destPt.y) / 2 + 0.08),
          destPt,
        ];
      } else {
        routeName = 'Route A (Sanand Direct Arterial)';
        baseTransitMin = double.parse((distanceKm * 1.5).toStringAsFixed(0));
        delayMin = 8.0;
        trafficIdx = 0.52;
        trafficLevel = 'Moderate industrial traffic (+8m)';
        primaryDriver = 'Direct industrial highway from Sanand Plant';
        riskFactors = ['Industrial freight traffic', 'Moderate ambient thermal loading'];
        botStart = 0.40;
        botEnd = 0.65;
        botDesc = '⚠️ Sanand GIDC Slowdown (+8m)';
        primaryPath = [
          originPt,
          MapPoint(originPt.x + 0.14, originPt.y + 0.06),
          MapPoint((originPt.x + destPt.x) / 2, (originPt.y + destPt.y) / 2 + 0.04),
          destPt,
        ];
        alternatePath = [
          originPt,
          MapPoint(originPt.x + 0.10, originPt.y - 0.08),
          MapPoint((originPt.x + destPt.x) / 2 + 0.02, (originPt.y + destPt.y) / 2 - 0.05),
          destPt,
        ];
        altRouteId = 'route-b';
        altRouteName = 'Route B (SP Ring Road Bypass)';
        altEtaMin = baseTransitMin - 4.0;
        altDistKm = distanceKm + 3.2;
      }
    } else if (isGandhinagarOrigin) {
      if (isRouteB) {
        routeName = 'Route B (Koba Circle Expressway)';
        effectiveDistKm = distanceKm + 2.5;
        baseTransitMin = double.parse((effectiveDistKm * 1.3).toStringAsFixed(0));
        delayMin = 2.0;
        trafficIdx = 0.26;
        trafficLevel = 'Expressway flow';
        primaryDriver = 'Koba Circle expressway corridor with signal priority';
        riskFactors = ['Clear signal progression', 'Slump protected'];
        primaryPath = [
          originPt,
          MapPoint(originPt.x + 0.06, originPt.y + 0.12),
          MapPoint((originPt.x + destPt.x) / 2 + 0.04, (originPt.y + destPt.y) / 2),
          destPt,
        ];
      } else if (isRouteC) {
        routeName = 'Route C (GIFT City Service Corridor)';
        effectiveDistKm = distanceKm + 5.0;
        baseTransitMin = double.parse((effectiveDistKm * 1.4).toStringAsFixed(0));
        delayMin = 3.0;
        trafficIdx = 0.35;
        trafficLevel = 'Peripheral arterial';
        primaryDriver = 'Suburban arterial avoiding SG Highway';
        riskFactors = ['Longer transit', 'Steady cruising speed'];
        primaryPath = [
          originPt,
          MapPoint(originPt.x + 0.10, originPt.y + 0.08),
          MapPoint((originPt.x + destPt.x) / 2 + 0.08, (originPt.y + destPt.y) / 2 + 0.05),
          destPt,
        ];
      } else {
        routeName = 'Route A (SG Highway Southbound)';
        baseTransitMin = double.parse((distanceKm * 1.45).toStringAsFixed(0));
        delayMin = 7.0;
        trafficIdx = 0.50;
        trafficLevel = 'Moderate peak corridor';
        primaryDriver = 'Direct southbound transit along SG Highway';
        riskFactors = ['SG Highway arterial signals', 'Target delivery window achievable'];
        botStart = 0.35;
        botEnd = 0.60;
        botDesc = '⚠️ Infocity Junction Delay (+7m)';
        primaryPath = [
          originPt,
          MapPoint(originPt.x - 0.05, originPt.y + 0.15),
          MapPoint((originPt.x + destPt.x) / 2 - 0.03, (originPt.y + destPt.y) / 2),
          destPt,
        ];
        alternatePath = [
          originPt,
          MapPoint(originPt.x + 0.06, originPt.y + 0.12),
          MapPoint((originPt.x + destPt.x) / 2 + 0.04, (originPt.y + destPt.y) / 2),
          destPt,
        ];
        altRouteId = 'route-b';
        altRouteName = 'Route B (Koba Circle Expressway)';
      }
    } else {
      // General Origin / Destination Pairing
      if (isRouteB) {
        routeName = 'Route B (Expressway Bypass)';
        effectiveDistKm = distanceKm + 3.0;
        baseTransitMin = double.parse((effectiveDistKm * 1.35).toStringAsFixed(0));
        delayMin = 2.0;
        trafficIdx = 0.28;
        trafficLevel = 'Free flow bypass';
        primaryDriver = 'Dedicated bypass route minimizing transit variance';
        riskFactors = ['Bypass active', 'Slump retention protected'];
        primaryPath = [
          originPt,
          MapPoint((originPt.x * 2 + destPt.x) / 3 - 0.05, (originPt.y * 2 + destPt.y) / 3 - 0.04),
          MapPoint((originPt.x + destPt.x * 2) / 3 + 0.05, (originPt.y + destPt.y * 2) / 3 - 0.03),
          destPt,
        ];
      } else if (isRouteC) {
        routeName = 'Route C (Outer Ring Road)';
        effectiveDistKm = distanceKm + 5.5;
        baseTransitMin = double.parse((effectiveDistKm * 1.45).toStringAsFixed(0));
        delayMin = 3.0;
        trafficIdx = 0.36;
        trafficLevel = 'Outer ring flow';
        primaryDriver = 'Outer perimeter corridor avoiding central city';
        riskFactors = ['Extended distance (+5.5 km)', 'Nominal travel risk'];
        primaryPath = [
          originPt,
          MapPoint((originPt.x * 2 + destPt.x) / 3 + 0.08, (originPt.y * 2 + destPt.y) / 3 + 0.06),
          MapPoint((originPt.x + destPt.x * 2) / 3 + 0.06, (originPt.y + destPt.y * 2) / 3 + 0.04),
          destPt,
        ];
      } else {
        routeName = 'Route A (Direct Corridor)';
        baseTransitMin = double.parse((distanceKm * 1.5).toStringAsFixed(0));
        delayMin = 6.0;
        trafficIdx = 0.46;
        trafficLevel = 'Moderate arterial traffic';
        primaryDriver = 'Direct arterial transit between ${plant.shortName} and ${project.shortName}';
        riskFactors = ['Corridor transit nominal', 'Hydration kinetics tracked'];
        primaryPath = [
          originPt,
          MapPoint((originPt.x * 2 + destPt.x) / 3, (originPt.y * 2 + destPt.y) / 3 + 0.04),
          MapPoint((originPt.x + destPt.x * 2) / 3 - 0.03, (originPt.y + destPt.y * 2) / 3),
          destPt,
        ];
        alternatePath = [
          originPt,
          MapPoint((originPt.x * 2 + destPt.x) / 3 - 0.05, (originPt.y * 2 + destPt.y) / 3 - 0.04),
          MapPoint((originPt.x + destPt.x * 2) / 3 + 0.05, (originPt.y + destPt.y * 2) / 3 - 0.03),
          destPt,
        ];
        altRouteId = 'route-b';
        altRouteName = 'Route B (Expressway Bypass)';
      }
    }

    final double totalEta = baseTransitMin + delayMin;

    return RouteAssessment(
      origin: plant,
      destination: project,
      routeId: routeId,
      routeName: routeName,
      distanceKm: effectiveDistKm,
      baseTransitMinutes: baseTransitMin,
      expectedDelayMin: delayMin,
      etaMinutes: totalEta,
      trafficIndex: trafficIdx,
      trafficLevel: trafficLevel,
      ambientTempC: ambientTemp,
      precipitationProb: rainProb,
      primaryDriver: primaryDriver,
      riskFactors: riskFactors,
      originPoint: originPt,
      destinationPoint: destPt,
      primaryPathPoints: primaryPath,
      alternatePathPoints: alternatePath,
      alternateRouteId: altRouteId,
      alternateRouteName: altRouteName,
      alternateEtaMinutes: altEtaMin,
      alternateDistanceKm: altDistKm,
      bottleneckStart: botStart,
      bottleneckEnd: botEnd,
      bottleneckDescription: botDesc,
    );
  }

  /// Validates that a rendered route strictly matches currently selected origin and destination
  static bool validateRoute({
    required RouteAssessment? route,
    required String originName,
    required String destinationName,
  }) {
    if (route == null) return false;
    final plant = resolvePlant(originName);
    final project = resolveProject(destinationName);
    return route.origin.id == plant.id && route.destination.id == project.id;
  }

  /// Returns 3 deterministic route candidates for any origin and destination pair
  static List<RouteAssessment> getCandidateRoutes({
    required String originName,
    required String destinationName,
  }) {
    final rA = getRoute(originName: originName, destinationName: destinationName, preferredRouteId: 'route-a');
    final rB = getRoute(originName: originName, destinationName: destinationName, preferredRouteId: 'route-b');
    final rC = getRoute(originName: originName, destinationName: destinationName, preferredRouteId: 'route-c');
    return [rA, rB, rC];
  }

  /// Returns 3 RouteOptionModel objects ready for UI display
  static List<RouteOptionModel> getCandidateRouteOptions({
    required String originName,
    required String destinationName,
  }) {
    final routes = getCandidateRoutes(originName: originName, destinationName: destinationName);
    return [
      routes[0].toRouteOptionModel(isRecommended: routes[0].etaMinutes < routes[1].etaMinutes),
      routes[1].toRouteOptionModel(isRecommended: routes[1].etaMinutes <= routes[0].etaMinutes),
      routes[2].toRouteOptionModel(isRecommended: false),
    ];
  }

  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // Earth radius in km
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) * math.cos(_degToRad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
}
