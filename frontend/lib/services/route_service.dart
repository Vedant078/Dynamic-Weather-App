import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/route_option.dart';
import '../models/area.dart';
import 'area_service.dart';

/// Canonical Geographic Location for RMC Operations
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

  factory LocationPoint.fromArea(Area area, {bool isPlant = false}) {
    return LocationPoint(
      id: area.id,
      name: area.name,
      shortName: area.name,
      latitude: area.latitude,
      longitude: area.longitude,
      isPlant: isPlant,
    );
  }

  Area toArea() {
    return Area(
      id: id,
      name: name,
      city: name,
      state: 'Gujarat',
      country: 'India',
      latitude: latitude,
      longitude: longitude,
    );
  }
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
/// Provides dynamic, location-driven routing and geography across generalized operational areas.
/// Uses live OSRM driving engine with realistic highway corridor geometry fallback.
class RouteService {
  static const String osrmBaseUrl = 'https://router.project-osrm.org/route/v1/driving';

  // ---------------------------------------------------------------------------
  // CANONICAL PLANTS CATALOGUE (Backward compatibility)
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
    latitude: 22.9868,
    longitude: 72.3814,
    isPlant: true,
  );

  static const LocationPoint plantGandhinagar = LocationPoint(
    id: 'plant-003',
    name: 'Gandhinagar Plant 03',
    shortName: 'Plant 03 (Gandhinagar)',
    latitude: 23.2156,
    longitude: 72.6369,
    isPlant: true,
  );

  // ---------------------------------------------------------------------------
  // CANONICAL PROJECT SITES CATALOGUE (Backward compatibility)
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

  /// Resolves any string query (name or ID) to a location point.
  /// Checks generalized AreaService first, never blindly falling back to one fixed coordinate.
  static LocationPoint resolvePlant(String query) {
    final q = query.toLowerCase().trim();
    if (q.contains('naroda') || q.contains('plant-001') || q.contains('plant 01') || q.contains('plant 1')) {
      return plantNaroda;
    }
    if (q.contains('sanand') || q.contains('plant-002') || q.contains('plant 02') || q.contains('plant 2')) {
      return plantSanand;
    }
    if (q.contains('gandhinagar plant') || q.contains('plant-003') || q.contains('plant 03') || q.contains('plant 3')) {
      return plantGandhinagar;
    }

    final area = AreaService.findAreaByName(query);
    if (area != null) {
      return LocationPoint.fromArea(area, isPlant: true);
    }

    // Default to Ahmedabad area coordinates if explicitly mentioned or unmatched
    final ahm = AreaService.getAreaById('area-ahmedabad')!;
    return LocationPoint(
      id: 'area-${query.hashCode.abs()}',
      name: query.isNotEmpty ? query : ahm.name,
      shortName: query.isNotEmpty ? query : ahm.name,
      latitude: ahm.latitude,
      longitude: ahm.longitude,
      isPlant: true,
    );
  }

  /// Resolves any string query (name or ID) to a project site point.
  /// Checks generalized AreaService first, never blindly falling back to GIFT City.
  static LocationPoint resolveProject(String query) {
    final area = AreaService.findAreaByName(query);
    if (area != null) {
      return LocationPoint.fromArea(area, isPlant: false);
    }

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
    if (q.contains('gift city') || q.contains('tower b') || q.contains('site 07')) {
      return siteGiftCity;
    }

    // Default to Gandhinagar area coordinates if unmatched
    final gandhi = AreaService.getAreaById('area-gandhinagar')!;
    return LocationPoint(
      id: 'area-${query.hashCode.abs()}',
      name: query.isNotEmpty ? query : gandhi.name,
      shortName: query.isNotEmpty ? query : gandhi.name,
      latitude: gandhi.latitude,
      longitude: gandhi.longitude,
      isPlant: false,
    );
  }

  /// Converts geographic lat/lng to normalized map canvas coordinates [0.08 .. 0.92]
  /// Dynamically normalizes within provided or computed geographic bounding box (Section 8).
  static MapPoint toMapPoint(
    double lat,
    double lng, {
    double? minLat,
    double? maxLat,
    double? minLng,
    double? maxLng,
  }) {
    final bMinLat = minLat ?? 21.0;
    final bMaxLat = maxLat ?? 23.8;
    final bMinLng = minLng ?? 72.0;
    final bMaxLng = maxLng ?? 73.5;

    final spanLat = math.max(0.005, (bMaxLat - bMinLat).abs());
    final spanLng = math.max(0.005, (bMaxLng - bMinLng).abs());

    final double normX = ((lng - bMinLng) / spanLng).clamp(0.08, 0.92);
    // Invert Y because canvas Y=0 is North, Y=1 is South
    final double normY = (1.0 - ((lat - bMinLat) / spanLat)).clamp(0.08, 0.92);

    return MapPoint(normX, normY);
  }

  /// Asynchronously fetches live OSRM driving route between origin and destination coordinates (Section 7).
  /// Falls back cleanly to deterministic highway corridor model if network times out.
  static Future<RouteAssessment> fetchDynamicRoute({
    required LocationPoint origin,
    required LocationPoint destination,
    String? preferredRouteId,
  }) async {
    try {
      final url = Uri.parse(
        '$osrmBaseUrl/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=simplified&geometries=geojson',
      );
      final response = await http.get(url).timeout(const Duration(milliseconds: 2500));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['code'] == 'Ok' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final routeInfo = (data['routes'] as List).first as Map<String, dynamic>;
          final double distanceKm = double.parse(((routeInfo['distance'] as num) / 1000.0).toStringAsFixed(1));
          final double durationMin = double.parse(((routeInfo['duration'] as num) / 60.0).toStringAsFixed(1));
          final coords = (routeInfo['geometry']?['coordinates'] as List?) ?? [];

          final List<math.Point<double>> waypoints = [];
          if (coords.isNotEmpty) {
            final step = math.max(1, coords.length ~/ 10);
            for (int i = 0; i < coords.length; i += step) {
              final c = coords[i] as List;
              waypoints.add(math.Point((c[1] as num).toDouble(), (c[0] as num).toDouble()));
            }
            final last = coords.last as List;
            waypoints.add(math.Point((last[1] as num).toDouble(), (last[0] as num).toDouble()));
          }

          return getRoute(
            originName: origin.name,
            destinationName: destination.name,
            preferredRouteId: preferredRouteId,
            customOrigin: origin,
            customDestination: destination,
            liveDistanceKm: distanceKm,
            liveDurationMin: durationMin,
            liveGeoWaypoints: waypoints,
          );
        }
      }
    } catch (_) {}

    // Clean deterministic fallback using actual highway geography
    return getRoute(
      originName: origin.name,
      destinationName: destination.name,
      preferredRouteId: preferredRouteId,
      customOrigin: origin,
      customDestination: destination,
    );
  }

  /// Generates the canonical RouteAssessment directly from two generalized Area models (Section 1, 6, 7, 8, 9).
  static RouteAssessment getRouteForAreas({
    required Area origin,
    required Area destination,
    String? preferredRouteId,
  }) {
    return getRoute(
      originName: origin.name,
      destinationName: destination.name,
      preferredRouteId: preferredRouteId,
      customOrigin: LocationPoint.fromArea(origin, isPlant: true),
      customDestination: LocationPoint.fromArea(destination, isPlant: false),
    );
  }

  /// Generates the canonical RouteAssessment for any origin and destination pair (Section 6, 7, 8, 9).
  static RouteAssessment getRoute({
    required String originName,
    required String destinationName,
    String? preferredRouteId,
    LocationPoint? customOrigin,
    LocationPoint? customDestination,
    double? liveDistanceKm,
    double? liveDurationMin,
    List<math.Point<double>>? liveGeoWaypoints,
  }) {
    final plant = customOrigin ?? resolvePlant(originName);
    final project = customDestination ?? resolveProject(destinationName);

    // Identify corridor endpoints for real highway routing
    final pLat = plant.latitude;
    final pLng = plant.longitude;
    final dLat = project.latitude;
    final dLng = project.longitude;

    // Real highway waypoints lookup across Gujarat operational geography (Section 7)
    final List<math.Point<double>> geoPoints = liveGeoWaypoints ?? _resolveHighwayCorridor(pLat, pLng, dLat, dLng);

    // Dynamic bounding box with 20% margin around ALL waypoints so entire route fits viewport (Section 8)
    double minLat = math.min(pLat, dLat);
    double maxLat = math.max(pLat, dLat);
    double minLng = math.min(pLng, dLng);
    double maxLng = math.max(pLng, dLng);

    for (final pt in geoPoints) {
      minLat = math.min(minLat, pt.x);
      maxLat = math.max(maxLat, pt.x);
      minLng = math.min(minLng, pt.y);
      maxLng = math.max(maxLng, pt.y);
    }

    final spanLat = (maxLat - minLat).abs();
    final spanLng = (maxLng - minLng).abs();
    final padLat = math.max(spanLat * 0.22, 0.03);
    final padLng = math.max(spanLng * 0.22, 0.03);

    final bMinLat = minLat - padLat;
    final bMaxLat = maxLat + padLat;
    final bMinLng = minLng - padLng;
    final bMaxLng = maxLng + padLng;

    final originPt = toMapPoint(pLat, pLng, minLat: bMinLat, maxLat: bMaxLat, minLng: bMinLng, maxLng: bMaxLng);
    final destPt = toMapPoint(dLat, dLng, minLat: bMinLat, maxLat: bMaxLat, minLng: bMinLng, maxLng: bMaxLng);

    // Convert real road geographic points to canvas MapPoints
    final List<MapPoint> primaryPath = [
      originPt,
      ...geoPoints.map((pt) => toMapPoint(pt.x, pt.y, minLat: bMinLat, maxLat: bMaxLat, minLng: bMinLng, maxLng: bMaxLng)),
      destPt,
    ];

    // Distance and travel time calculation from real geography (Section 9)
    final double crowFlyKm = _haversineKm(pLat, pLng, dLat, dLng);
    final double realDistKm = liveDistanceKm ??
        _lookupCorridorDistance(
          plant.name,
          project.name,
          crowFlyKm,
          origin: plant,
          destination: project,
        );

    final normRoute = (preferredRouteId ?? 'route-a').replaceAll('_', '-').toLowerCase();
    final bool isRouteB = normRoute.contains('route-b');
    final bool isRouteC = normRoute.contains('route-c');
    final String routeId = isRouteB ? 'route-b' : (isRouteC ? 'route-c' : 'route-a');

    // Corridor-aware speed and traffic calculations
    final bool isIntracity = realDistKm <= 35.0;
    final bool isExpresswayCorridor = realDistKm > 80.0;

    double baseTransitMin;
    double delayMin = 0.0;
    double trafficIdx = 0.35;
    double effectiveDistKm = realDistKm;
    String trafficLevel = 'Nominal flow';
    double ambientTemp = 36.0;
    double rainProb = 8.0;
    String primaryDriver = isIntracity
        ? 'Urban / arterial corridor transit nominal'
        : 'Transit on schedule along arterial highway';
    List<String> riskFactors = isIntracity
        ? ['Intracity arterial corridor', 'City junction traffic monitored']
        : ['Highway transit nominal', 'Hydration kinetics monitored'];

    if (liveDurationMin != null) {
      baseTransitMin = liveDurationMin;
    } else {
      // Highway speed ~65 km/h, arterial ~48 km/h, urban intracity ~34 km/h
      final avgSpeedKmh = isExpresswayCorridor ? 65.0 : (isIntracity ? 34.0 : 48.0);
      baseTransitMin = double.parse(((realDistKm / avgSpeedKmh) * 60.0).toStringAsFixed(0));
    }

    String routeName;
    List<MapPoint>? alternatePath;
    String? altRouteId;
    String? altRouteName;
    double? altEtaMin;
    double? altDistKm;
    double? botStart;
    double? botEnd;
    String? botDesc;

    final bool isNarodaToGift = (plant.id == 'plant-001' ||
            plant.name.toLowerCase().contains('naroda') ||
            plant.name.toLowerCase().contains('plant 01')) &&
        (project.id == 'project-007' || project.name.toLowerCase().contains('gift'));

    if (isRouteB) {
      routeName = 'Route B (Expressway / Airport Bypass)';
      effectiveDistKm = double.parse((realDistKm * 1.05).toStringAsFixed(1));
      baseTransitMin = isNarodaToGift ? 52.0 : double.parse((baseTransitMin * 0.88).toStringAsFixed(0));
      delayMin = 2.0;
      trafficIdx = 0.26;
      trafficLevel = 'Free flow bypass';
      primaryDriver = isNarodaToGift
          ? 'Airport Bypass avoids Nana Chiloda junction'
          : 'Expressway corridor active; minimal traffic variance';
      riskFactors = ['Bypass active (saves travel delay)', 'Safe hydration envelope'];

      // Generate alternate offset path
      alternatePath = primaryPath.map((p) {
        final offX = (p == originPt || p == destPt) ? 0.0 : 0.03;
        final offY = (p == originPt || p == destPt) ? 0.0 : -0.02;
        return MapPoint((p.x + offX).clamp(0.08, 0.92), (p.y + offY).clamp(0.08, 0.92));
      }).toList();

      altRouteId = 'route-a';
      altRouteName = 'Route A (Direct Arterial)';
      altEtaMin = baseTransitMin + 12.0;
      altDistKm = realDistKm;
    } else if (isRouteC) {
      routeName = 'Route C (Outer Perimeter Corridor)';
      effectiveDistKm = double.parse((realDistKm * 1.15).toStringAsFixed(1));
      baseTransitMin = double.parse((baseTransitMin * 1.12).toStringAsFixed(0));
      delayMin = 3.0;
      trafficIdx = 0.32;
      trafficLevel = 'Peripheral flow';
      primaryDriver = 'Peripheral routing avoiding industrial junctions';
      riskFactors = ['Long distance buffer', 'Pavement temperature monitored'];
    } else {
      routeName = isNarodaToGift ? 'Route A (Direct SP Ring Road)' : 'Route A (Direct Highway Corridor)';
      if (isNarodaToGift) {
        baseTransitMin = 58.0;
        delayMin = 14.0;
        trafficIdx = 0.65;
        trafficLevel = 'Heavy congestion at Nana Chiloda (+14m)';
        primaryDriver = 'Direct via SP Ring Road with Nana Chiloda bottleneck';
      } else {
        delayMin = isIntracity ? 6.0 : (isExpresswayCorridor ? 14.0 : 10.0);
        trafficIdx = 0.55;
        trafficLevel = 'Moderate corridor congestion (+${delayMin.toInt()}m)';
        primaryDriver = 'Direct highway corridor between ${plant.shortName} and ${project.shortName}';
      }
      riskFactors = ['Corridor transit active', 'Traffic bottleneck monitored'];

      if (delayMin >= 8.0) {
        botStart = 0.38;
        botEnd = 0.65;
        botDesc = '⚠️ Arterial Bottleneck (+${delayMin.toInt()}m)';
      }

      // Generate alternate bypass path
      alternatePath = primaryPath.map((p) {
        final offX = (p == originPt || p == destPt) ? 0.0 : -0.03;
        final offY = (p == originPt || p == destPt) ? 0.0 : 0.02;
        return MapPoint((p.x + offX).clamp(0.08, 0.92), (p.y + offY).clamp(0.08, 0.92));
      }).toList();

      altRouteId = 'route-b';
      altRouteName = 'Route B (Expressway / Bypass)';
      altEtaMin = math.max(25.0, baseTransitMin - 8.0);
      altDistKm = double.parse((realDistKm * 1.05).toStringAsFixed(1));
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

  /// Resolves intermediate real road highway waypoints between coordinates (Section 7).
  static List<math.Point<double>> _resolveHighwayCorridor(
    double lat1, double lng1, double lat2, double lng2,
  ) {
    // 1. Ahmedabad - Gandhinagar Corridor (SG Highway / Gandhinagar Road)
    if (_isNearby(lat1, lng1, 23.0225, 72.5714) && _isNearby(lat2, lng2, 23.2156, 72.6369)) {
      return [
        const math.Point(23.0784, 72.5855), // Motera
        const math.Point(23.1320, 72.6050), // Chandkheda / Koba Circle
        const math.Point(23.1800, 72.6250), // Infocity
      ];
    }
    if (_isNearby(lat1, lng1, 23.2156, 72.6369) && _isNearby(lat2, lng2, 23.0225, 72.5714)) {
      return [
        const math.Point(23.1800, 72.6250),
        const math.Point(23.1320, 72.6050),
        const math.Point(23.0784, 72.5855),
      ];
    }

    // 2. Ahmedabad - Vadodara Corridor (National Expressway 1 / NH48)
    if (_isNearby(lat1, lng1, 23.0225, 72.5714) && _isNearby(lat2, lng2, 22.3072, 73.1812)) {
      return [
        const math.Point(22.8420, 72.6840), // Bareja Toll
        const math.Point(22.6916, 72.8634), // Nadiad Expressway Exit
        const math.Point(22.5645, 72.9289), // Anand Expressway Exit
        const math.Point(22.3780, 73.1250), // Vasad Bridge
      ];
    }
    if (_isNearby(lat1, lng1, 22.3072, 73.1812) && _isNearby(lat2, lng2, 23.0225, 72.5714)) {
      return [
        const math.Point(22.3780, 73.1250),
        const math.Point(22.5645, 72.9289),
        const math.Point(22.6916, 72.8634),
        const math.Point(22.8420, 72.6840),
      ];
    }

    // 3. Vadodara - Surat Corridor (NH48 Highway Corridor)
    if (_isNearby(lat1, lng1, 22.3072, 73.1812) && _isNearby(lat2, lng2, 21.1702, 72.8311)) {
      return [
        const math.Point(22.1850, 73.1350), // Por
        const math.Point(21.8900, 73.0800), // Nabipur
        const math.Point(21.7051, 72.9959), // Bharuch (Narmada River)
        const math.Point(21.6250, 72.9980), // Ankleshwar GIDC
        const math.Point(21.3850, 72.9450), // Kosamba / Kim
      ];
    }
    if (_isNearby(lat1, lng1, 21.1702, 72.8311) && _isNearby(lat2, lng2, 22.3072, 73.1812)) {
      return [
        const math.Point(21.3850, 72.9450),
        const math.Point(21.6250, 72.9980),
        const math.Point(21.7051, 72.9959),
        const math.Point(21.8900, 73.0800),
        const math.Point(22.1850, 73.1350),
      ];
    }

    // 4. Surat - Ahmedabad Corridor (Full Golden Quadrilateral Route)
    if (_isNearby(lat1, lng1, 21.1702, 72.8311) && _isNearby(lat2, lng2, 23.0225, 72.5714)) {
      return [
        const math.Point(21.3850, 72.9450), // Kim
        const math.Point(21.7051, 72.9959), // Bharuch
        const math.Point(22.3072, 73.1812), // Vadodara Bypass
        const math.Point(22.5645, 72.9289), // Anand
        const math.Point(22.6916, 72.8634), // Nadiad
      ];
    }
    if (_isNearby(lat1, lng1, 23.0225, 72.5714) && _isNearby(lat2, lng2, 21.1702, 72.8311)) {
      return [
        const math.Point(22.6916, 72.8634),
        const math.Point(22.5645, 72.9289),
        const math.Point(22.3072, 73.1812),
        const math.Point(21.7051, 72.9959),
        const math.Point(21.3850, 72.9450),
      ];
    }

    // Generic realistic road curvature (never a straight line - Section 7)
    final midLat = (lat1 + lat2) / 2.0;
    final midLng = (lng1 + lng2) / 2.0;
    final dLat = lat2 - lat1;
    final dLng = lng2 - lng1;
    final perpLat = -dLng * 0.12;
    final perpLng = dLat * 0.12;

    return [
      math.Point(lat1 + dLat * 0.3 + perpLat * 0.6, lng1 + dLng * 0.3 + perpLng * 0.6),
      math.Point(midLat + perpLat, midLng + perpLng),
      math.Point(lat1 + dLat * 0.7 + perpLat * 0.5, lng1 + dLng * 0.7 + perpLng * 0.5),
    ];
  }

  static bool _isNearby(double lat1, double lng1, double lat2, double lng2) {
    return (lat1 - lat2).abs() < 0.12 && (lng1 - lng2).abs() < 0.12;
  }

  /// Real road distance lookup for operational corridors.
  /// If leaf localities are selected, dynamically calculates from leaf coordinates.
  static double _lookupCorridorDistance(
    String origName,
    String destName,
    double crowFlyKm, {
    LocationPoint? origin,
    LocationPoint? destination,
  }) {
    final o = origName.toLowerCase();
    final d = destName.toLowerCase();

    // Check if either is a specific locality (via AreaService, slash, or locality name)
    final originArea = AreaService.getAreaById(origin?.id ?? '') ?? AreaService.findAreaByName(origName);
    final destArea = AreaService.getAreaById(destination?.id ?? '') ?? AreaService.findAreaByName(destName);
    final bool isSpecificLocality = (originArea != null && originArea.isLocality) ||
        (destArea != null && destArea.isLocality) ||
        o.contains('/') ||
        d.contains('/') ||
        o.contains('naroda') ||
        d.contains('naroda') ||
        o.contains('bopal') ||
        d.contains('bopal') ||
        o.contains('vatva') ||
        d.contains('vatva') ||
        o.contains('chandkheda') ||
        d.contains('chandkheda') ||
        o.contains('infocity') ||
        d.contains('infocity') ||
        o.contains('sector') ||
        d.contains('sector') ||
        o.contains('hazira') ||
        d.contains('hazira') ||
        o.contains('adajan') ||
        d.contains('adajan') ||
        o.contains('makarpura') ||
        d.contains('makarpura') ||
        o.contains('alkapuri') ||
        d.contains('alkapuri');

    // Check specific known arterial corridors first:
    if ((o.contains('naroda') && d.contains('gift')) || (o.contains('gift') && d.contains('naroda'))) {
      return 18.5;
    }

    // If neither endpoint is a specific locality, use calibrated intercity highway corridors:
    if (!isSpecificLocality) {
      if ((o.contains('ahmedabad') && d.contains('gandhinagar')) || (o.contains('gandhinagar') && d.contains('ahmedabad'))) {
        return 27.5;
      }
      if ((o.contains('ahmedabad') && d.contains('vadodara')) || (o.contains('vadodara') && d.contains('ahmedabad'))) {
        return 111.4;
      }
      if ((o.contains('vadodara') && d.contains('surat')) || (o.contains('surat') && d.contains('vadodara'))) {
        return 147.4;
      }
      if ((o.contains('surat') && d.contains('ahmedabad')) || (o.contains('ahmedabad') && d.contains('surat'))) {
        return 247.1;
      }
      if ((o.contains('ahmedabad') && d.contains('sanand')) || (o.contains('sanand') && d.contains('ahmedabad'))) {
        return 26.2;
      }
      if ((o.contains('ahmedabad') && d.contains('mehsana')) || (o.contains('mehsana') && d.contains('ahmedabad'))) {
        return 74.8;
      }
      if ((o.contains('ahmedabad') && d.contains('anand')) || (o.contains('anand') && d.contains('ahmedabad'))) {
        return 76.5;
      }
      if ((o.contains('vadodara') && d.contains('bharuch')) || (o.contains('bharuch') && d.contains('vadodara'))) {
        return 72.3;
      }
      if ((o.contains('bharuch') && d.contains('surat')) || (o.contains('surat') && d.contains('bharuch'))) {
        return 75.1;
      }
    }

    // Dynamic routing using real leaf coordinates (with 1.28 urban/arterial winding factor)
    return double.parse(math.max(1.0, crowFlyKm * 1.28).toStringAsFixed(1));
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

    final bool originMatches = route.origin.id == plant.id ||
        route.origin.name.toLowerCase() == plant.name.toLowerCase() ||
        route.origin.shortName.toLowerCase() == plant.shortName.toLowerCase() ||
        route.origin.name.toLowerCase().contains(originName.toLowerCase()) ||
        originName.toLowerCase().contains(route.origin.name.toLowerCase());

    final bool destMatches = route.destination.id == project.id ||
        route.destination.name.toLowerCase() == project.name.toLowerCase() ||
        route.destination.shortName.toLowerCase() == project.shortName.toLowerCase() ||
        route.destination.name.toLowerCase().contains(destinationName.toLowerCase()) ||
        destinationName.toLowerCase().contains(route.destination.name.toLowerCase());

    return originMatches && destMatches;
  }

  /// Returns 3 deterministic route candidates for any origin and destination pair
  static List<RouteAssessment> getCandidateRoutes({
    required String originName,
    required String destinationName,
    LocationPoint? customOrigin,
    LocationPoint? customDestination,
  }) {
    final rA = getRoute(
      originName: originName,
      destinationName: destinationName,
      preferredRouteId: 'route-a',
      customOrigin: customOrigin,
      customDestination: customDestination,
    );
    final rB = getRoute(
      originName: originName,
      destinationName: destinationName,
      preferredRouteId: 'route-b',
      customOrigin: customOrigin,
      customDestination: customDestination,
    );
    final rC = getRoute(
      originName: originName,
      destinationName: destinationName,
      preferredRouteId: 'route-c',
      customOrigin: customOrigin,
      customDestination: customDestination,
    );
    return [rA, rB, rC];
  }

  /// Returns 3 RouteOptionModel objects ready for UI display
  static List<RouteOptionModel> getCandidateRouteOptions({
    required String originName,
    required String destinationName,
    LocationPoint? customOrigin,
    LocationPoint? customDestination,
  }) {
    final routes = getCandidateRoutes(
      originName: originName,
      destinationName: destinationName,
      customOrigin: customOrigin,
      customDestination: customDestination,
    );
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
