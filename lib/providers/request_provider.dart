import 'package:flutter/material.dart';
import 'package:gk_http_client/models/http_request.dart';
import 'package:gk_http_client/models/http_response.dart';
import 'package:gk_http_client/models/collection_model.dart';

import 'package:gk_http_client/repository/collection_repository.dart';
import 'package:gk_http_client/repository/workspace_repository.dart';
import 'package:gk_http_client/theme/app_colors.dart';
import 'package:gk_http_client/services/http_service.dart';

class RequestProvider with ChangeNotifier {
  final CollectionRepository _repository = CollectionRepository();
  final HttpService _httpService = HttpService();

  List<RequestCollection> _collections = [];

  HttpRequest? _selectedRequest;

  HttpResponse? _currentResponse;

  bool _isLoading = false;

  String _searchFilter = '';
  
  String? _workspaceId;

  List<Map<String, dynamic>> _corruptedCollections = [];

  List<RequestCollection> get collections => _collections;
  List<Map<String, dynamic>> get corruptedCollections => _corruptedCollections;
  HttpRequest? get selectedRequest => _selectedRequest;
  HttpResponse? get currentResponse => _currentResponse;
  bool get isLoading => _isLoading;
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
    final collectionWithSortOrder = collection.copyWith(sortOrder: maxSortOrder + 1);
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

  Future<void> executeRequest(HttpRequest request, {Map<String, String>? variables}) async {
    _isLoading = true;
    _currentResponse = null;
    notifyListeners();

    try {
      final response = await _httpService.send(request, variables: variables);
      _currentResponse = response;
    } catch (e) {
      debugPrint('Erro inesperado ao enviar requisição: $e');
      _currentResponse = HttpResponse(
        statusCode: 0,
        statusMessage: 'Error',
        headers: {},
        body: e.toString(),
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

    _corruptedCollections = await _repository.getCorruptedCollections(workspaceId);

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
      final totalRequests = _collections.fold<int>(0, (sum, c) => sum + c.requests.length);
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

  Future<void> importCollections(List<Map<String, dynamic>> data, String workspaceId) async {
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

  void reorderCollections(String draggedId, String targetId, {bool before = true}) {
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
        _collections[parentIdx] = _collections[parentIdx].copyWith(isExpanded: true);
      }

      _saveCollections();
      notifyListeners();
    }
  }

  Future<void> createSubCollection(String parentCollectionId, String name) async {
    final parentIdx = _collections.indexWhere((c) => c.id == parentCollectionId);
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
    final List<Map<String, dynamic>> toProcess = List.from(_corruptedCollections);
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
    final sourceIdx = _collections.indexWhere((c) => c.id == sourceCollectionId);
    final targetIdx = _collections.indexWhere((c) => c.id == targetCollectionId);

    if (sourceIdx == -1 || targetIdx == -1) return;

    final sourceColl = _collections[sourceIdx];
    final targetColl = _collections[targetIdx];

    final reqIdx = sourceColl.requests.indexWhere((r) => r.id == requestId);
    if (reqIdx == -1) return;

    final request = sourceColl.requests.removeAt(reqIdx);

    if (targetRequestId != null) {
      final targetReqIdx = targetColl.requests.indexWhere((r) => r.id == targetRequestId);
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

    collection.requests[reqIdx] = collection.requests[reqIdx].copyWith(name: newName);

    if (_selectedRequest?.id == requestId) {
      _selectedRequest = collection.requests[reqIdx];
    }

    _saveCollections();
    notifyListeners();
  }
}
