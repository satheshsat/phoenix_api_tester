import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_request.dart';
import '../models/assertion_item.dart';
import '../models/auth_config.dart';
import '../models/body_config.dart';
import '../models/collection_item.dart';
import '../models/environment.dart';
import '../models/history_item.dart';
import '../models/key_value_item.dart';

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
    return _getDefaultEnvironments();
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
    return _getDefaultCollections();
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

  // Sample seed data
  static List<Environment> _getDefaultEnvironments() {
    return [
      Environment(
        id: 'env_jsonplaceholder',
        name: 'JSONPlaceholder API',
        variables: [
          KeyValueItem(
            key: 'baseUrl',
            value: 'https://jsonplaceholder.typicode.com',
            description: 'Public REST API server for testing',
            isEnabled: true,
          ),
          KeyValueItem(
            key: 'userId',
            value: '1',
            description: 'Default user ID',
            isEnabled: true,
          ),
        ],
      ),
      Environment(
        id: 'env_httpbin',
        name: 'HTTPBin Testing',
        variables: [
          KeyValueItem(
            key: 'baseUrl',
            value: 'https://httpbin.org',
            description: 'HTTP request & response service',
            isEnabled: true,
          ),
          KeyValueItem(
            key: 'token',
            value: 'phoenix_secret_token_123',
            description: 'Auth bearer token',
            isEnabled: true,
          ),
        ],
      ),
    ];
  }

  static List<CollectionItem> _getDefaultCollections() {
    return [
      CollectionItem(
        id: 'proj_sample',
        name: 'Sample REST API Project',
        description: 'Starter collection demonstrating Talend API Tester features',
        type: CollectionItemType.project,
        children: [
          CollectionItem(
            id: 'folder_posts',
            name: 'Posts Service',
            type: CollectionItemType.service,
            parentId: 'proj_sample',
            children: [
              CollectionItem(
                id: 'req_get_posts',
                name: 'Get All Posts',
                type: CollectionItemType.request,
                parentId: 'folder_posts',
                request: ApiRequest(
                  id: 'req_get_posts',
                  name: 'Get All Posts',
                  method: 'GET',
                  url: '{{baseUrl}}/posts',
                  queryParams: [
                    KeyValueItem(key: '_limit', value: '5', isEnabled: true),
                  ],
                  assertions: [
                    AssertionItem(
                      id: 'as_1',
                      target: AssertionTarget.statusCode,
                      operator: AssertionOperator.equals,
                      expectedValue: '200',
                    ),
                    AssertionItem(
                      id: 'as_2',
                      target: AssertionTarget.responseTime,
                      operator: AssertionOperator.lessThan,
                      expectedValue: '3000',
                    ),
                    AssertionItem(
                      id: 'as_3',
                      target: AssertionTarget.bodyText,
                      operator: AssertionOperator.contains,
                      expectedValue: 'title',
                    ),
                  ],
                ),
              ),
              CollectionItem(
                id: 'req_get_post_1',
                name: 'Get Single Post',
                type: CollectionItemType.request,
                parentId: 'folder_posts',
                request: ApiRequest(
                  id: 'req_get_post_1',
                  name: 'Get Single Post',
                  method: 'GET',
                  url: '{{baseUrl}}/posts/1',
                  assertions: [
                    AssertionItem(
                      id: 'as_p1',
                      target: AssertionTarget.statusCode,
                      operator: AssertionOperator.equals,
                      expectedValue: '200',
                    ),
                    AssertionItem(
                      id: 'as_p2',
                      target: AssertionTarget.jsonValue,
                      property: 'id',
                      operator: AssertionOperator.equals,
                      expectedValue: '1',
                    ),
                  ],
                ),
              ),
              CollectionItem(
                id: 'req_create_post',
                name: 'Create Post',
                type: CollectionItemType.request,
                parentId: 'folder_posts',
                request: ApiRequest(
                  id: 'req_create_post',
                  name: 'Create Post',
                  method: 'POST',
                  url: '{{baseUrl}}/posts',
                  body: BodyConfig(
                    type: BodyType.json,
                    jsonText: '{\n  "title": "Phoenix API Tester Launch",\n  "body": "A powerful Talend API Tester clone built in Flutter.",\n  "userId": 1\n}',
                  ),
                  assertions: [
                    AssertionItem(
                      id: 'as_c1',
                      target: AssertionTarget.statusCode,
                      operator: AssertionOperator.equals,
                      expectedValue: '201',
                    ),
                  ],
                ),
              ),
              CollectionItem(
                id: 'req_update_post',
                name: 'Update Post',
                type: CollectionItemType.request,
                parentId: 'folder_posts',
                request: ApiRequest(
                  id: 'req_update_post',
                  name: 'Update Post',
                  method: 'PUT',
                  url: '{{baseUrl}}/posts/1',
                  body: BodyConfig(
                    type: BodyType.json,
                    jsonText: '{\n  "id": 1,\n  "title": "Updated Post Title",\n  "body": "Updated content from Phoenix API Tester",\n  "userId": 1\n}',
                  ),
                  assertions: [
                    AssertionItem(
                      id: 'as_u1',
                      target: AssertionTarget.statusCode,
                      operator: AssertionOperator.equals,
                      expectedValue: '200',
                    ),
                  ],
                ),
              ),
              CollectionItem(
                id: 'req_delete_post',
                name: 'Delete Post',
                type: CollectionItemType.request,
                parentId: 'folder_posts',
                request: ApiRequest(
                  id: 'req_delete_post',
                  name: 'Delete Post',
                  method: 'DELETE',
                  url: '{{baseUrl}}/posts/1',
                  assertions: [
                    AssertionItem(
                      id: 'as_d1',
                      target: AssertionTarget.statusCode,
                      operator: AssertionOperator.equals,
                      expectedValue: '200',
                    ),
                  ],
                ),
              ),
            ],
          ),
          CollectionItem(
            id: 'folder_httpbin',
            name: 'HTTPBin Inspection',
            type: CollectionItemType.service,
            parentId: 'proj_sample',
            children: [
              CollectionItem(
                id: 'req_headers',
                name: 'Inspect Request Headers',
                type: CollectionItemType.request,
                parentId: 'folder_httpbin',
                request: ApiRequest(
                  id: 'req_headers',
                  name: 'Inspect Request Headers',
                  method: 'GET',
                  url: 'https://httpbin.org/headers',
                  headers: [
                    KeyValueItem(
                      key: 'X-Phoenix-Client',
                      value: 'Talend-Clone-v1',
                      isEnabled: true,
                    ),
                  ],
                  auth: AuthConfig(
                    type: AuthType.bearer,
                    bearerToken: 'phoenix_demo_secret',
                  ),
                  assertions: [
                    AssertionItem(
                      id: 'as_h1',
                      target: AssertionTarget.statusCode,
                      operator: AssertionOperator.equals,
                      expectedValue: '200',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ];
  }
}

