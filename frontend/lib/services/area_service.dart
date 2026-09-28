import '../models/area.dart';

/// Centralized Area & Location Master Repository for MAUSAM (Section 1, 4, 6)
/// Implements full location hierarchy: STATE -> CITY -> AREA / LOCALITY -> EXACT COORDINATES.
/// Provides curated, real geographic coordinates for both intercity and intracity operations.
class AreaService {
  // ---------------------------------------------------------------------------
  // 1. CITIES (PARENT LEVEL)
  // ---------------------------------------------------------------------------
  static const List<Area> _cities = [
    Area(
      id: 'area-ahmedabad',
      name: 'Ahmedabad',
      displayName: 'Ahmedabad',
      type: 'CITY',
      city: 'Ahmedabad',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: null,
      latitude: 23.0225,
      longitude: 72.5714,
    ),
    Area(
      id: 'area-anand',
      name: 'Anand',
      displayName: 'Anand',
      type: 'CITY',
      city: 'Anand',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: null,
      latitude: 22.5645,
      longitude: 72.9289,
    ),
    Area(
      id: 'area-bharuch',
      name: 'Bharuch',
      displayName: 'Bharuch',
      type: 'CITY',
      city: 'Bharuch',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: null,
      latitude: 21.7051,
      longitude: 72.9959,
    ),
    Area(
      id: 'area-gandhinagar',
      name: 'Gandhinagar',
      displayName: 'Gandhinagar',
      type: 'CITY',
      city: 'Gandhinagar',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: null,
      latitude: 23.2156,
      longitude: 72.6369,
    ),
    Area(
      id: 'area-mehsana',
      name: 'Mehsana',
      displayName: 'Mehsana',
      type: 'CITY',
      city: 'Mehsana',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: null,
      latitude: 23.5880,
      longitude: 72.3693,
    ),
    Area(
      id: 'area-nadiad',
      name: 'Nadiad',
      displayName: 'Nadiad',
      type: 'CITY',
      city: 'Nadiad',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: null,
      latitude: 22.6916,
      longitude: 72.8634,
    ),
    Area(
      id: 'area-sanand',
      name: 'Sanand',
      displayName: 'Sanand',
      type: 'CITY',
      city: 'Sanand',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: null,
      latitude: 22.9868,
      longitude: 72.3814,
    ),
    Area(
      id: 'area-surat',
      name: 'Surat',
      displayName: 'Surat',
      type: 'CITY',
      city: 'Surat',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: null,
      latitude: 21.1702,
      longitude: 72.8311,
    ),
    Area(
      id: 'area-vadodara',
      name: 'Vadodara',
      displayName: 'Vadodara',
      type: 'CITY',
      city: 'Vadodara',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: null,
      latitude: 22.3072,
      longitude: 73.1812,
    ),
  ];

