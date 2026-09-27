import 'package:intl/intl.dart';

/// Single day forecast entry for the 5-day weather row
class ForecastDay {
  final String dayName; // 'Mon', 'Tue', etc.
  final double maxTempC;
  final double minTempC;
  final String condition;
  final int weatherCode;

  const ForecastDay({
    required this.dayName,
    required this.maxTempC,
    required this.minTempC,
    required this.condition,
    this.weatherCode = 0,
  });

  Map<String, dynamic> toJson() => {
        'day_name': dayName,
        'max_temp_c': maxTempC,
        'min_temp_c': minTempC,
        'condition': condition,
        'weather_code': weatherCode,
      };

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    return ForecastDay(
      dayName: json['day_name'] as String? ?? 'Day',
      maxTempC: (json['max_temp_c'] as num?)?.toDouble() ?? 28.0,
      minTempC: (json['min_temp_c'] as num?)?.toDouble() ?? 20.0,
      condition: json['condition'] as String? ?? 'Partly Cloudy',
      weatherCode: (json['weather_code'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Canonical Current Weather Model for MAUSAM Hero & Environmental Intelligence
/// (Section 3, 4, 15)
class CurrentWeather {
  final String locationName;
  final String regionName;
  final double latitude;
  final double longitude;
  final double temperature;
  final double feelsLike;
  final String condition;
  final int weatherCode;
  final double humidity;
  final double windSpeedKmh;
  final double precipitationProbability;
  final int? aqi;
  final bool isDay;
  final String? sunrise;
  final String? sunset;
  final DateTime timestamp;
  final String source;
  final List<ForecastDay> forecastDays;

  const CurrentWeather({
    required this.locationName,
    required this.regionName,
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    this.weatherCode = 0,
    required this.humidity,
    required this.windSpeedKmh,
    required this.precipitationProbability,
    this.aqi,
    this.isDay = true,
    this.sunrise,
    this.sunset,
    required this.timestamp,
    required this.source,
    required this.forecastDays,
  });

  /// Formatted date and time matching the reference template: "Monday | Dec 20 | 12:45"
  String get formattedDateTime {
    final dayStr = DateFormat('EEEE').format(timestamp);
    final dateStr = DateFormat('MMM d').format(timestamp);
    final timeStr = DateFormat('HH:mm').format(timestamp);
    return '$dayStr | $dateStr | $timeStr';
  }

  /// Parses Open-Meteo current & daily forecast response
  factory CurrentWeather.fromOpenMeteo({
    required Map<String, dynamic> json,
    required String locationName,
    required String regionName,
    required double lat,
    required double lng,
  }) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final daily = json['daily'] as Map<String, dynamic>? ?? {};

    final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 28.0;
    final apparent = (current['apparent_temperature'] as num?)?.toDouble() ?? temp;
    final humidity = (current['relative_humidity_2m'] as num?)?.toDouble() ?? 50.0;
    final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 12.0;
    final precip = (current['precipitation'] as num?)?.toDouble() ?? 0.0;
    final code = (current['weather_code'] as num?)?.toInt() ?? 0;

    final isDayRaw = current['is_day'];
    final bool isDay;
    if (isDayRaw != null) {
      isDay = (isDayRaw as num).toInt() == 1;
    } else {
      final hour = DateTime.now().hour;
      isDay = hour >= 6 && hour < 19;
    }

    final sunriseList = daily['sunrise'] as List<dynamic>?;
    final sunsetList = daily['sunset'] as List<dynamic>?;
    final String? sunriseStr = (sunriseList != null && sunriseList.isNotEmpty) ? sunriseList[0].toString() : null;
    final String? sunsetStr = (sunsetList != null && sunsetList.isNotEmpty) ? sunsetList[0].toString() : null;

    final condition = _wmoCodeToCondition(code, isDay: isDay);

    final List<ForecastDay> days = [];
    final times = daily['time'] as List<dynamic>? ?? [];
    final maxTemps = daily['temperature_2m_max'] as List<dynamic>? ?? [];
    final minTemps = daily['temperature_2m_min'] as List<dynamic>? ?? [];
    final codes = daily['weather_code'] as List<dynamic>? ?? [];

    for (int i = 0; i < times.length && i < 5; i++) {
      DateTime? d;
      try {
        d = DateTime.parse(times[i].toString());
      } catch (_) {}
      final dayName = d != null ? DateFormat('EEE').format(d) : 'D${i + 1}';
      final maxT = i < maxTemps.length ? (maxTemps[i] as num).toDouble() : temp;
      final minT = i < minTemps.length ? (minTemps[i] as num).toDouble() : temp - 6;
      final dayCode = i < codes.length ? (codes[i] as num).toInt() : 0;

      days.add(ForecastDay(
        dayName: dayName,
        maxTempC: maxT,
        minTempC: minT,
        condition: _wmoCodeToCondition(dayCode, isDay: true),
        weatherCode: dayCode,
      ));
    }

    if (days.isEmpty) {
      days.addAll(_defaultForecastDays(temp));
    }

    return CurrentWeather(
      locationName: locationName,
      regionName: regionName,
      latitude: lat,
      longitude: lng,
      temperature: temp,
      feelsLike: apparent,
      condition: condition,
      weatherCode: code,
      humidity: humidity,
      windSpeedKmh: wind,
      precipitationProbability: precip > 0 ? (precip * 20.0).clamp(10.0, 95.0) : 10.0,
      aqi: 55,
      isDay: isDay,
      sunrise: sunriseStr,
      sunset: sunsetStr,
      timestamp: DateTime.now(),
      source: 'LIVE · Meteorological API',
      forecastDays: days,
    );
  }

  /// Canonical deterministic current weather fallback (Section 4)
  factory CurrentWeather.deterministic({
    required String locationName,
    required String regionName,
    required double latitude,
    required double longitude,
  }) {
    final norm = locationName.toLowerCase().trim();
    double temp = 28.0;
    double apparent = 30.0;
    double humidity = 55.0;
    double wind = 14.0;
    double precip = 12.0;
    int aqi = 62;
    String condition = 'Partly Cloudy';
    int code = 2;

    if (norm.contains('mumbai')) {
      temp = 31.0;
      apparent = 35.0;
      humidity = 78.0;
      wind = 18.0;
      precip = 25.0;
      aqi = 68;
      condition = 'Humid / Coastal Breeze';
      code = 1;
    } else if (norm.contains('delhi')) {
      temp = 33.5;
      apparent = 36.0;
      humidity = 42.0;
      wind = 11.0;
      precip = 5.0;
      aqi = 142;
      condition = 'Hazy Sunshine';
      code = 2;
    } else if (norm.contains('bengaluru') || norm.contains('bangalore')) {
      temp = 25.5;
      apparent = 26.0;
      humidity = 60.0;
      wind = 15.0;
      precip = 15.0;
      aqi = 45;
      condition = 'Mild / Pleasant';
      code = 1;
    } else if (norm.contains('pune')) {
      temp = 27.2;
      apparent = 28.5;
      humidity = 58.0;
      wind = 13.0;
      precip = 10.0;
      aqi = 52;
      condition = 'Partly Cloudy';
      code = 2;
    } else if (norm.contains('sydney')) {
      temp = 26.0;
      apparent = 27.0;
      humidity = 50.0;
      wind = 16.0;
      precip = 5.0;
      aqi = 28;
      condition = 'Sunny';
      code = 0;
    } else {
      // Default: Ahmedabad
      temp = 32.4;
      apparent = 34.8;
      humidity = 52.0;
      wind = 14.0;
      precip = 15.0;
      aqi = 78;
      condition = 'Sunny';
      code = 0;
    }

    final days = _defaultForecastDays(temp);
    final hour = DateTime.now().hour;
    final isDay = hour >= 6 && hour < 19;
    if (!isDay && condition == 'Sunny') {
      condition = 'Clear Night';
    }

    return CurrentWeather(
      locationName: locationName,
      regionName: regionName,
      latitude: latitude,
      longitude: longitude,
      temperature: temp,
      feelsLike: apparent,
      condition: condition,
      weatherCode: code,
      humidity: humidity,
      windSpeedKmh: wind,
      precipitationProbability: precip,
      aqi: aqi,
      isDay: isDay,
      timestamp: DateTime.now(),
      source: 'DETERMINISTIC · Canonical Fallback',
      forecastDays: days,
    );
  }

  static List<ForecastDay> _defaultForecastDays(double baseTemp) {
    final now = DateTime.now();
    final offsets = [0.0, -1.0, -4.0, -5.0, -8.0];
    final conditions = ['Cloudy', 'Sunny', 'Partly Cloudy', 'Breezy', 'Light Rain'];
    final codes = [3, 0, 2, 1, 61];

    final List<ForecastDay> list = [];
    for (int i = 0; i < 5; i++) {
      final dayDate = now.add(Duration(days: i));
      final dayName = DateFormat('EEE').format(dayDate);
      final maxT = double.parse((baseTemp + offsets[i]).toStringAsFixed(0));
      final minT = maxT - 6;

      list.add(ForecastDay(
        dayName: dayName,
        maxTempC: maxT,
        minTempC: minT,
        condition: conditions[i],
        weatherCode: codes[i],
      ));
    }
    return list;
  }

  static String _wmoCodeToCondition(int code, {bool isDay = true}) {
    switch (code) {
      case 0:
        return isDay ? 'Sunny' : 'Clear Night';
      case 1:
        return isDay ? 'Mainly Clear' : 'Clear Sky';
      case 2:
        return 'Partly Cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 80:
      case 81:
      case 82:
        return 'Rain Showers';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Clear';
    }
  }
}
