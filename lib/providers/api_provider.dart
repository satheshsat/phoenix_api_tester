import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/api_request.dart';
import '../models/api_response.dart';
import '../models/collection_item.dart';
import '../models/environment.dart';
import '../models/history_item.dart';
import '../services/http_client_service.dart';
import '../services/storage_service.dart';
import '../services/curl_service.dart';

class ApiProvider extends ChangeNotifier {
  // Tabs & Active Request
  final List<ApiRequest> _tabs = [];
  int _activeTabIndex = 0;
  final Map<String, ApiResponse?> _tabResponses = {};
  bool _isLoading = false;

  // Environments
  List<Environment> _environments = [];
  String? _activeEnvironmentId;

  // Collections (Repository)
  List<CollectionItem> _collections = [];

  // History
  List<HistoryItem> _history = [];

  // UI state
  bool _isDarkMode = true;
  bool _isSidebarOpen = true;
  int _sidebarTab = 0; // 0: Repository, 1: History

  // Getters
  List<ApiRequest> get tabs => _tabs;
  int get activeTabIndex => _activeTabIndex;
  ApiRequest get currentRequest {
    if (_tabs.isEmpty) {
      _tabs.add(ApiRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'New Request',
        url: 'https://jsonplaceholder.typicode.com/posts/1',
      ));
    }
    if (_activeTabIndex >= _tabs.length) {
      _activeTabIndex = _tabs.length - 1;
    }
    return _tabs[_activeTabIndex];
  }

  ApiResponse? get currentResponse {
    if (_tabs.isEmpty) return null;
    return _tabResponses[currentRequest.id];
  }

  bool get isLoading => _isLoading;
  List<Environment> get environments => _environments;
  String? get activeEnvironmentId => _activeEnvironmentId;
  Environment? get activeEnvironment {
    if (_activeEnvironmentId == null) return null;
    try {
      return _environments.firstWhere((e) => e.id == _activeEnvironmentId);
    } catch (_) {
      return null;
    }
  }

  Map<String, String> get activeVariables {
    final env = activeEnvironment;
    if (env == null) return {};
    final map = <String, String>{};
    for (final v in env.variables) {
      if (v.isEnabled && v.key.trim().isNotEmpty) {
        map[v.key.trim()] = v.value;
      }
    }
    return map;
  }

  List<CollectionItem> get collections => _collections;
  List<HistoryItem> get history => _history;
  bool get isDarkMode => _isDarkMode;
  bool get isSidebarOpen => _isSidebarOpen;
  int get sidebarTab => _sidebarTab;

  // Initialize
  Future<void> init() async {
    _isDarkMode = await StorageService.loadDarkMode();
    _environments = await StorageService.loadEnvironments();
    _activeEnvironmentId = await StorageService.loadActiveEnvironmentId();
    if (_activeEnvironmentId == null && _environments.isNotEmpty) {
      _activeEnvironmentId = _environments.first.id;
    }
    _collections = await StorageService.loadCollections();
    _history = await StorageService.loadHistory();

    // Setup initial default tab
    if (_tabs.isEmpty) {
      // Find first request in collections if available
      ApiRequest? firstReq = _findFirstRequest(_collections);
      if (firstReq != null) {
        _tabs.add(firstReq.copyWith());
      } else {
        _tabs.add(ApiRequest(
          id: 'tab_init_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Get All Posts',
          method: 'GET',
          url: '{{baseUrl}}/posts?_limit=5',
        ));
      }
    }

    notifyListeners();
  }

  ApiRequest? _findFirstRequest(List<CollectionItem> items) {
    for (final item in items) {
      if (item.type == CollectionItemType.request && item.request != null) {
        return item.request;
      }
      final childReq = _findFirstRequest(item.children);
      if (childReq != null) return childReq;
    }
    return null;
  }

  // Tab Operations
  void openNewTab([ApiRequest? request]) {
    final newReq = request != null
        ? request.copyWith(
            id: 'tab_${DateTime.now().millisecondsSinceEpoch}_${_tabs.length}',
          )
        : ApiRequest(
            id: 'tab_${DateTime.now().millisecondsSinceEpoch}_${_tabs.length}',
            name: 'New Request',
            method: 'GET',
            url: '{{baseUrl}}/',
          );
    _tabs.add(newReq);
    _activeTabIndex = _tabs.length - 1;
    notifyListeners();
  }

  void openOrSelectRequest(ApiRequest request) {
    // Check if already open
    final existingIdx = _tabs.indexWhere((t) => t.url == request.url && t.name == request.name);
    if (existingIdx != -1) {
      _activeTabIndex = existingIdx;
    } else {
      openNewTab(request);
    }
    notifyListeners();
  }

  void closeTab(int index) {
    if (_tabs.length <= 1) {
      // Don't close last tab, just reset it
      _tabs[0] = ApiRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'New Request',
      );
      _tabResponses.clear();
      notifyListeners();
      return;
    }

    final removed = _tabs.removeAt(index);
    _tabResponses.remove(removed.id);

    if (_activeTabIndex >= _tabs.length) {
      _activeTabIndex = _tabs.length - 1;
    }
    notifyListeners();
  }

  void selectTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _activeTabIndex = index;
      notifyListeners();
    }
  }

  void updateCurrentRequest(ApiRequest updated) {
    if (_activeTabIndex < _tabs.length) {
      _tabs[_activeTabIndex] = updated;
      notifyListeners();
    }
  }

  // Request Execution
  Future<void> sendCurrentRequest() async {
    if (_isLoading) return;
    final req = currentRequest;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await HttpClientService.executeRequest(
        req,
        variables: activeVariables,
      );

      _tabResponses[req.id] = response;

      // Add to history
      final historyItem = HistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        request: req.copyWith(),
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        responseTimeMs: response.responseTimeMs,
        responseSizeBytes: response.responseSizeBytes,
        executedAt: DateTime.now(),
        isError: response.isError,
      );

      _history.insert(0, historyItem);
      if (_history.length > 200) {
        _history = _history.sublist(0, 200);
      }
      StorageService.saveHistory(_history);
    } catch (e) {
      _tabResponses[req.id] = ApiResponse.error(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResponse() {
    _tabResponses.remove(currentRequest.id);
    notifyListeners();
  }

  // Collections Operations
  void addProject(String name) {
    final newProject = CollectionItem(
      id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: CollectionItemType.project,
    );
    _collections.add(newProject);
    StorageService.saveCollections(_collections);
    notifyListeners();
  }

  void addService(String parentId, String name) {
    final newService = CollectionItem(
      id: 'srv_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: CollectionItemType.service,
      parentId: parentId,
    );
    _addItemToParent(_collections, parentId, newService);
    StorageService.saveCollections(_collections);
    notifyListeners();
  }

  void saveRequestToCollection(String parentId, ApiRequest req) {
    final newReqItem = CollectionItem(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      name: req.name,
      type: CollectionItemType.request,
      parentId: parentId,
      request: req.copyWith(),
    );
    _addItemToParent(_collections, parentId, newReqItem);
    StorageService.saveCollections(_collections);
    notifyListeners();
  }

  bool _addItemToParent(
      List<CollectionItem> items, String parentId, CollectionItem newItem) {
    for (final item in items) {
      if (item.id == parentId) {
        item.children.add(newItem);
        return true;
      }
      if (_addItemToParent(item.children, parentId, newItem)) {
        return true;
      }
    }
    return false;
  }

  void deleteCollectionItem(String id) {
    _removeItem(_collections, id);
    StorageService.saveCollections(_collections);
    notifyListeners();
  }

  bool _removeItem(List<CollectionItem> items, String id) {
    final idx = items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      items.removeAt(idx);
      return true;
    }
    for (final item in items) {
      if (_removeItem(item.children, id)) return true;
    }
    return false;
  }

  void renameCollectionItem(String id, String newName) {
    _renameItem(_collections, id, newName);
    StorageService.saveCollections(_collections);
    notifyListeners();
  }

  bool _renameItem(List<CollectionItem> items, String id, String newName) {
    for (final item in items) {
      if (item.id == id) {
        item.name = newName;
        if (item.request != null) {
          item.request!.name = newName;
        }
        return true;
      }
      if (_renameItem(item.children, id, newName)) return true;
    }
    return false;
  }

  void toggleExpandItem(String id) {
    _toggleExpand(_collections, id);
    notifyListeners();
  }

  bool _toggleExpand(List<CollectionItem> items, String id) {
    for (final item in items) {
      if (item.id == id) {
        item.isExpanded = !item.isExpanded;
        return true;
      }
      if (_toggleExpand(item.children, id)) return true;
    }
    return false;
  }

  // Environment Operations
  void addEnvironment(Environment env) {
    _environments.add(env);
    _activeEnvironmentId ??= env.id;
    StorageService.saveEnvironments(_environments);
    StorageService.saveActiveEnvironmentId(_activeEnvironmentId);
    notifyListeners();
  }

  void updateEnvironment(Environment env) {
    final idx = _environments.indexWhere((e) => e.id == env.id);
    if (idx != -1) {
      _environments[idx] = env;
      StorageService.saveEnvironments(_environments);
      notifyListeners();
    }
  }

  void deleteEnvironment(String id) {
    _environments.removeWhere((e) => e.id == id);
    if (_activeEnvironmentId == id) {
      _activeEnvironmentId =
          _environments.isNotEmpty ? _environments.first.id : null;
    }
    StorageService.saveEnvironments(_environments);
    StorageService.saveActiveEnvironmentId(_activeEnvironmentId);
    notifyListeners();
  }

  void setActiveEnvironment(String? envId) {
    _activeEnvironmentId = envId;
    StorageService.saveActiveEnvironmentId(envId);
    notifyListeners();
  }

  // History Operations
  void clearHistory() {
    _history.clear();
    StorageService.saveHistory(_history);
    notifyListeners();
  }

  void deleteHistoryItem(String id) {
    _history.removeWhere((h) => h.id == id);
    StorageService.saveHistory(_history);
    notifyListeners();
  }

  // cURL Import
  bool importCurl(String curlCommand) {
    final parsed = CurlService.fromCurl(curlCommand);
    if (parsed != null) {
      openNewTab(parsed);
      return true;
    }
    return false;
  }

  // UI Toggles
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    StorageService.saveDarkMode(_isDarkMode);
    notifyListeners();
  }

  void toggleSidebar() {
    _isSidebarOpen = !_isSidebarOpen;
    notifyListeners();
  }

  void setSidebarTab(int index) {
    _sidebarTab = index;
    notifyListeners();
  }

  // Export / Import Collections
  String exportCollectionsJson() {
    return const JsonEncoder.withIndent('  ')
        .convert(_collections.map((e) => e.toJson()).toList());
  }

  bool importCollectionsJson(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        final imported = decoded
            .map((e) => CollectionItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _collections.addAll(imported);
        StorageService.saveCollections(_collections);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