  // ---------------------------------------------------------------------------
  // 2. WITHIN-CITY LOCALITIES (LEAF LEVEL WITH REAL VERIFIED COORDINATES)
  // ---------------------------------------------------------------------------
  static const List<Area> _localities = [
    // --- AHMEDABAD LOCALITIES ---
    Area(
      id: 'area-ahm-city-centre',
      name: 'Ahmedabad — City Centre',
      displayName: 'Ahmedabad / City Centre',
      type: 'LOCALITY',
      city: 'Ahmedabad',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-ahmedabad',
      latitude: 23.0225,
      longitude: 72.5714,
    ),
    Area(
      id: 'area-ahm-bopal',
      name: 'Bopal',
      displayName: 'Ahmedabad / Bopal',
      type: 'LOCALITY',
      city: 'Ahmedabad',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-ahmedabad',
      latitude: 23.0336,
      longitude: 72.4634,
    ),
    Area(
      id: 'area-ahm-chandkheda',
      name: 'Chandkheda',
      displayName: 'Ahmedabad / Chandkheda',
      type: 'LOCALITY',
      city: 'Ahmedabad',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-ahmedabad',
      latitude: 23.1118,
      longitude: 72.5841,
    ),
    Area(
      id: 'area-ahm-maninagar',
      name: 'Maninagar',
      displayName: 'Ahmedabad / Maninagar',
      type: 'LOCALITY',
      city: 'Ahmedabad',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-ahmedabad',
      latitude: 22.9983,
      longitude: 72.6033,
    ),
    Area(
      id: 'area-ahm-naroda',
      name: 'Naroda',
      displayName: 'Ahmedabad / Naroda',
      type: 'INDUSTRIAL_AREA',
      city: 'Ahmedabad',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-ahmedabad',
      latitude: 23.0805,
      longitude: 72.6500,
    ),
    Area(
      id: 'area-ahm-sanand-road',
      name: 'Sanand Road',
      displayName: 'Ahmedabad / Sanand Road',
      type: 'INDUSTRIAL_AREA',
      city: 'Ahmedabad',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-ahmedabad',
      latitude: 22.9924,
      longitude: 72.3814,
    ),
    Area(
      id: 'area-ahm-sarkhej',
      name: 'Sarkhej',
      displayName: 'Ahmedabad / Sarkhej',
      type: 'LOCALITY',
      city: 'Ahmedabad',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-ahmedabad',
      latitude: 22.9818,
      longitude: 72.5028,
    ),
    Area(
      id: 'area-ahm-satellite',
      name: 'Satellite',
      displayName: 'Ahmedabad / Satellite',
      type: 'BUSINESS_DISTRICT',
      city: 'Ahmedabad',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-ahmedabad',
      latitude: 23.0276,
      longitude: 72.5173,
    ),
    Area(
      id: 'area-ahm-sg-highway',
      name: 'SG Highway',
      displayName: 'Ahmedabad / SG Highway',
      type: 'BUSINESS_DISTRICT',
      city: 'Ahmedabad',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-ahmedabad',
      latitude: 23.0525,
      longitude: 72.5085,
    ),
    Area(
      id: 'area-ahm-thaltej',
      name: 'Thaltej',
      displayName: 'Ahmedabad / Thaltej',
      type: 'PROJECT_AREA',
      city: 'Ahmedabad',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-ahmedabad',
      latitude: 23.0500,
      longitude: 72.5100,
    ),
    Area(
      id: 'area-ahm-vatva',
      name: 'Vatva',
      displayName: 'Ahmedabad / Vatva',
      type: 'INDUSTRIAL_AREA',
      city: 'Ahmedabad',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-ahmedabad',
      latitude: 22.9555,
      longitude: 72.6348,
    ),

    // --- GANDHINAGAR LOCALITIES ---
    Area(
      id: 'area-gn-city-centre',
      name: 'Gandhinagar — City Centre',
      displayName: 'Gandhinagar / City Centre',
      type: 'LOCALITY',
      city: 'Gandhinagar',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-gandhinagar',
      latitude: 23.2156,
      longitude: 72.6369,
    ),
    Area(
      id: 'area-gn-gift-city',
      name: 'GIFT City',
      displayName: 'Gandhinagar / GIFT City',
      type: 'PROJECT_AREA',
      city: 'Gandhinagar',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-gandhinagar',
      latitude: 23.1600,
      longitude: 72.6850,
    ),
    Area(
      id: 'area-gn-infocity',
      name: 'Infocity',
      displayName: 'Gandhinagar / Infocity',
      type: 'BUSINESS_DISTRICT',
      city: 'Gandhinagar',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-gandhinagar',
      latitude: 23.1920,
      longitude: 72.6288,
    ),
    Area(
      id: 'area-gn-koba',
      name: 'Koba Circle',
      displayName: 'Gandhinagar / Koba Circle',
      type: 'LOCALITY',
      city: 'Gandhinagar',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-gandhinagar',
      latitude: 23.1550,
      longitude: 72.6330,
    ),
    Area(
      id: 'area-gn-sec-11',
      name: 'Sector 11',
      displayName: 'Gandhinagar / Sector 11',
      type: 'LOCALITY',
      city: 'Gandhinagar',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-gandhinagar',
      latitude: 23.2235,
      longitude: 72.6502,
    ),
    Area(
      id: 'area-gn-sec-21',
      name: 'Sector 21',
      displayName: 'Gandhinagar / Sector 21',
      type: 'LOCALITY',
      city: 'Gandhinagar',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-gandhinagar',
      latitude: 23.2386,
      longitude: 72.6521,
    ),
    Area(
      id: 'area-gn-sec-22',
      name: 'Sector 22',
      displayName: 'Gandhinagar / Sector 22',
      type: 'LOCALITY',
      city: 'Gandhinagar',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-gandhinagar',
      latitude: 23.2435,
      longitude: 72.6465,
    ),

    // --- VADODARA LOCALITIES ---
    Area(
      id: 'area-bdq-city-centre',
      name: 'Vadodara — City Centre',
      displayName: 'Vadodara / City Centre',
      type: 'LOCALITY',
      city: 'Vadodara',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-vadodara',
      latitude: 22.3072,
      longitude: 73.1812,
    ),
    Area(
      id: 'area-bdq-alkapuri',
      name: 'Alkapuri',
      displayName: 'Vadodara / Alkapuri',
      type: 'BUSINESS_DISTRICT',
      city: 'Vadodara',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-vadodara',
      latitude: 22.3129,
      longitude: 73.1704,
    ),
    Area(
      id: 'area-bdq-gorwa',
      name: 'Gorwa',
      displayName: 'Vadodara / Gorwa',
      type: 'INDUSTRIAL_AREA',
      city: 'Vadodara',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-vadodara',
      latitude: 22.3361,
      longitude: 73.1534,
    ),
    Area(
      id: 'area-bdq-gotri',
      name: 'Gotri',
      displayName: 'Vadodara / Gotri',
      type: 'PROJECT_AREA',
      city: 'Vadodara',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-vadodara',
      latitude: 22.3168,
      longitude: 73.1362,
    ),
    Area(
      id: 'area-bdq-makarpura',
      name: 'Makarpura',
      displayName: 'Vadodara / Makarpura',
      type: 'INDUSTRIAL_AREA',
      city: 'Vadodara',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-vadodara',
      latitude: 22.2533,
      longitude: 73.1950,
    ),
    Area(
      id: 'area-bdq-manjalpur',
      name: 'Manjalpur',
      displayName: 'Vadodara / Manjalpur',
      type: 'LOCALITY',
      city: 'Vadodara',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-vadodara',
      latitude: 22.2715,
      longitude: 73.1873,
    ),

    // --- SURAT LOCALITIES ---
    Area(
      id: 'area-stv-city-centre',
      name: 'Surat — City Centre',
      displayName: 'Surat / City Centre',
      type: 'LOCALITY',
      city: 'Surat',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-surat',
      latitude: 21.1702,
      longitude: 72.8311,
    ),
    Area(
      id: 'area-stv-adajan',
      name: 'Adajan',
      displayName: 'Surat / Adajan',
      type: 'PROJECT_AREA',
      city: 'Surat',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-surat',
      latitude: 21.1960,
      longitude: 72.7950,
    ),
    Area(
      id: 'area-stv-hazira',
      name: 'Hazira',
      displayName: 'Surat / Hazira',
      type: 'INDUSTRIAL_AREA',
      city: 'Surat',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-surat',
      latitude: 21.1098,
      longitude: 72.6522,
    ),
    Area(
      id: 'area-stv-katargam',
      name: 'Katargam',
      displayName: 'Surat / Katargam',
      type: 'LOCALITY',
      city: 'Surat',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-surat',
      latitude: 21.2268,
      longitude: 72.8273,
    ),
    Area(
      id: 'area-stv-pandesara',
      name: 'Pandesara',
      displayName: 'Surat / Pandesara',
      type: 'INDUSTRIAL_AREA',
      city: 'Surat',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-surat',
      latitude: 21.1442,
      longitude: 72.8354,
    ),
    Area(
      id: 'area-stv-varachha',
      name: 'Varachha',
      displayName: 'Surat / Varachha',
      type: 'LOCALITY',
      city: 'Surat',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-surat',
      latitude: 21.2155,
      longitude: 72.8682,
    ),
    Area(
      id: 'area-stv-vesu',
      name: 'Vesu',
      displayName: 'Surat / Vesu',
      type: 'BUSINESS_DISTRICT',
      city: 'Surat',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-surat',
      latitude: 21.1408,
      longitude: 72.7758,
    ),

    // --- ANAND LOCALITIES ---
    Area(
      id: 'area-and-city-centre',
      name: 'Anand — City Centre',
      displayName: 'Anand / City Centre',
      type: 'LOCALITY',
      city: 'Anand',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-anand',
      latitude: 22.5645,
      longitude: 72.9289,
    ),
    Area(
      id: 'area-and-vvn',
      name: 'Vallabh Vidyanagar',
      displayName: 'Anand / Vallabh Vidyanagar',
      type: 'LOCALITY',
      city: 'Anand',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-anand',
      latitude: 22.5482,
      longitude: 72.9248,
    ),
    Area(
      id: 'area-and-gidc',
      name: 'Vitthal Udyognagar GIDC',
      displayName: 'Anand / Vitthal Udyognagar GIDC',
      type: 'INDUSTRIAL_AREA',
      city: 'Anand',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-anand',
      latitude: 22.5320,
      longitude: 72.9050,
    ),

    // --- BHARUCH LOCALITIES ---
    Area(
      id: 'area-bh-city-centre',
      name: 'Bharuch — City Centre',
      displayName: 'Bharuch / City Centre',
      type: 'LOCALITY',
      city: 'Bharuch',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-bharuch',
      latitude: 21.7051,
      longitude: 72.9959,
    ),
    Area(
      id: 'area-bh-ankleshwar',
      name: 'Ankleshwar GIDC',
      displayName: 'Bharuch / Ankleshwar GIDC',
      type: 'INDUSTRIAL_AREA',
      city: 'Bharuch',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-bharuch',
      latitude: 21.6264,
      longitude: 73.0031,
    ),
    Area(
      id: 'area-bh-dahej',
      name: 'Dahej Port & Industrial Hub',
      displayName: 'Bharuch / Dahej Port & Industrial Hub',
      type: 'INDUSTRIAL_AREA',
      city: 'Bharuch',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-bharuch',
      latitude: 21.7088,
      longitude: 72.5855,
    ),

    // --- MEHSANA LOCALITIES ---
    Area(
      id: 'area-mh-city-centre',
      name: 'Mehsana — City Centre',
      displayName: 'Mehsana / City Centre',
      type: 'LOCALITY',
      city: 'Mehsana',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-mehsana',
      latitude: 23.5880,
      longitude: 72.3693,
    ),
    Area(
      id: 'area-mh-gidc',
      name: 'Mehsana GIDC',
      displayName: 'Mehsana / Mehsana GIDC',
      type: 'INDUSTRIAL_AREA',
      city: 'Mehsana',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-mehsana',
      latitude: 23.6045,
      longitude: 72.3920,
    ),

    // --- NADIAD LOCALITIES ---
    Area(
      id: 'area-nd-city-centre',
      name: 'Nadiad — City Centre',
      displayName: 'Nadiad / City Centre',
      type: 'LOCALITY',
      city: 'Nadiad',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-nadiad',
      latitude: 22.6916,
      longitude: 72.8634,
    ),
    Area(
      id: 'area-nd-gidc',
      name: 'Nadiad Industrial Area',
      displayName: 'Nadiad / Nadiad Industrial Area',
      type: 'INDUSTRIAL_AREA',
      city: 'Nadiad',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-nadiad',
      latitude: 22.7050,
      longitude: 72.8420,
    ),

    // --- SANAND LOCALITIES ---
    Area(
      id: 'area-sn-town-centre',
      name: 'Sanand — Town Centre',
      displayName: 'Sanand / Town Centre',
      type: 'LOCALITY',
      city: 'Sanand',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-sanand',
      latitude: 22.9868,
      longitude: 72.3814,
    ),
    Area(
      id: 'area-sn-gidc',
      name: 'Sanand GIDC Mega Estate',
      displayName: 'Sanand / Sanand GIDC Mega Estate',
      type: 'INDUSTRIAL_AREA',
      city: 'Sanand',
      state: 'Gujarat',
      country: 'India',
      parentLocationId: 'area-sanand',
      latitude: 22.9680,
      longitude: 72.3420,
    ),
  ];

