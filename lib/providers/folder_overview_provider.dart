import 'package:flutter/material.dart';
import 'package:gk_http_client/models/collection_model.dart';
import 'package:gk_http_client/models/workspace_models.dart';
import 'package:gk_http_client/repository/collection_repository.dart';

/// A lightweight record pairing a [RequestCollection] with its
/// originating [WorkspaceModel], used in the global folder overview.
class CollectionWithWorkspace {
  final RequestCollection collection;
  final WorkspaceModel workspace;

  const CollectionWithWorkspace({
    required this.collection,
    required this.workspace,
  });
}

class FolderOverviewProvider extends ChangeNotifier {
  final CollectionRepository _repository = CollectionRepository();

  List<CollectionWithWorkspace> _items = [];
  bool _isLoading = false;
  bool _isGrid = true;
  String _searchQuery = '';

  List<CollectionWithWorkspace> get items => _filteredItems;
  bool get isLoading => _isLoading;
  bool get isGrid => _isGrid;
  String get searchQuery => _searchQuery;

  List<CollectionWithWorkspace> get _filteredItems {
    if (_searchQuery.isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items.where((item) {
      return item.collection.name.toLowerCase().contains(q) ||
          item.workspace.name.toLowerCase().contains(q);
    }).toList();
  }

  /// Loads all collections across workspaces. Needs the current list of
  /// [workspaces] from [WorkspaceProvider] to resolve workspace metadata.
  Future<void> load(List<WorkspaceModel> workspaces) async {
    _isLoading = true;
    notifyListeners();

    try {
      final allCollections = await _repository.getAllGlobal();

      // Build a lookup map for O(1) workspace resolution.
      final Map<String, WorkspaceModel> wsMap = {
        for (final ws in workspaces) ws.id: ws,
      };

      _items = allCollections
          .where((c) => wsMap.containsKey(c.workspaceId))
          .map((c) => CollectionWithWorkspace(
                collection: c,
                workspace: wsMap[c.workspaceId]!,
              ))
          .toList()
        ..sort((a, b) => a.collection.name.compareTo(b.collection.name));
    } catch (e) {
      debugPrint('FolderOverviewProvider: erro ao carregar pastas: $e');
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleLayout() {
    _isGrid = !_isGrid;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
