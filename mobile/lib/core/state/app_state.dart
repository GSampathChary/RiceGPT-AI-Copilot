import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../data/disease_library.dart';
import '../data/stress_labels.dart';
import '../models/app_settings.dart';
import '../models/chat_models.dart';
import '../models/disease.dart';
import '../models/history_item.dart';
import '../services/api_client.dart';
import '../services/local_storage.dart';
import '../models/stress_label.dart';

class AppState extends ChangeNotifier {
  AppState()
      : settings = AppSettings(
          baseUrl: AppConfig.defaultBaseUrl,
          provider: AppConfig.defaultProvider,
          themeMode: ThemeMode.system,
          language: AppConfig.defaultLanguage,
        ),
        _apiClient = ApiClient(),
        _storage = LocalStorage();

  final LocalStorage _storage;
  final ApiClient _apiClient;

  AppSettings settings;
  bool isBootstrapped = false;
  bool isBusy = false;
  bool isDiagnosing = false;
  bool backendHealthy = false;
  final List<String> providers = ['gemini', 'openai', 'claude', 'grok', 'deepseek', 'ollama'];
  List<ChatMessage> currentConversation = [];
  List<ChatThread> chatHistory = [];
  List<DiagnosisItem> diagnosisHistory = [];
  List<DiseaseCard> diseases = diseaseLibrary;
  List<StressLabel> stressLabels = stressLabelsCatalog;
  DiagnosisResult? latestDiagnosis;
  String? draftPrompt;

  ThemeMode get themeMode => settings.themeMode;
  String get baseUrl => settings.baseUrl;
  String get selectedProvider => settings.provider;

  Future<void> bootstrap() async {
    final storedSettings = await _storage.readSettings();
    if (storedSettings != null) {
      settings = AppSettings.fromJson(storedSettings);
      settings = settings.copyWith(baseUrl: _normalizeBaseUrl(settings.baseUrl));
      _apiClient.baseUrl = settings.baseUrl;
    }

    final storedChats = await _storage.readChats();
    final storedDiagnoses = await _storage.readDiagnoses();
    chatHistory = storedChats.map(ChatThread.fromJson).toList();
    diagnosisHistory = storedDiagnoses.map(DiagnosisItem.fromJson).toList();

    try {
      final remoteProviders = await _apiClient.fetchProviders();
      if (remoteProviders.isNotEmpty) {
        providers
          ..clear()
          ..addAll(remoteProviders);
      }
      diseases = await _apiClient.fetchLibrary();
      stressLabels = await _apiClient.fetchLabels();
      backendHealthy = await _apiClient.health();
    } catch (_) {
      diseases = diseaseLibrary;
      stressLabels = stressLabelsCatalog;
      backendHealthy = false;
    }

    isBootstrapped = true;
    notifyListeners();
  }

  Future<void> setBaseUrl(String value) async {
    settings = settings.copyWith(baseUrl: _normalizeBaseUrl(value.trim().isEmpty ? AppConfig.defaultBaseUrl : value.trim()));
    _apiClient.baseUrl = settings.baseUrl;
    await _persistSettings();
    backendHealthy = await _apiClient.health();
    notifyListeners();
  }

  Future<void> refreshBackendStatus() async {
    backendHealthy = await _apiClient.health();
    notifyListeners();
  }

  Future<void> setProvider(String value) async {
    settings = settings.copyWith(provider: value);
    await _persistSettings();
    notifyListeners();
  }

  Future<void> toggleTheme(ThemeMode mode) async {
    settings = settings.copyWith(themeMode: mode);
    await _persistSettings();
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    settings = settings.copyWith(language: value);
    await _persistSettings();
    notifyListeners();
  }

  Future<void> _persistSettings() async {
    await _storage.writeSettings(settings.toJson());
  }

  String _normalizeBaseUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return AppConfig.defaultBaseUrl;
    }
    final uri = Uri.tryParse(trimmed);
    final host = uri?.host.toLowerCase() ?? '';
    if (host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '0.0.0.0' ||
        host == '::1' ||
        trimmed.contains('localhost') ||
        trimmed.contains('10.0.2.2')) {
      return AppConfig.defaultBaseUrl;
    }
    return trimmed;
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    currentConversation = [
      ...currentConversation,
      ChatMessage(role: 'user', content: message.trim()),
    ];
    isBusy = true;
    notifyListeners();

    final reply = await _apiClient.sendChat(
      message: message.trim(),
      provider: settings.provider,
      history: currentConversation,
    );

    currentConversation = [...currentConversation, reply];
    chatHistory = [
      ChatThread(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        query: message.trim(),
        answer: reply.content,
        provider: settings.provider,
        createdAt: DateTime.now(),
        context: '',
      ),
      ...chatHistory,
    ];
    await _persistChatHistory();
    isBusy = false;
    notifyListeners();
  }

  void clearConversation() {
    currentConversation = [];
    notifyListeners();
  }

  void setDraftPrompt(String message) {
    draftPrompt = message;
    notifyListeners();
  }

  void consumeDraftPrompt() {
    draftPrompt = null;
    notifyListeners();
  }

  void clearLatestDiagnosis() {
    latestDiagnosis = null;
    notifyListeners();
  }

  Future<void> diagnoseImage(File image) async {
    isDiagnosing = true;
    notifyListeners();
    final result = await _apiClient.diagnose(image, provider: settings.provider);
    latestDiagnosis = result;
    diagnosisHistory = [
      DiagnosisItem(
        id: result.id,
        imageName: result.imageName,
        disease: result.disease,
        confidence: result.confidence,
        provider: result.provider,
        createdAt: result.createdAt,
      ),
      ...diagnosisHistory,
    ];
    await _persistDiagnosisHistory();
    isDiagnosing = false;
    notifyListeners();
  }

  Future<void> refreshHistory() async {
    try {
      final chats = await _apiClient.fetchChatHistory();
      final diagnoses = await _apiClient.fetchDiagnosisHistory();
      if (chats.isNotEmpty) {
        chatHistory = chats;
        await _persistChatHistory();
      }
      if (diagnoses.isNotEmpty) {
        diagnosisHistory = diagnoses;
        await _persistDiagnosisHistory();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> deleteChat(String id) async {
    chatHistory.removeWhere((item) => item.id == id);
    await _persistChatHistory();
    notifyListeners();
  }

  Future<void> deleteDiagnosis(String id) async {
    diagnosisHistory.removeWhere((item) => item.id == id);
    await _persistDiagnosisHistory();
    notifyListeners();
  }

  Future<void> clearAllHistory() async {
    chatHistory = [];
    diagnosisHistory = [];
    await _persistChatHistory();
    await _persistDiagnosisHistory();
    notifyListeners();
  }

  Future<void> _persistChatHistory() async {
    await _storage.writeChats(chatHistory
        .map(
          (item) => {
            'id': item.id,
            'query': item.query,
            'answer': item.answer,
            'provider': item.provider,
            'created_at': item.createdAt.toIso8601String(),
            'disease_context': item.context,
          },
        )
        .toList());
  }

  Future<void> _persistDiagnosisHistory() async {
    await _storage.writeDiagnoses(
      diagnosisHistory
          .map(
            (item) => {
              'id': item.id,
              'image_name': item.imageName,
              'disease': item.disease,
              'confidence': item.confidence,
              'provider': item.provider,
              'created_at': item.createdAt.toIso8601String(),
            },
          )
          .toList(),
    );
  }
}
