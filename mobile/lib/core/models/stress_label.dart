class StressLabel {
  StressLabel({
    required this.label,
    required this.displayName,
    required this.category,
  });

  final String label;
  final String displayName;
  final String category;

  factory StressLabel.fromJson(Map<String, dynamic> json) {
    return StressLabel(
      label: json['label'] as String? ?? '',
      displayName: json['display_name'] as String? ?? json['label'] as String? ?? '',
      category: json['category'] as String? ?? 'Other',
    );
  }
}

