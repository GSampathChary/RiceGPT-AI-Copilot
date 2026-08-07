class DiseaseCard {
  DiseaseCard({
    required this.name,
    required this.aliases,
    required this.symptoms,
    required this.cause,
    required this.treatment,
    required this.prevention,
    required this.recommendedFungicide,
    required this.organicSolution,
    required this.farmerTips,
    required this.fertilizerRecommendation,
  });

  final String name;
  final List<String> aliases;
  final String symptoms;
  final String cause;
  final String treatment;
  final String prevention;
  final String recommendedFungicide;
  final String organicSolution;
  final String farmerTips;
  final String fertilizerRecommendation;

  factory DiseaseCard.fromJson(Map<String, dynamic> json) {
    return DiseaseCard(
      name: json['name'] as String? ?? '',
      aliases: (json['aliases'] as List<dynamic>? ?? []).cast<String>(),
      symptoms: json['symptoms'] as String? ?? '',
      cause: json['cause'] as String? ?? '',
      treatment: json['treatment'] as String? ?? '',
      prevention: json['prevention'] as String? ?? '',
      recommendedFungicide: json['recommended_fungicide'] as String? ?? '',
      organicSolution: json['organic_solution'] as String? ?? '',
      farmerTips: json['farmer_tips'] as String? ?? '',
      fertilizerRecommendation: json['fertilizer_recommendation'] as String? ?? '',
    );
  }
}

