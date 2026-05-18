import 'package:flutter/material.dart';
import 'package:gk_http_client/models/workspace_models.dart';
import 'package:gk_http_client/repository/workspace_repository.dart';
import 'package:gk_http_client/services/workspace_service.dart';
import 'package:gk_http_client/theme/app_colors.dart';

class WorkspaceProvider extends ChangeNotifier {
  final WorkspaceRepository _repository = WorkspaceRepository();
  final WorkspaceService _service = WorkspaceService();

  final Map<String, WorkspaceModel> _workspaces = {};

  bool isLoading = false;
  WorkspaceModel? _currentWorkspace;

  static const Map<String, IconData> icons = {
    'bolt': Icons.bolt,
    'folder': Icons.folder,
    'api': Icons.api,
    'security': Icons.security,
    'analytics': Icons.analytics,
  };

  static const Map<String, Color> iconColors = {
    'bolt': AppColors.primary,
    'folder': AppColors.primary,
    'api': AppColors.primary,
    'security': AppColors.primary,
    'analytics': AppColors.primary,
  };

  List<WorkspaceModel> get workspaces => List.from(_workspaces.values);

  WorkspaceModel? get currentWorkspace => _currentWorkspace;

  Future<void> loadWorkspaces() async {
    isLoading = true;
    notifyListeners();

    final workspaces = await _repository.getAll();

    for (var ws in workspaces) {
      _workspaces[ws.id] = ws;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> addWorkspace(WorkspaceModel ws) async {
    await _repository.save(ws);
    notifyListeners();
  }

  Future<void> removeWorkspace(String workspace) async {
    await _service.removeWorkspace(workspace);
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

    if (workspace != null) _workspaces.clear();

    _currentWorkspace = workspace;
  }
}
