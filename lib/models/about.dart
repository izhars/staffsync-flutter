class AboutDataModel {
  final AboutSection about;
  final List<StatItem> stats;
  final List<TimelineItem> timeline;
  final List<TeamMember> team;
  final List<String> achievements; // Add this

  AboutDataModel({
    required this.about,
    required this.stats,
    required this.timeline,
    required this.team,
    required this.achievements, // Add this
  });

  factory AboutDataModel.fromJson(Map<String, dynamic> json) {
    return AboutDataModel(
      about: AboutSection.fromJson(json['about'] ?? json), // Modified this line
      stats: (json['stats'] as List? ?? [])
          .map((item) => StatItem.fromJson(item))
          .toList(),
      timeline: (json['timeline'] as List? ?? [])
          .map((item) => TimelineItem.fromJson(item))
          .toList(),
      team: (json['team'] as List? ?? [])
          .map((item) => TeamMember.fromJson(item))
          .toList(),
      achievements: (json['achievements'] as List<dynamic>? ?? []) // Add this
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class AboutSection {
  final String companyName;
  final String slogan;
  final String description;
  final String mission;
  final String vision;
  final List<String> values;
  final List<String> achievements; // Add this

  AboutSection({
    required this.companyName,
    required this.slogan,
    required this.description,
    required this.mission,
    required this.vision,
    required this.values,
    required this.achievements, // Add this
  });

  factory AboutSection.fromJson(Map<String, dynamic> json) {
    return AboutSection(
      companyName: json['companyName'] ?? '',
      slogan: json['slogan'] ?? '',
      description: json['description'] ?? '',
      mission: json['mission'] ?? '',
      vision: json['vision'] ?? '',
      values: (json['values'] as List<dynamic>? ?? []).cast<String>(),
      achievements: (json['achievements'] as List<dynamic>? ?? []) // Add this
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class StatItem {
  final String label;
  final String value;
  final String suffix;

  StatItem({required this.label, required this.value, required this.suffix});

  factory StatItem.fromJson(Map<String, dynamic> json) {
    return StatItem(
      label: json['label'] ?? '',
      value: json['value']?.toString() ?? '0',
      suffix: json['suffix'] ?? '',
    );
  }
}

class TimelineItem {
  final int year;
  final String title;
  final String description;

  TimelineItem({
    required this.year,
    required this.title,
    required this.description,
  });

  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    return TimelineItem(
      year: json['year'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class TeamMember {
  final String name;
  final String role;
  final String? imageUrl;

  TeamMember({required this.name, required this.role, this.imageUrl});

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }
}