  // ---------------------------------------------------------------------------
  // PUBLIC ACCESSORS & SORTING
  // ---------------------------------------------------------------------------

  /// Returns all primary cities strictly sorted in ALPHABETICAL ORDER (Section 16).
  static List<Area> getCities() {
    final list = List<Area>.from(_cities);
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Returns all localities within a given city, strictly sorted in ALPHABETICAL ORDER (Section 16).
  static List<Area> getLocalitiesForCity(String cityIdOrName) {
    final query = cityIdOrName.trim().toLowerCase();
    final list = _localities.where((loc) {
      final matchesParentId = loc.parentLocationId?.toLowerCase() == query;
      final matchesCityName = loc.city.toLowerCase() == query;
      return matchesParentId || matchesCityName;
    }).toList();

    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Returns all available areas (both cities and within-city localities), sorted alphabetically.
  static List<Area> getAvailableAreas() {
    final all = [..._cities, ..._localities];
    all.sort((a, b) {
      final nameComp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (nameComp != 0) return nameComp;
      return a.city.toLowerCase().compareTo(b.city.toLowerCase());
    });
    return all;
  }

  /// Search areas across both cities and within-city localities (Section 3).
  /// Typing "Naroda" returns:
  ///   Naroda
  ///   Ahmedabad, Gujarat
  /// Typing "Infocity" returns:
  ///   Infocity
  ///   Gandhinagar, Gujarat
  /// Typing "Gan" matches Gandhinagar as well as any locality in Gandhinagar.
  static List<Area> searchAreas(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return getCities();

    final all = [..._localities, ..._cities];
    final filtered = all.where((a) {
      final matchesName = a.name.toLowerCase().contains(clean);
      final matchesCity = a.city.toLowerCase().contains(clean);
      final matchesQualified = a.qualifiedName.toLowerCase().contains(clean);
      final matchesType = a.typeLabel.toLowerCase().contains(clean);
      return matchesName || matchesCity || matchesQualified || matchesType;
    }).toList();

    // Sort matching results programmatically and prioritize direct name match
    filtered.sort((a, b) {
      final aExact = a.name.toLowerCase().startsWith(clean);
      final bExact = b.name.toLowerCase().startsWith(clean);
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;
      return a.qualifiedName.toLowerCase().compareTo(b.qualifiedName.toLowerCase());
    });

    return filtered;
  }

  /// Resolves an Area by its unique ID.
  static Area? getAreaById(String id) {
    final clean = id.trim().toLowerCase();
    try {
      return [..._cities, ..._localities].firstWhere(
        (a) => a.id.toLowerCase() == clean,
      );
    } catch (_) {
      return null;
    }
  }

  /// Resolves an Area by name, qualified name, or common synonym.
  static Area? findAreaByName(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return null;

    final all = [..._localities, ..._cities];

    // 1. Exact ID match
    for (final a in all) {
      if (a.id.toLowerCase() == clean) return a;
    }

    // 2. Exact qualified name match ("Ahmedabad / Naroda")
    for (final a in all) {
      if (a.qualifiedName.toLowerCase() == clean) return a;
    }

    // 3. Exact name match ("Naroda")
    for (final a in all) {
      if (a.name.toLowerCase() == clean) return a;
    }

    // 4. Substring or composite match ("Naroda", "Ahmedabad Plant 01 (Naroda)", "Gift City")
    for (final a in all) {
      if (clean.contains(a.name.toLowerCase()) || a.name.toLowerCase().contains(clean)) {
        return a;
      }
    }

    // 5. City fallback
    for (final c in _cities) {
      if (clean.contains(c.city.toLowerCase()) || c.city.toLowerCase().contains(clean)) {
        return c;
      }
    }

    return null;
  }
}
