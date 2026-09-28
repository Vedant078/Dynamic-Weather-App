/// Conceptual geographic area model for generalized RMC routing (Section 1, 4, 6)
/// Supports STATE -> CITY -> AREA / LOCALITY hierarchy with real coordinates.
class Area {
  final String id;
  final String name;
  final String? displayName;
  final String type; // 'CITY', 'LOCALITY', 'INDUSTRIAL_AREA', 'BUSINESS_DISTRICT', 'PROJECT_AREA', 'PLANT', 'SITE'
  final String city;
  final String state;
  final String country;
  final String? parentLocationId;
  final double latitude;
  final double longitude;

  const Area({
    required this.id,
    required this.name,
    this.displayName,
    this.type = 'LOCALITY',
    required this.city,
    required this.state,
    required this.country,
    this.parentLocationId,
    required this.latitude,
    required this.longitude,
  });

  bool get isCity => type.toUpperCase() == 'CITY' || parentLocationId == null || parentLocationId!.isEmpty;
  bool get isLocality => !isCity;

  String get qualifiedName {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (isCity) return name;
    return '$city / $name';
  }

  String get typeLabel {
    switch (type.toUpperCase()) {
      case 'CITY':
        return 'City';
      case 'INDUSTRIAL_AREA':
        return 'Industrial Area';
      case 'BUSINESS_DISTRICT':
        return 'Business District';
      case 'PROJECT_AREA':
        return 'Project Site';
      case 'PLANT':
        return 'Plant';
      case 'SITE':
        return 'Site';
      case 'LOCALITY':
      default:
        return 'Locality';
    }
  }

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['display_name'] as String?,
      type: json['type'] as String? ?? 'LOCALITY',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? 'Gujarat',
      country: json['country'] as String? ?? 'India',
      parentLocationId: json['parentLocationId'] as String? ?? json['parent_location_id'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'type': type,
      'city': city,
      'state': state,
      'country': country,
      'parentLocationId': parentLocationId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Area &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$qualifiedName ($state)';
}
