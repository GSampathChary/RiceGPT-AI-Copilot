class DiagnosisItem {
  DiagnosisItem({
    required this.id,
    required this.imageName,
    required this.disease,
    required this.confidence,
    required this.provider,
    required this.createdAt,
  });

  final String id;
  final String imageName;
  final String disease;
  final double confidence;
  final String provider;
  final DateTime createdAt;

  factory DiagnosisItem.fromJson(Map<String, dynamic> json) {
    return DiagnosisItem(
      id: json['id'] as String? ?? '',
      imageName: json['image_name'] as String? ?? '',
      disease: json['disease'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      provider: json['provider'] as String? ?? 'gemini',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

