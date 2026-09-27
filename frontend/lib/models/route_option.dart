class WaypointModel {
  final double lat;
  final double lng;
  final String? name;

  const WaypointModel({required this.lat, required this.lng, this.name});

  factory WaypointModel.fromJson(Map<String, dynamic> json) {
    return WaypointModel(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      name: json['name'] as String?,
    );
  }
}

class RouteOptionModel {
  final String routeId;
  final String routeName;
  final bool isRecommended;
  final double etaMinutes;
  final double distanceKm;
  final double deliveryRisk;
  final double heatRisk;
  final double travelRisk;
  final String trafficLevel;
  final String weatherSummary;
  final String tradeOffExplanation;
  final List<WaypointModel> waypoints;

  const RouteOptionModel({
    required this.routeId,
    required this.routeName,
    required this.isRecommended,
    required this.etaMinutes,
    required this.distanceKm,
    required this.deliveryRisk,
    required this.heatRisk,
    required this.travelRisk,
    required this.trafficLevel,
    required this.weatherSummary,
    required this.tradeOffExplanation,
    required this.waypoints,
  });

  factory RouteOptionModel.fromJson(Map<String, dynamic> json) {
    return RouteOptionModel(
      routeId: json['route_id'] as String,
      routeName: json['route_name'] as String,
      isRecommended: json['is_recommended'] as bool? ?? false,
      etaMinutes: (json['eta_minutes'] as num).toDouble(),
      distanceKm: (json['distance_km'] as num).toDouble(),
      deliveryRisk: (json['delivery_risk'] as num).toDouble(),
      heatRisk: (json['heat_risk'] as num).toDouble(),
      travelRisk: (json['travel_risk'] as num).toDouble(),
      trafficLevel: json['traffic_level'] as String? ?? 'Moderate',
      weatherSummary: json['weather_summary'] as String? ?? 'Clear',
      tradeOffExplanation: json['trade_off_explanation'] as String? ?? '',
      waypoints: (json['waypoints'] as List<dynamic>?)
              ?.map((e) => WaypointModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
