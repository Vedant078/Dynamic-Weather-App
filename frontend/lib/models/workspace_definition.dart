import 'persona.dart';

/// Workspace Definition (Section 14: Data-Aware Workspace Metadata)
class WorkspaceDefinition {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final String? keyCapability;
  final List<String> capabilities;
  final bool isFlagship;

  const WorkspaceDefinition({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    this.keyCapability,
    this.capabilities = const [],
    this.isFlagship = false,
  });

  factory WorkspaceDefinition.fromPersona(PersonaModel p) {
    String? keyCap;
    List<String> caps = [];
    final bool flagship = p.id == 'rmc';

    switch (p.id) {
      case 'rmc':
        caps = const ['Dynamic Slump Risk', 'Route Intelligence', 'Transit Loss Prevention'];
        keyCap = 'Transit risk • Slump retention • Route conditions';
        break;
      case 'health':
        keyCap = 'AQI • Heat • Pollen';
        caps = const ['AQI Monitoring', 'Heat Strain Warnings', 'Pollen Radar'];
        break;
      case 'fitness':
        keyCap = 'Safe Windows • Heat Alerts • Headwind';
        caps = const ['Running Window Predictor', 'Heat Alerts', 'Headwind Vectors'];
        break;
      case 'beach':
        keyCap = 'Tide Swell • Water Temp • Rip Currents';
        caps = const ['Tide Schedule', 'Wave Swell Height', 'Water Temp'];
        break;
      case 'traveler':
        keyCap = 'Highway Visibility • Delay Alerts';
        caps = const ['Corridor Visibility', 'Rainfall Accumulation', 'Route Delay'];
        break;
      case 'family':
        keyCap = 'School Commute • Storm Warnings';
        caps = const ['Commute Risk Guard', 'Sudden Rain Alerts', 'UV Advisory'];
        break;
      case 'agriculture':
        keyCap = 'Soil Moisture • Frost • Crop Windows';
        caps = const ['Soil Moisture Index', 'Frost Risk', 'Evapotranspiration Rate'];
        break;
      default:
        keyCap = p.primaryMetrics.join(' • ');
    }

    return WorkspaceDefinition(
      id: p.id,
      name: p.name,
      tagline: p.tagline,
      description: p.description,
      keyCapability: keyCap,
      capabilities: caps,
      isFlagship: flagship,
    );
  }
}

/// Dynamic Operational Summary for a Workspace (Scoped to authenticated account)
class WorkspaceOperationalSummary {
  final int activeDeliveries;
  final int attentionCount;
  final bool hasLiveTelemetry;

  const WorkspaceOperationalSummary({
    this.activeDeliveries = 0,
    this.attentionCount = 0,
    this.hasLiveTelemetry = false,
  });
}
