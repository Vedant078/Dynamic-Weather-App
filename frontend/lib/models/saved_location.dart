import '../services/route_service.dart';

/// Represents a persistent geographic location (Plant, Project Site, or Destination)
/// Owned by an authenticated user / organization.
class SavedLocation {
  final String id;
  final String name;
  final String type; // 'PLANT', 'PROJECT_SITE', 'DESTINATION'
  final String? address;
  final double latitude;
  final double longitude;
  final DateTime? createdAt;

  const SavedLocation({
    required this.id,
    required this.name,
    required this.type,
    this.address,
    required this.latitude,
    required this.longitude,
    this.createdAt,
  });

  bool get isPlant => type.toUpperCase() == 'PLANT';
  bool get isProjectSite => type.toUpperCase() == 'PROJECT_SITE';
  bool get isDestination => type.toUpperCase() == 'DESTINATION';

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: (json['type'] as String? ?? 'PLANT').toUpperCase(),
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 23.0650,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 72.6500,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      if (address != null) 'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  LocationPoint toLocationPoint() {
    return LocationPoint(
      id: id,
      name: name,
      shortName: name.length > 20 ? '${name.substring(0, 18)}...' : name,
      latitude: latitude,
      longitude: longitude,
      isPlant: isPlant,
    );
  }
}
