class WeatherTelemetry {
  final String locationName;
  final String timeOfDay;
  final double ambientTempC;
  final double apparentTempC;
  final double humidityPct;
  final double windSpeedKmh;
  final String windDirection;
  final double precipitationProbabilityPct;
  final String weatherCondition;
  final double solarExposureOffsetC;
  final double uvIndex;
  final int airQualityIndex;
  final String freshness;

  const WeatherTelemetry({
    required this.locationName,
    required this.timeOfDay,
    required this.ambientTempC,
    required this.apparentTempC,
    required this.humidityPct,
    required this.windSpeedKmh,
    this.windDirection = 'SW',
    required this.precipitationProbabilityPct,
    required this.weatherCondition,
    this.solarExposureOffsetC = 0.0,
    this.uvIndex = 7.5,
    this.airQualityIndex = 98,
    this.freshness = 'LIVE · Verified Sensor',
  });

  /// Effective temperature experienced during transit (ambient + solar radiation offset)
  double get effectiveTempC => double.parse((ambientTempC + solarExposureOffsetC).toStringAsFixed(1));

  bool get isHighHeat => effectiveTempC >= 38.0;
  bool get isRainRisk => precipitationProbabilityPct >= 50.0;

  Map<String, dynamic> toJson() => {
        'location_name': locationName,
        'time_of_day': timeOfDay,
        'ambient_temp_c': ambientTempC,
        'apparent_temp_c': apparentTempC,
        'humidity_pct': humidityPct,
        'wind_speed_kmh': windSpeedKmh,
        'wind_direction': windDirection,
        'precipitation_probability_pct': precipitationProbabilityPct,
        'weather_condition': weatherCondition,
        'solar_exposure_offset_c': solarExposureOffsetC,
        'uv_index': uvIndex,
        'air_quality_index': airQualityIndex,
        'freshness': freshness,
      };

  factory WeatherTelemetry.fromJson(Map<String, dynamic> json) {
    return WeatherTelemetry(
      locationName: json['location_name'] as String? ?? 'Ahmedabad Central Corridor',
      timeOfDay: json['time_of_day'] as String? ?? '14:00',
      ambientTempC: (json['ambient_temp_c'] as num?)?.toDouble() ?? 35.0,
      apparentTempC: (json['apparent_temp_c'] as num?)?.toDouble() ?? 37.0,
      humidityPct: (json['humidity_pct'] as num?)?.toDouble() ?? 50.0,
      windSpeedKmh: (json['wind_speed_kmh'] as num?)?.toDouble() ?? 14.0,
      windDirection: json['wind_direction'] as String? ?? 'SW',
      precipitationProbabilityPct: (json['precipitation_probability_pct'] as num?)?.toDouble() ?? 15.0,
      weatherCondition: json['weather_condition'] as String? ?? 'Partly Cloudy',
      solarExposureOffsetC: (json['solar_exposure_offset_c'] as num?)?.toDouble() ?? 0.0,
      uvIndex: (json['uv_index'] as num?)?.toDouble() ?? 7.5,
      airQualityIndex: (json['air_quality_index'] as num?)?.toInt() ?? 98,
      freshness: json['freshness'] as String? ?? 'LIVE · Verified Sensor',
    );
  }
}
