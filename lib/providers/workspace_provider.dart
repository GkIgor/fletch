import 'package:flutter/material.dart';
import 'package:fletch/models/workspace_models.dart';
import 'package:fletch/repository/workspace_repository.dart';
import 'package:fletch/services/workspace_service.dart';

class WorkspaceProvider extends ChangeNotifier {
  final WorkspaceRepository _repository = WorkspaceRepository();
  final WorkspaceService _service = WorkspaceService();

  final Map<String, WorkspaceModel> _workspaces = {};

  bool isLoading = false;
  WorkspaceModel? _currentWorkspace;

  static const Map<String, IconData> icons = {
    'bolt': Icons.bolt_rounded,
    'api': Icons.api_rounded,
    'shield': Icons.shield_rounded,
    'package': Icons.inventory_2_rounded,
    'bar_chart': Icons.bar_chart_rounded,
    'search_activity': Icons.explore_rounded,
    'code': Icons.code_rounded,
    'cloud': Icons.cloud_rounded,
    'database': Icons.storage_rounded,
    'hub': Icons.hub_rounded,
    'terminal': Icons.terminal_rounded,
    'dns': Icons.dns_rounded,
    'deployed_code': Icons.layers_rounded,
    'security': Icons.security_rounded,
    'lock': Icons.lock_rounded,
    // Compatibility keys
    'analytics': Icons.analytics_rounded,
    'folder': Icons.folder_open_rounded,
    'language': Icons.language_rounded,
  };

  static const Map<String, Color> iconColors = {
    'bolt': Color(0xFF10B981),
    'api': Color(0xFF6366F1),
    'shield': Color(0xFF3B82F6),
    'package': Color(0xFF8B5CF6),
    'bar_chart': Color(0xFFEC4899),
    'search_activity': Color(0xFFF59E0B),
    'code': Color(0xFFEF4444),
    'cloud': Color(0xFF06B6D4),
    'database': Color(0xFF14B8A6),
    'hub': Color(0xFF6366F1),
    'terminal': Color(0xFF475569),
    'dns': Color(0xFF10B981),
    'deployed_code': Color(0xFF8B5CF6),
    'security': Color(0xFFF59E0B),
    'lock': Color(0xFFEC4899),
    // Compatibility keys
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

  bool _isManagingEnvironments = false;
  bool get isManagingEnvironments => _isManagingEnvironments;

  set isManagingEnvironments(bool value) {
    _isManagingEnvironments = value;
    if (value) {
      _isManagingAuth = false;
    }
    notifyListeners();
  }

  bool _isManagingAuth = false;
  bool get isManagingAuth => _isManagingAuth;

  set isManagingAuth(bool value) {
    _isManagingAuth = value;
    if (value) {
      _isManagingEnvironments = false;
    }
    notifyListeners();
  }

  void openWorkspace(String ws) {
    final workspace = _workspaces[ws];
    _currentWorkspace = workspace;
    _isManagingEnvironments = false;
    _isManagingAuth = false;
    notifyListeners();
  }

  Future<void> addEnvironmentWithNameAndDescription(String name, String description, String icon) async {
    if (_currentWorkspace != null) {
      final env = EnvironmentModel(name: name, description: description, icon: icon);
      _currentWorkspace!.environments.add(env);
      await _repository.save(_currentWorkspace!);
      notifyListeners();
    }
  }

  Future<void> updateEnvironmentDetails(String envId, String name, String description, String icon) async {
    if (_currentWorkspace != null) {
      final index = _currentWorkspace!.environments.indexWhere((e) => e.id == envId);
      if (index != -1) {
        _currentWorkspace!.environments[index].name = name;
        _currentWorkspace!.environments[index].description = description;
        _currentWorkspace!.environments[index].icon = icon;
        await _repository.save(_currentWorkspace!);
        notifyListeners();
      }
    }
  }

  Future<void> addOrUpdateVariable(String envId, String key, String newKey, WorkspaceSecretKey secretKey) async {
    if (_currentWorkspace != null) {
      try {
        final env = _currentWorkspace!.environments.firstWhere((e) => e.id == envId);
        if (key != newKey) {
          env.variables.remove(key);
        }
        env.variables[newKey] = secretKey;
        await _repository.save(_currentWorkspace!);
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> removeVariable(String envId, String key) async {
    if (_currentWorkspace != null) {
      try {
        final env = _currentWorkspace!.environments.firstWhere((e) => e.id == envId);
        env.variables.remove(key);
        await _repository.save(_currentWorkspace!);
        notifyListeners();
      } catch (_) {}
    }
  }
}
