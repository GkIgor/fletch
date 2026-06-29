import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:fletch/backend/requests/models/http_request.dart';
import 'package:fletch/backend/requests/models/http_response.dart';
import 'package:fletch/backend/collections/models/collection.dart';
import 'package:fletch/backend/collections/repository/collection_repository.dart';
import 'package:fletch/backend/workspace/repository/workspace_repository.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:fletch/backend/requests/services/http_service.dart';
import 'package:fletch/backend/collections/converters/postman_converter.dart';
import 'package:fletch/backend/collections/converters/insomnia_converter.dart';
import 'package:fletch/backend/workspace/models/workspace.dart';
import 'package:fletch/backend/scripting/execution/script_execution_context.dart';
import 'package:fletch/backend/requests/use_cases/execute_request.dart';

class RequestProvider with ChangeNotifier {
  final CollectionRepository _repository = CollectionRepository();
  final HttpService _httpService;

  RequestProvider({HttpService? httpService})
    : _httpService = httpService ?? HttpService();

  List<RequestCollection> _collections = [];

  HttpRequest? _selectedRequest;

  HttpResponse? _currentResponse;

  bool _isLoading = false;

  ExecutionContext? _lastExecutionContext;

  String _searchFilter = '';

  String? _workspaceId;

  List<Map<String, dynamic>> _corruptedCollections = [];


  List<RequestCollection> get collections => _collections;
  List<Map<String, dynamic>> get corruptedCollections => _corruptedCollections;
  HttpRequest? get selectedRequest => _selectedRequest;
  HttpResponse? get currentResponse => _currentResponse;
  bool get isLoading => _isLoading;
  ExecutionContext? get lastExecutionContext => _lastExecutionContext;
  String get searchFilter => _searchFilter;


  static const Map<String, IconData> icons = {
    'folder': Icons.folder_rounded,
    'api': Icons.api_rounded,
    'webhook': Icons.webhook_rounded,
    'storage': Icons.storage_rounded,
  };

  static const Map<String, Color> colors = {
    '#8b5cf6': AppColors.primary,
    '#10b981': Color(0xFF10b981),
    '#f59e0b': Color(0xFFf59e0b),
    '#f43f5e': Color(0xFFf43f5e),
  };

