class PersonaModel {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final List<String> primaryMetrics;
  final String? badgeLabel;

  const PersonaModel({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.primaryMetrics,
    this.badgeLabel,
  });

  factory PersonaModel.fromJson(Map<String, dynamic> json) {
    return PersonaModel(
      id: json['id'] as String,
      name: json['name'] as String,
      tagline: json['tagline'] as String,
      description: json['description'] as String,
      primaryMetrics: (json['primary_metrics'] as List<dynamic>).map((e) => e.toString()).toList(),
      badgeLabel: json['badge_label'] as String?,
    );
  }
}
