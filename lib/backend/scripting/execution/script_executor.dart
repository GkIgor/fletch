// Executor engine for visual scripts applying modifications dynamically (ExecutionContext & JIT compiler resolution).
import 'dart:convert';
import 'package:fletch/backend/collections/models/collection.dart';
import 'package:fletch/backend/requests/models/http_request.dart';
import 'package:fletch/backend/requests/models/http_method.dart';
import 'package:fletch/backend/scripting/models/visual_script.dart';
import 'package:fletch/backend/workspace/models/workspace.dart';
import 'package:fletch/backend/requests/models/http_auth.dart';
import 'package:fletch/backend/requests/services/http_service.dart';
import 'package:fletch/backend/scripting/compiler/script_compiler.dart';
import 'package:fletch/backend/requests/auth/auth_resolver.dart';

final _httpService = HttpService();

void _injectHttpExecutor(ExecutionContext context) {
  context.httpExecutor = (method, url, headers, body) async {
    final httpMethod = HttpMethod.values.firstWhere(
      (m) => m.value.toUpperCase() == method.toUpperCase(),
      orElse: () => HttpMethod.get,
    );
    final req = HttpRequest(
      name: 'Secondary Request',
      method: httpMethod,
      url: url,
      headers: headers,
      body: body,
      auth: HttpAuth(type: AuthType.none),
    );
    final res = await _httpService.send(req, variables: context.variables);
    return {
      'statusCode': res.statusCode,
      'body': res.body is String ? res.body : jsonEncode(res.body),
      'headers': res.headers.map((k, v) => MapEntry(k, v.toString())),
    };
  };
}

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

    _injectHttpExecutor(context);

    final availableRequests = collections
        .expand((c) => c.requests)
        .map((r) {
          final resolvedAuth = AuthResolver.resolveAuth(
            request: r,
            collections: collections,
            workspaceAuth: workspace.auth,
          );
          return WorkspaceRequestRef(
            id: r.id,
            name: r.name,
            method: r.method.value,
            url: r.url,
            headers: r.headers,
            body: r.body,
            resolvedAuth: resolvedAuth,
          );
        })
        .toList();

    for (var script in activePreScripts) {
      final compiled = JitCache.getOrCreate(script, availableRequests: availableRequests);
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

    _injectHttpExecutor(context);

    final availableRequests = collections
        .expand((c) => c.requests)
        .map((r) {
          final resolvedAuth = AuthResolver.resolveAuth(
            request: r,
            collections: collections,
            workspaceAuth: workspace.auth,
          );
          return WorkspaceRequestRef(
            id: r.id,
            name: r.name,
            method: r.method.value,
            url: r.url,
            headers: r.headers,
            body: r.body,
            resolvedAuth: resolvedAuth,
          );
        })
        .toList();

    for (var script in activePostScripts) {
      final compiled = JitCache.getOrCreate(script, availableRequests: availableRequests);
      await compiled.execute(context);
    }
  }
}