  Future<void> addCollection(RequestCollection collection) async {
    final maxSortOrder = _collections.isEmpty
        ? 0
        : _collections.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b);
    final collectionWithSortOrder = collection.copyWith(
      sortOrder: maxSortOrder + 1,
    );
    _collections.add(collectionWithSortOrder);
    await _saveCollections();
    notifyListeners();
  }

  Future<void> removeCollection(String collectionId) async {
    _collections.removeWhere((c) => c.id == collectionId);
    await _repository.delete(collectionId);
    await _updateWorkspaceRequestCount();
    notifyListeners();
  }

  Future<void> updateCollection(RequestCollection collection) async {
    final index = _collections.indexWhere((c) => c.id == collection.id);
    if (index != -1) {
      _collections[index] = collection;
      await _saveCollections();
      notifyListeners();
    }
  }

  void toggleCollectionExpansion(String collectionId) {
    final index = _collections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      _collections[index] = _collections[index].copyWith(
        isExpanded: !_collections[index].isExpanded,
      );
      notifyListeners();
    }
  }

  void toggleAllCollections({required bool expanded}) {
    for (int i = 0; i < _collections.length; i++) {
      _collections[i] = _collections[i].copyWith(isExpanded: expanded);
    }
    notifyListeners();
  }

  void addRequestToCollection(String collectionId, HttpRequest request) {
    final collection = _collections.firstWhere((c) => c.id == collectionId);
    collection.addRequest(request);
    _saveCollections();
    notifyListeners();
  }

  void removeRequestFromCollection(String collectionId, String requestId) {
    final collection = _collections.firstWhere((c) => c.id == collectionId);
    collection.removeRequest(requestId);
    if (_selectedRequest?.id == requestId) {
      _selectedRequest = null;
      _currentResponse = null;
    }
    _saveCollections();
    notifyListeners();
  }

  void selectRequest(HttpRequest? request) {
    _selectedRequest = request;
    _currentResponse = null;
    notifyListeners();
  }

  void updateSelectedRequest(HttpRequest request) {
    if (_selectedRequest?.id == request.id) {
      _selectedRequest = request;

      for (var collection in _collections) {
        final index = collection.requests.indexWhere((r) => r.id == request.id);
        if (index != -1) {
          collection.requests[index] = request;
          _saveCollections();
          break;
        }
      }

      notifyListeners();
    }
  }

  void setCurrentResponse(HttpResponse? response) {
    _currentResponse = response;
    notifyListeners();
  }

  Future<void> executeRequest(
    HttpRequest request, {
    Map<String, String>? variables,
    WorkspaceModel? workspace,
  }) async {
    _isLoading = true;
    _currentResponse = null;
    _lastExecutionContext = null;
    notifyListeners();

    try {
      final ws = workspace ?? WorkspaceModel(name: 'Default WS');
      final executeRequestUseCase = ExecuteRequest(
        httpClient: _httpService,
        workspaceRepository: WorkspaceRepository(),
      );

      final pipelineContext = await executeRequestUseCase(
        request: request,
        collections: _collections,
        workspace: ws,
        variables: variables,
      );

      _currentResponse = pipelineContext.response;
      _lastExecutionContext = pipelineContext.scriptContext;
    } catch (e) {
      debugPrint('Erro inesperado ao enviar requisição ou rodar scripts: $e');
      final errBody = e.toString().replaceAll('Exception: ', '');
      _currentResponse = HttpResponse(
        statusCode: 0,
        statusMessage: 'Error',
        headers: {},
        body: errBody,
        responseTime: 0,
        contentLength: 0,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setSearchFilter(String filter) {
    _searchFilter = filter;
    notifyListeners();
  }

  List<RequestCollection> get filteredCollections {
    if (_searchFilter.isEmpty) {
      return _collections;
    }

    return _collections
        .map((collection) {
          final filteredRequests = collection.requests
              .where(
                (request) =>
                    request.name.toLowerCase().contains(
                      _searchFilter.toLowerCase(),
                    ) ||
                    request.url.toLowerCase().contains(
                      _searchFilter.toLowerCase(),
                    ),
              )
              .toList();

          if (filteredRequests.isEmpty) {
            return null;
          }

          return collection.copyWith(requests: filteredRequests);
        })
        .whereType<RequestCollection>()
        .toList();
  }

  Future<void> loadCollections(String workspaceId) async {
    _workspaceId = workspaceId;
    final loaded = await _repository.getAll(workspaceId);
    loaded.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _collections = loaded;

    _corruptedCollections = await _repository.getCorruptedCollections(
      workspaceId,
    );

    if (_collections.isNotEmpty && _collections[0].requests.isNotEmpty) {
      _selectedRequest = _collections[0].requests[0];
    }

    await _updateWorkspaceRequestCount();
    notifyListeners();
  }

  Future<void> _saveCollections() async {
    try {
      await _repository.saveAll(_collections);
      await _updateWorkspaceRequestCount();
    } catch (e) {
      debugPrint('Erro ao salvar coleções: $e');
    }
  }

  Future<void> _updateWorkspaceRequestCount() async {
    final wsId = _workspaceId;
    if (wsId == null) return;
    try {
      final totalRequests = _collections.fold<int>(
        0,
        (sum, c) => sum + c.requests.length,
      );
      final wsRepo = WorkspaceRepository();
      final ws = await wsRepo.getById(wsId);
      if (ws != null) {
        ws.requestCount = totalRequests;
        await wsRepo.save(ws);
      }
    } catch (e) {
      debugPrint('Erro ao atualizar contador de requests do workspace: $e');
    }
  }

  List<Map<String, dynamic>> exportCollections() {
    return _collections.map((c) => c.toJson()).toList();
  }

  Map<String, dynamic> exportPostman(String workspaceName) {
    return PostmanConverter.exportCollection(_collections, workspaceName);
  }

  Map<String, dynamic> exportInsomnia(
    String workspaceId,
    String workspaceName, {
    int exportFormat = 4,
  }) {
    return InsomniaConverter.exportCollection(
      _collections,
      workspaceId,
      workspaceName,
      exportFormat: exportFormat,
    );
  }

  Future<void> importCollections(
    List<Map<String, dynamic>> data,
    String workspaceId,
  ) async {
    try {
      final List<RequestCollection> imported = data.map((json) {
        json['workspaceId'] = workspaceId;
        json.remove('signature');
        return RequestCollection.fromJson(json);
      }).toList();

      _collections.addAll(imported);

      for (int i = 0; i < _collections.length; i++) {
        _collections[i] = _collections[i].copyWith(sortOrder: i);
      }

      await _saveCollections();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao importar coleções: $e');
      rethrow;
    }
  }

  Future<void> importLoadedCollections(
    List<RequestCollection> imported,
    String workspaceId,
  ) async {
    try {
      for (var col in imported) {
        col.workspaceId = workspaceId;
      }
      _collections.addAll(imported);

      for (int i = 0; i < _collections.length; i++) {
        _collections[i] = _collections[i].copyWith(sortOrder: i);
      }

      await _saveCollections();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao importar coleções carregadas: $e');
      rethrow;
    }
  }

  void reorderCollections(
    String draggedId,
    String targetId, {
    bool before = true,
  }) {
    final dragIndex = _collections.indexWhere((c) => c.id == draggedId);
    if (dragIndex == -1) return;

    final dragged = _collections[dragIndex];
    _collections.removeAt(dragIndex);

    int targetIndex = _collections.indexWhere((c) => c.id == targetId);
    if (targetIndex != -1) {
      final target = _collections[targetIndex];
      final updatedDragged = dragged.copyWith(
        parentId: target.parentId,
        clearParentId: target.parentId == null,
      );
      final insertIndex = before ? targetIndex : targetIndex + 1;
      _collections.insert(insertIndex, updatedDragged);
    } else {
      _collections.insert(dragIndex, dragged);
    }

    for (int i = 0; i < _collections.length; i++) {
      _collections[i] = _collections[i].copyWith(sortOrder: i);
    }

    _saveCollections();
    notifyListeners();
  }

  void nestCollection(String draggedId, String targetParentId) {
    final idx = _collections.indexWhere((c) => c.id == draggedId);
    if (idx != -1) {
      _collections[idx] = _collections[idx].copyWith(parentId: targetParentId);

      final parentIdx = _collections.indexWhere((c) => c.id == targetParentId);
      if (parentIdx != -1 && !_collections[parentIdx].isExpanded) {
        _collections[parentIdx] = _collections[parentIdx].copyWith(
          isExpanded: true,
        );
      }

      _saveCollections();
      notifyListeners();
    }
  }

  Future<void> createSubCollection(
    String parentCollectionId,
    String name,
  ) async {
    final parentIdx = _collections.indexWhere(
      (c) => c.id == parentCollectionId,
    );
    if (parentIdx == -1) return;

    final parent = _collections[parentIdx];
    final subCollection = RequestCollection(
      name: name,
      workspaceId: parent.workspaceId,
      parentId: parentCollectionId,
      icon: 'folder',
      color: parent.color,
      sortOrder: _collections.length,
    );

    if (!parent.isExpanded) {
      _collections[parentIdx] = parent.copyWith(isExpanded: true);
    }

    _collections.add(subCollection);
    await _saveCollections();
    notifyListeners();
  }

  Future<void> reSignCollection(Map<String, dynamic> collectionData) async {
    try {
      collectionData.remove('signature');
      final collection = RequestCollection.fromJson(collectionData);
      await _repository.save(collection);

      _corruptedCollections.removeWhere((c) => c['id'] == collection.id);
      _collections.add(collection);
      _collections.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao re-assinar coleção: $e');
    }
  }

  Future<void> reSignAllCorrupted() async {
    final List<Map<String, dynamic>> toProcess = List.from(
      _corruptedCollections,
    );
    for (var data in toProcess) {
      await reSignCollection(data);
    }
  }

  Future<void> discardCorruptedCollection(String id) async {
    try {
      await _repository.delete(id);
      _corruptedCollections.removeWhere((c) => c['id'] == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao descartar coleção corrompida: $e');
    }
  }

  void moveRequest({
    required String requestId,
    required String sourceCollectionId,
    required String targetCollectionId,
    String? targetRequestId,
  }) {
    final sourceIdx = _collections.indexWhere(
      (c) => c.id == sourceCollectionId,
    );
    final targetIdx = _collections.indexWhere(
      (c) => c.id == targetCollectionId,
    );

    if (sourceIdx == -1 || targetIdx == -1) return;

    final sourceColl = _collections[sourceIdx];
    final targetColl = _collections[targetIdx];

    final reqIdx = sourceColl.requests.indexWhere((r) => r.id == requestId);
    if (reqIdx == -1) return;

    final request = sourceColl.requests.removeAt(reqIdx);

    if (targetRequestId != null) {
      final targetReqIdx = targetColl.requests.indexWhere(
        (r) => r.id == targetRequestId,
      );
      if (targetReqIdx != -1) {
        targetColl.requests.insert(targetReqIdx, request);
      } else {
        targetColl.requests.add(request);
      }
    } else {
      targetColl.requests.add(request);
    }

    _saveCollections();
    notifyListeners();
  }

  void duplicateRequest(String collectionId, HttpRequest request) {
    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx == -1) return;

    final collection = _collections[idx];
    final reqIdx = collection.requests.indexWhere((r) => r.id == request.id);
    if (reqIdx == -1) return;

    final duplicated = HttpRequest(
      name: '${request.name} Copy',
      method: request.method,
      url: request.url,
      queryParams: Map<String, String>.from(request.queryParams),
      headers: Map<String, String>.from(request.headers),
      body: request.body,
      bodyType: request.bodyType,
      formData: request.formData.map((e) => e.copyWith()).toList(),
      binaryPath: request.binaryPath,
    );

    collection.requests.insert(reqIdx + 1, duplicated);
    _saveCollections();
    notifyListeners();
  }

  void renameRequest(String collectionId, String requestId, String newName) {
    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx == -1) return;

    final collection = _collections[idx];
    final reqIdx = collection.requests.indexWhere((r) => r.id == requestId);
    if (reqIdx == -1) return;

    collection.requests[reqIdx] = collection.requests[reqIdx].copyWith(
      name: newName,
    );

    if (_selectedRequest?.id == requestId) {
      _selectedRequest = collection.requests[reqIdx];
    }

    _saveCollections();
    notifyListeners();
  }



  String _interpolate(String value, Map<String, String>? variables) {
    if (variables == null || variables.isEmpty) return value;
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    return value.replaceAllMapped(regex, (match) {
      final varName = match.group(1)?.trim() ?? '';
      return variables[varName] ?? '';
    });
  }

  Future<void> bulkImportPayloads({
    required List<MapEntry<String, HttpRequest>> newRequestsWithCollectionId,
    required List<HttpRequest> updatedRequests,
  }) async {
    // 1. Substituir os corpos nas requisições existentes
    for (var updated in updatedRequests) {
      for (var col in _collections) {
        final idx = col.requests.indexWhere((r) => r.id == updated.id);
        if (idx != -1) {
          col.requests[idx] = updated;
          if (_selectedRequest?.id == updated.id) {
            _selectedRequest = updated;
          }
          break;
        }
      }
    }

    // 2. Adicionar novas requisições às coleções de destino
    for (var entry in newRequestsWithCollectionId) {
      final collectionId = entry.key;
      final request = entry.value;
      final colIdx = _collections.indexWhere((c) => c.id == collectionId);
      if (colIdx != -1) {
        _collections[colIdx].requests.add(request);
      }
    }

    // 3. Salvar tudo uma única vez e notificar a UI
    await _saveCollections();
    notifyListeners();
  }

  Future<String?> fetchOAuth2Token({
    required String tokenUrl,
    required String grantType,
    required String clientId,
    required String clientSecret,
    required String scope,
    required String username,
    required String password,
    Map<String, String>? variables,
  }) async {
    final dio = Dio();
    try {
      final interpolatedUrl = _interpolate(tokenUrl, variables).trim();
      final interpolatedGrantType = _interpolate(grantType, variables).trim();
      final interpolatedClientId = _interpolate(clientId, variables).trim();
      final interpolatedClientSecret = _interpolate(
        clientSecret,
        variables,
      ).trim();
      final interpolatedScope = _interpolate(scope, variables).trim();
      final interpolatedUsername = _interpolate(username, variables).trim();
      final interpolatedPassword = _interpolate(password, variables).trim();

      if (interpolatedUrl.isEmpty) {
        throw Exception('Token URL is empty');
      }

      final data = <String, String>{'grant_type': interpolatedGrantType};

      if (interpolatedClientId.isNotEmpty) {
        data['client_id'] = interpolatedClientId;
      }
      if (interpolatedClientSecret.isNotEmpty) {
        data['client_secret'] = interpolatedClientSecret;
      }
      if (interpolatedScope.isNotEmpty) {
        data['scope'] = interpolatedScope;
      }

      if (interpolatedGrantType == 'password') {
        if (interpolatedUsername.isNotEmpty) {
          data['username'] = interpolatedUsername;
        }
        if (interpolatedPassword.isNotEmpty) {
          data['password'] = interpolatedPassword;
        }
      }

      final Map<String, dynamic> headers = {
        Headers.contentTypeHeader: Headers.formUrlEncodedContentType,
      };

      final response = await dio.post(
        interpolatedUrl,
        data: data,
        options: Options(headers: headers, validateStatus: (status) => true),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        dynamic responseData = response.data;
        if (responseData is String) {
          try {
            responseData = jsonDecode(responseData);
          } catch (_) {}
        }
        if (responseData is Map) {
          return responseData['access_token']?.toString();
        }
        throw Exception('Unexpected token response: $responseData');
      } else {
        throw Exception(
          'Token request failed: ${response.statusCode} ${response.statusMessage}\n${response.data}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching OAuth2 token: $e');
      rethrow;
    }
  }
}
