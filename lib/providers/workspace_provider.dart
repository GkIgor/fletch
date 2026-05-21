import 'package:flutter/material.dart';
import 'package:gk_http_client/models/workspace_models.dart';
import 'package:gk_http_client/repository/workspace_repository.dart';
import 'package:gk_http_client/services/workspace_service.dart';

class WorkspaceProvider extends ChangeNotifier {
  final WorkspaceRepository _repository = WorkspaceRepository();
  final WorkspaceService _service = WorkspaceService();

  final Map<String, WorkspaceModel> _workspaces = {};

  bool isLoading = false;
  WorkspaceModel? _currentWorkspace;

  static const Map<String, IconData> icons = {
    'bolt': Icons.bolt_rounded,
    'api': Icons.api_rounded,
    'security': Icons.security_rounded,
    'analytics': Icons.analytics_rounded,
    'folder': Icons.folder_open_rounded,
    'language': Icons.language_rounded,
  };

  static const Map<String, Color> iconColors = {
    'bolt': Color(0xFF10B981),
    'api': Color(0xFF6366F1),
    'security': Color(0xFFF59E0B),
    'analytics': Color(0xFFEF4444),
    'folder': Color(0xFF94A3B8),
    'language': Color(0xFF94A3B8),
  };

  List<WorkspaceModel> get workspaces => List.from(_workspaces.values);

  WorkspaceModel? get currentWorkspace => _currentWorkspace;

  Future<void> loadWorkspaces() async {
    isLoading = true;
    notifyListeners();

    final workspaces = await _repository.getAll();

    _workspaces.clear();
    for (var ws in workspaces) {
      _workspaces[ws.id] = ws;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> addWorkspace(WorkspaceModel ws) async {
    await _repository.save(ws);
    _workspaces[ws.id] = ws;
    notifyListeners();
  }

  Future<void> removeWorkspace(String workspace) async {
    await _service.removeWorkspace(workspace);
    _workspaces.remove(workspace);
    notifyListeners();
  }

  Future<void> updateWorkspaceIcon(String workspace, String icon) async {
    final ws = _workspaces[workspace];

    if (ws != null) {
      ws.icon = icon;
      _workspaces[workspace] = ws;
    }
    await _repository.save(ws!);

    notifyListeners();
  }

  Future<void> updateWorkspaceName(String workspaceId, String newName) async {
    final ws = _workspaces[workspaceId];

    if (ws != null) {
      ws.name = newName;
      await _repository.save(ws);
      notifyListeners();
    }
  }

  Future<void> selectEnvironment(String? environmentId) async {
    if (_currentWorkspace != null) {
      _currentWorkspace!.selectedEnvironmentId = environmentId;
      await _repository.save(_currentWorkspace!);
      notifyListeners();
    }
  }

  Future<void> addEnvironment(String name) async {
    if (_currentWorkspace != null) {
      final env = EnvironmentModel(name: name);
      _currentWorkspace!.environments.add(env);
      await _repository.save(_currentWorkspace!);
      notifyListeners();
    }
  }

  Future<void> removeEnvironment(String environmentId) async {
    if (_currentWorkspace != null) {
      _currentWorkspace!.environments.removeWhere((e) => e.id == environmentId);
      if (_currentWorkspace!.selectedEnvironmentId == environmentId) {
        _currentWorkspace!.selectedEnvironmentId = null;
      }
      await _repository.save(_currentWorkspace!);
      notifyListeners();
    }
  }

  EnvironmentModel? get activeEnvironment {
    if (_currentWorkspace == null) return null;
    if (_currentWorkspace!.selectedEnvironmentId == null) return null;
    try {
      return _currentWorkspace!.environments.firstWhere(
        (e) => e.id == _currentWorkspace!.selectedEnvironmentId,
      );
    } catch (e) {
      return null;
    }
  }

  void openWorkspace(String ws) {
    final workspace = _workspaces[ws];
    _currentWorkspace = workspace;
    notifyListeners();
  }
}
