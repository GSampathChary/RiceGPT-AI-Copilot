import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../config/app_config.dart';
import '../data/disease_library.dart';
import '../data/stress_labels.dart';
import '../models/chat_models.dart';
import '../models/disease.dart';
import '../models/history_item.dart';
import '../models/app_settings.dart';
import '../models/stress_label.dart';

class ApiClient {
  ApiClient({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
          ),
        ),
        baseUrl = baseUrl ?? AppConfig.defaultBaseUrl;

  final Dio _dio;
  String baseUrl;

  String get _api => baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  Future<bool> health() async {
    try {
      final response = await _dio.get('$_api/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> fetchProviders() async {
    try {
      final response = await _dio.get('$_api/api/providers');
      final data = response.data as Map<String, dynamic>;
      final providers = data['providers'] as List<dynamic>;
      return providers.map((item) => item['id'] as String).toList();
    } catch (_) {
      return const ['gemini', 'openai', 'claude', 'grok', 'deepseek', 'ollama'];
    }
  }

  Future<List<DiseaseCard>> fetchLibrary({String? query}) async {
    try {
      final response = await _dio.get(
        '$_api/api/library/diseases',
        queryParameters: query == null || query.isEmpty ? null : {'q': query},
      );
      final items = response.data['items'] as List<dynamic>;
      return items.map((item) => DiseaseCard.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } catch (_) {
      final filtered = diseaseLibrary.where((disease) {
        if (query == null || query.isEmpty) return true;
        final q = query.toLowerCase();
        return disease.name.toLowerCase().contains(q) || disease.symptoms.toLowerCase().contains(q);
      }).toList();
      return filtered;
    }
  }

  Future<List<StressLabel>> fetchLabels() async {
    try {
      final response = await _dio.get('$_api/api/labels');
      final items = response.data['items'] as List<dynamic>;
      return items.map((item) => StressLabel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } catch (_) {
      return stressLabelsCatalog;
    }
  }

  Future<ChatMessage> sendChat({
    required String message,
    required String provider,
    required List<ChatMessage> history,
  }) async {
    try {
      final response = await _dio.post(
        '$_api/api/chat',
        data: {
          'message': message,
          'provider': provider,
          'history': history.map((item) => item.toJson()).toList(),
        },
      );
      return ChatMessage(
        role: 'assistant',
        content: response.data['answer'] as String? ?? '',
        createdAt: DateTime.tryParse(response.data['created_at'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      return ChatMessage(
        role: 'assistant',
        content: _fallbackChat(message),
      );
    }
  }

  Future<DiagnosisResult> diagnose(File image, {required String provider}) async {
    try {
      final form = FormData.fromMap({
        'provider': provider,
        'file': await MultipartFile.fromFile(image.path, filename: p.basename(image.path)),
      });
      debugPrint('RiceGPT diagnosis request -> $_api/api/diagnosis');
      final response = await _dio.post('$_api/api/diagnosis', data: form);
      final data = Map<String, dynamic>.from(response.data as Map);
      return DiagnosisResult.fromJson(data);
    } on DioException catch (error) {
      debugPrint('RiceGPT diagnosis request failed: ${error.message}');
      if (error.response != null) {
        debugPrint('RiceGPT diagnosis response: ${error.response?.statusCode} ${error.response?.data}');
      }
      return _fallbackDiagnosis(image.path);
    } catch (error) {
      debugPrint('RiceGPT diagnosis request failed: $error');
      return _fallbackDiagnosis(image.path);
    }
  }

  Future<List<ChatThread>> fetchChatHistory() async {
    try {
      final response = await _dio.get('$_api/api/history');
      final items = response.data['chats'] as List<dynamic>;
      return items.map((item) => ChatThread.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<DiagnosisItem>> fetchDiagnosisHistory() async {
    try {
      final response = await _dio.get('$_api/api/history');
      final items = response.data['diagnoses'] as List<dynamic>;
      return items.map((item) => DiagnosisItem.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } catch (_) {
      return const [];
    }
  }

  String _fallbackChat(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('yellow')) {
      return 'Yellow leaves often point to nitrogen deficiency, water stress, or root problems. Check drainage, fertility, and whether the issue is patchy or widespread.';
    }
    if (lower.contains('blast')) {
      return 'Rice blast causes spindle-shaped lesions and can damage leaves and necks. Use resistant varieties, avoid excess nitrogen, and keep good airflow.';
    }
    if (lower.contains('brown spot')) {
      return 'Brown spot is linked to fungal stress and poor fertility. Improve balanced nutrition, keep residue clean, and treat only if needed.';
    }
    return 'Share the crop stage, leaf symptoms, and field conditions so I can give a sharper rice-specific recommendation.';
  }

  DiagnosisResult _fallbackDiagnosis(String imageName) {
    final fallbackDisease = DiseaseCard(
      name: 'Rice disease',
      aliases: const [],
      symptoms: 'Inspect the leaf carefully.',
      cause: 'The model is not connected yet.',
      treatment: 'Use a configured model for accurate prediction.',
      prevention: 'Upload your trained `.h5`, `.keras`, `.pt`, or `.pth` file on the backend.',
      recommendedFungicide: 'Follow local advice after confirmation.',
      organicSolution: 'Use integrated crop management.',
      farmerTips: 'Capture a clearer leaf image in daylight.',
      fertilizerRecommendation: 'Use balanced nutrition.',
    );
    final disease = diseaseLibrary.firstWhere(
      (item) => item.name.toLowerCase() == 'healthy',
      orElse: () => diseaseLibrary.isNotEmpty ? diseaseLibrary.first : fallbackDisease,
    );
    return DiagnosisResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      disease: disease.name,
      confidence: 0.56,
      provider: 'offline',
      modelPath: '',
      createdAt: DateTime.now(),
      explanation: disease,
      suggestions: const [
        'Retake the photo in brighter daylight.',
        'Check if the problem appears on multiple leaves.',
        'Avoid excess nitrogen until the issue is identified.',
      ],
      imageName: imageName,
    );
  }
}

class DiagnosisResult {
  DiagnosisResult({
    required this.id,
    required this.disease,
    required this.confidence,
    required this.provider,
    required this.modelPath,
    required this.createdAt,
    required this.explanation,
    required this.suggestions,
    required this.imageName,
  });

  final String id;
  final String disease;
  final double confidence;
  final String provider;
  final String modelPath;
  final DateTime createdAt;
  final DiseaseCard explanation;
  final List<String> suggestions;
  final String imageName;

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    return DiagnosisResult(
      id: json['id'] as String? ?? '',
      disease: json['disease'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      provider: json['provider'] as String? ?? 'gemini',
      modelPath: json['model_path'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      explanation: DiseaseCard.fromJson(Map<String, dynamic>.from(json['explanation'] as Map)),
      suggestions: (json['suggestions'] as List<dynamic>? ?? []).cast<String>(),
      imageName: json['image_name'] as String? ?? '',
    );
  }
}
