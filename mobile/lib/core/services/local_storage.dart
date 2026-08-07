import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _settingsKey = 'ricegpt_settings';
  static const _chatKey = 'ricegpt_chat_history';
  static const _diagnosisKey = 'ricegpt_diagnosis_history';

  Future<Map<String, dynamic>?> readSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> writeSettings(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(json));
  }

  Future<List<Map<String, dynamic>>> readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final data = jsonDecode(raw) as List<dynamic>;
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
  }

  Future<List<Map<String, dynamic>>> readChats() => readList(_chatKey);
  Future<List<Map<String, dynamic>>> readDiagnoses() => readList(_diagnosisKey);
  Future<void> writeChats(List<Map<String, dynamic>> items) => writeList(_chatKey, items);
  Future<void> writeDiagnoses(List<Map<String, dynamic>> items) => writeList(_diagnosisKey, items);
}
