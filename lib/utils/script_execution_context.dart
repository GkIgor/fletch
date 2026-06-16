import 'dart:convert';

/// Lightweight reference to a workspace HttpRequest — only the fields needed
/// by the JIT compiler to resolve a SendRequestStep with requestId.
/// Using a slim DTO avoids loading full request bodies into the canvas's RAM.
class WorkspaceRequestRef {
  final String id;
  final String name;
  final String method;
  final String url;
  final Map<String, String> headers;
  final String? body;

  const WorkspaceRequestRef({
    required this.id,
    required this.name,
    required this.method,
    required this.url,
    required this.headers,
    this.body,
  });
}

enum LogLevel { info, warn, error, debug }

class ExecutionLog {
  final DateTime timestamp;
  final LogLevel level;
  final String nodeId;
  final String nodeName;
  final String message;

  ExecutionLog({
    required this.timestamp,
    required this.level,
    required this.nodeId,
    required this.nodeName,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'nodeId': nodeId,
        'nodeName': nodeName,
        'message': message,
      };
}

class ExecutionResult {
  final bool success;
  final String? nextNodeId;
  final String? error;

  ExecutionResult({
    required this.success,
    this.nextNodeId,
    this.error,
  });
}

/// Isolation context for visual script executions.
class ExecutionContext {
  final Map<String, String> variables;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  String url;
  String? body;
  
  // Response metadata (available in post-response scripts)
  int statusCode;
  String? responseBody;
  Map<String, String> responseHeaders;

  // HTTP execution callback
  Future<Map<String, dynamic>> Function(String method, String url, Map<String, String> headers, String? body)? httpExecutor;

  // Execution logs
  final List<ExecutionLog> logs = [];

  // JSON decode cache to avoid redundant parsing
  final Map<String, dynamic> _jsonCache = {};

  ExecutionContext({
    Map<String, String>? variables,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    this.url = '',
    this.body,
    this.statusCode = 0,
    this.responseBody,
    Map<String, String>? responseHeaders,
  })  : variables = variables ?? {},
        headers = headers ?? {},
        queryParams = queryParams ?? {},
        responseHeaders = responseHeaders ?? {};

  dynamic getDecodedJson(String rawJson) {
    if (_jsonCache.containsKey(rawJson)) {
      return _jsonCache[rawJson];
    }
    try {
      final decoded = jsonDecode(rawJson);
      _jsonCache[rawJson] = decoded;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  void log(String nodeId, String nodeName, String message, {LogLevel level = LogLevel.info}) {
    logs.add(ExecutionLog(
      timestamp: DateTime.now(),
      level: level,
      nodeId: nodeId,
      nodeName: nodeName,
      message: message,
    ));
  }
}
