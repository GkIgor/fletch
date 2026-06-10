// Executor engine for visual scripts applying modifications dynamically (ExecutionContext & Inheritance resolution).
import '../models/collection_model.dart';
import '../models/http_request.dart';
import '../models/visual_script.dart';
import '../models/workspace_models.dart';
import 'script_compiler.dart';

class ScriptExecutor {
  /// Resolves scripts hierarchy: Workspace -> Collection -> Request.
  /// Collects active script models matching the configured ID lists.
  static List<VisualScript> resolveActiveScripts({
    required HttpRequest request,
    required List<RequestCollection> collections,
    required WorkspaceModel workspace,
    required bool isPreRequest,
  }) {
    final List<VisualScript> resolved = [];

    // 1. Gather lists based on inheritance checks
    List<String> wsScriptIds = workspace.activeScriptIds;
    List<String> colScriptIds = [];
    List<String> reqScriptIds = request.activeScriptIds;

    // Find the collection containing the request
    RequestCollection? collection;
    for (var col in collections) {
      if (col.requests.any((r) => r.id == request.id)) {
        collection = col;
        break;
      }
    }

    if (collection != null) {
      colScriptIds = collection.activeScriptIds;
      
      // If collection doesn't inherit, clear workspace level scripts
      if (!collection.inheritScripts) {
        wsScriptIds = [];
      }
    }

    // If request doesn't inherit, clear higher level scripts
    if (!request.inheritScripts) {
      wsScriptIds = [];
      colScriptIds = [];
    }

    // 2. Fetch script models from Workspace repository
    final allScriptModels = {for (var s in workspace.scripts) s.id: s};

    // Helper to add matching scripts
    void addScripts(List<String> ids) {
      for (var id in ids) {
        final script = allScriptModels[id];
        if (script != null && script.isPreRequest == isPreRequest) {
          resolved.add(script);
        }
      }
    }

    // Order: Workspace-wide first, then Collection, then Request-specific
    addScripts(wsScriptIds);
    addScripts(colScriptIds);
    addScripts(reqScriptIds);

    return resolved;
  }

  /// Runs active Pre-Request scripts and modifies query/header lists.
  static Future<ExecutionContext> executePreRequest({
    required HttpRequest request,
    required List<RequestCollection> collections,
    required WorkspaceModel workspace,
    required Map<String, String> initialVariables,
  }) async {
    final activePreScripts = resolveActiveScripts(
      request: request,
      collections: collections,
      workspace: workspace,
      isPreRequest: true,
    );

    final context = ExecutionContext(
      variables: Map<String, String>.from(initialVariables),
      headers: Map<String, String>.from(request.headers),
      queryParams: Map<String, String>.from(request.queryParams),
      url: request.url,
      body: request.body,
    );

    for (var script in activePreScripts) {
      final compiled = JitCache.getOrCreate(script);
      await compiled.execute(context);
    }

    return context;
  }

  /// Runs active Post-Response scripts, validating assertions and saving variables.
  static Future<void> executePostResponse({
    required HttpRequest request,
    required List<RequestCollection> collections,
    required WorkspaceModel workspace,
    required ExecutionContext context,
    required int statusCode,
    required String? responseBody,
    required Map<String, String> responseHeaders,
  }) async {
    final activePostScripts = resolveActiveScripts(
      request: request,
      collections: collections,
      workspace: workspace,
      isPreRequest: false,
    );

    context.statusCode = statusCode;
    context.responseBody = responseBody;
    context.responseHeaders = responseHeaders;

    for (var script in activePostScripts) {
      final compiled = JitCache.getOrCreate(script);
      await compiled.execute(context);
    }
  }
}
