import 'dart:convert';
import 'package:http/http.dart' as http;

/// Canonical location data representation for weather intelligence
class LocationData {
  final String cityName;
  final String regionName;
  final double latitude;
  final double longitude;
  final bool isDetected;

  const LocationData({
    required this.cityName,
    required this.regionName,
    required this.latitude,
    required this.longitude,
    this.isDetected = false,
  });

  Map<String, dynamic> toJson() => {
        'city_name': cityName,
        'region_name': regionName,
        'latitude': latitude,
        'longitude': longitude,
        'is_detected': isDetected,
      };

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      cityName: json['city_name'] as String? ?? 'Ahmedabad',
      regionName: json['region_name'] as String? ?? 'Gujarat, India',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 23.0225,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 72.5714,
      isDetected: json['is_detected'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationData &&
          runtimeType == other.runtimeType &&
          cityName == other.cityName &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => cityName.hashCode ^ latitude.hashCode ^ longitude.hashCode;
}

/// Service handling location resolution, geolocation detection, and preset catalogs
/// (PRD Section 3 & Hero Prompt Section 3, 15)
class LocationService {
  final http.Client _client;

  LocationService({http.Client? client}) : _client = client ?? http.Client();

  static const LocationData defaultLocation = LocationData(
    cityName: 'Ahmedabad',
    regionName: 'Gujarat, India',
    latitude: 23.0225,
    longitude: 72.5714,
  );

  static const List<LocationData> supportedPresets = [
    LocationData(
      cityName: 'Ahmedabad',
      regionName: 'Gujarat, India',
      latitude: 23.0225,
      longitude: 72.5714,
    ),
    LocationData(
      cityName: 'Mumbai',
      regionName: 'Maharashtra, India',
      latitude: 19.0760,
      longitude: 72.8777,
    ),
    LocationData(
      cityName: 'Delhi',
      regionName: 'Delhi, India',
      latitude: 28.6139,
      longitude: 77.2090,
    ),
    LocationData(
      cityName: 'Bengaluru',
      regionName: 'Karnataka, India',
      latitude: 12.9716,
      longitude: 77.5946,
    ),
    LocationData(
      cityName: 'Pune',
      regionName: 'Maharashtra, India',
      latitude: 18.5204,
      longitude: 73.8567,
    ),
    LocationData(
      cityName: 'Sydney',
      regionName: 'New South Wales, Australia',
      latitude: -33.8688,
      longitude: 151.2093,
    ),
  ];

  /// Detects the user's location via IP geolocation lookup
  /// Falls back gracefully to defaultLocation on error or network failure
  Future<LocationData> detectLocation() async {
    try {
      final response = await _client
          .get(Uri.parse('http://ip-api.com/json/'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          final city = data['city'] as String? ?? 'Ahmedabad';
          final region = data['regionName'] as String? ?? '';
          final country = data['country'] as String? ?? 'India';
          final lat = (data['lat'] as num?)?.toDouble() ?? 23.0225;
          final lon = (data['lon'] as num?)?.toDouble() ?? 72.5714;

          final regionStr = region.isNotEmpty ? '$region, $country' : country;

          return LocationData(
            cityName: city,
            regionName: regionStr,
            latitude: lat,
            longitude: lon,
            isDetected: true,
          );
        }
      }
    } catch (_) {}

    return defaultLocation;
  }

  /// Resolves any city query to a known preset or default
  static LocationData resolvePreset(String query) {
    final q = query.toLowerCase().trim();
    for (final loc in supportedPresets) {
      if (loc.cityName.toLowerCase() == q || q.contains(loc.cityName.toLowerCase())) {
        return loc;
      }
    }
    return defaultLocation;
  }
}
