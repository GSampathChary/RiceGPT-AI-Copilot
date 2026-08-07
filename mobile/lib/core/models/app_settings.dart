import 'package:flutter/material.dart';

class AppSettings {
  AppSettings({
    required this.baseUrl,
    required this.provider,
    required this.themeMode,
    required this.language,
  });

  final String baseUrl;
  final String provider;
  final ThemeMode themeMode;
  final String language;

  AppSettings copyWith({
    String? baseUrl,
    String? provider,
    ThemeMode? themeMode,
    String? language,
  }) {
    return AppSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      provider: provider ?? this.provider,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'provider': provider,
        'themeMode': themeMode.name,
        'language': language,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      baseUrl: json['baseUrl'] as String? ?? '',
      provider: json['provider'] as String? ?? 'gemini',
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      language: json['language'] as String? ?? 'English',
    );
  }
}

