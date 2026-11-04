import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/collection_item.dart';
import '../models/environment.dart';
import '../models/history_item.dart';

class StorageService {
  static const String _keyEnvironments = 'phoenix_environments';
  static const String _keyCollections = 'phoenix_collections';
  static const String _keyHistory = 'phoenix_history';
  static const String _keyActiveEnv = 'phoenix_active_env_id';
  static const String _keyThemeMode = 'phoenix_theme_mode';

  static Future<List<Environment>> loadEnvironments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyEnvironments);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        return list.map((e) => Environment.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    return [];
  }

  static Future<void> saveEnvironments(List<Environment> envs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(envs.map((e) => e.toJson()).toList());
    await prefs.setString(_keyEnvironments, jsonStr);
  }

  static Future<String?> loadActiveEnvironmentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveEnv);
  }

  static Future<void> saveActiveEnvironmentId(String? envId) async {
    final prefs = await SharedPreferences.getInstance();
    if (envId == null) {
      await prefs.remove(_keyActiveEnv);
    } else {
      await prefs.setString(_keyActiveEnv, envId);
    }
  }

  static Future<List<CollectionItem>> loadCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyCollections);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        return list
            .map((e) => CollectionItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    return [];
  }

  static Future<void> saveCollections(List<CollectionItem> collections) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(collections.map((e) => e.toJson()).toList());
    await prefs.setString(_keyCollections, jsonStr);
  }

  static Future<List<HistoryItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyHistory);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        return list
            .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    return [];
  }

  static Future<void> saveHistory(List<HistoryItem> history) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_keyHistory, jsonStr);
  }

  static Future<bool> loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyThemeMode) ?? true; // default to modern dark theme
  }

  static Future<void> saveDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyThemeMode, isDark);
  }
}
