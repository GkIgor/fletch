import 'package:flutter/material.dart';
import 'package:fletch/backend/collections/models/collection.dart';
import 'package:fletch/backend/requests/models/http_request.dart';
import 'package:fletch/backend/runner/models/runner_item_state.dart';
import 'package:fletch/backend/runner/models/runner_session.dart';
import 'package:fletch/backend/runner/use_cases/run_session.dart';
import 'package:fletch/backend/workspace/models/workspace.dart';
import 'package:fletch/backend/workspace/repository/workspace_repository.dart';
import 'package:fletch/backend/requests/services/http_service.dart';

class RunnerProvider extends ChangeNotifier {
  final HttpService _httpService;
  final WorkspaceRepository _workspaceRepository;
  late final RunSession _runSession;

  RunnerProvider({
    HttpService? httpService,
    WorkspaceRepository? workspaceRepository,
  })  : _httpService = httpService ?? HttpService(),
        _workspaceRepository = workspaceRepository ?? WorkspaceRepository() {
    _runSession = RunSession(
      httpClient: _httpService,
      workspaceRepository: _workspaceRepository,
    );
  }

  bool _isRunnerActive = false;
  bool _isRunningWorkspace = false;
  RequestCollection? _runnerCollection;
  List<RunnerItemState> _runnerItems = [];
  bool _isCurrentlyRunning = false;
  int _runnerCurrentIndex = -1;
  int _runnerDelayMs = 0;
  RunnerItemState? _selectedRunnerItem;
  RunnerSession? _activeSession;

  bool get isRunnerActive => _isRunnerActive;
  bool get isRunningWorkspace => _isRunningWorkspace;
  RequestCollection? get runnerCollection => _runnerCollection;
  List<RunnerItemState> get runnerItems => _runnerItems;
  bool get isCurrentlyRunning => _isCurrentlyRunning;
  int get runnerCurrentIndex => _runnerCurrentIndex;
  int get runnerDelayMs => _runnerDelayMs;
  RunnerItemState? get selectedRunnerItem => _selectedRunnerItem;

  List<HttpRequest> _gatherRequestsRecursively(String collectionId, List<RequestCollection> collections) {
    final List<HttpRequest> gathered = [];

    final collectionIdx = collections.indexWhere((c) => c.id == collectionId);
    if (collectionIdx != -1) {
      gathered.addAll(collections[collectionIdx].requests);
    }

    final children = collections
        .where((c) => c.parentId == collectionId)
        .toList();
    children.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (var child in children) {
      gathered.addAll(_gatherRequestsRecursively(child.id, collections));
    }

    return gathered;
  }

  List<HttpRequest> _gatherWorkspaceRequests(List<RequestCollection> collections) {
    final List<HttpRequest> gathered = [];
    final rootCollections = collections
        .where((c) => c.parentId == null)
        .toList();
    rootCollections.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (var root in rootCollections) {
      gathered.addAll(_gatherRequestsRecursively(root.id, collections));
    }

    return gathered;
  }

  void startCollectionRun(RequestCollection collection, List<RequestCollection> collections) {
    _isRunnerActive = true;
    _isRunningWorkspace = false;
    _runnerCollection = collection;

    final requests = _gatherRequestsRecursively(collection.id, collections);
    _runnerItems = requests
        .map((req) => RunnerItemState(request: req))
        .toList();
    _isCurrentlyRunning = false;
    _runnerCurrentIndex = -1;
    _selectedRunnerItem = null;
    _activeSession = null;
    notifyListeners();
  }

  void startWorkspaceRun(List<RequestCollection> collections) {
    _isRunnerActive = true;
    _isRunningWorkspace = true;
    _runnerCollection = null;

    final requests = _gatherWorkspaceRequests(collections);
    _runnerItems = requests
        .map((req) => RunnerItemState(request: req))
        .toList();
    _isCurrentlyRunning = false;
    _runnerCurrentIndex = -1;
    _selectedRunnerItem = null;
    _activeSession = null;
    notifyListeners();
  }

  void closeRunner() {
    _isRunnerActive = false;
    _isRunningWorkspace = false;
    _runnerCollection = null;
    _runnerItems = [];
    _isCurrentlyRunning = false;
    _runnerCurrentIndex = -1;
    _selectedRunnerItem = null;
    _activeSession = null;
    notifyListeners();
  }

  void setRunnerDelay(int ms) {
    _runnerDelayMs = ms;
    notifyListeners();
  }

  void selectRunnerItem(RunnerItemState? item) {
    _selectedRunnerItem = item;
    notifyListeners();
  }

  void setRunnerItemSelection(int index, bool selected) {
    if (index >= 0 && index < _runnerItems.length) {
      _runnerItems[index].isSelected = selected;
      notifyListeners();
    }
  }

  void toggleAllRunnerItems(bool selected) {
    for (var item in _runnerItems) {
      item.isSelected = selected;
    }
    notifyListeners();
  }

  void stopRunnerExecution() {
    _activeSession?.stopExecution = true;
    _isCurrentlyRunning = false;
    notifyListeners();
  }

  Future<void> executeRunnerSession({
    required List<RequestCollection> collections,
    required WorkspaceModel workspace,
    required Map<String, String> variables,
  }) async {
    if (_isCurrentlyRunning) return;
    _isCurrentlyRunning = true;

    final session = RunnerSession(
      id: 'session_${DateTime.now().microsecondsSinceEpoch}',
      items: _runnerItems,
      variables: variables,
      delayMs: _runnerDelayMs,
    );
    _activeSession = session;

    notifyListeners();

    await _runSession(
      session: session,
      collections: collections,
      workspace: workspace,
      onItemStart: (index) {
        _runnerCurrentIndex = index;
        notifyListeners();
      },
      onItemComplete: (index) {
        notifyListeners();
      },
      onSessionComplete: () async {
        if (workspace.environments.isNotEmpty) {
          final activeEnvId = workspace.selectedEnvironmentId;
          if (activeEnvId != null) {
            final envIdx = workspace.environments.indexWhere(
              (e) => e.id == activeEnvId,
            );
            if (envIdx != -1) {
              session.variables.forEach((key, val) {
                workspace.environments[envIdx].variables[key] = WorkspaceSecretKey(
                  value: val,
                );
              });
              try {
                await _workspaceRepository.save(workspace);
              } catch (saveError) {
                debugPrint('Aviso: Não foi possível salvar o Workspace no disco durante runner: $saveError');
              }
            }
          }
        }
        _isCurrentlyRunning = false;
        notifyListeners();
      },
    );
  }
}
