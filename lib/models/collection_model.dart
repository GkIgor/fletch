import 'package:uuid/uuid.dart';
import 'http_request.dart';
import 'http_auth.dart';

class RequestCollection {
  final String id;
  final String icon;
  final String color;
  String? description;
  String name;
  bool isExpanded;
  List<HttpRequest> requests;
  String workspaceId;
  int sortOrder;
  String? parentId;
  final HttpAuth auth;
  final List<String> activeScriptIds;
  final bool inheritScripts;

  RequestCollection({
    String? id,
    required this.name,
    required this.workspaceId,
    List<HttpRequest>? requests,
    this.isExpanded = true,
    this.icon = 'folder',
    this.color = '#8b5cf6',
    this.description,
    this.sortOrder = 0,
    this.parentId,
    HttpAuth? auth,
    List<String>? activeScriptIds,
    this.inheritScripts = true,
  }) : id = id ?? const Uuid().v4(),
       requests = requests ?? [],
       auth = auth ?? HttpAuth(type: AuthType.inherit),
       activeScriptIds = activeScriptIds ?? [];

  void addRequest(HttpRequest request) {
    requests.add(request);
  }

  void removeRequest(String requestId) {
    requests.removeWhere((r) => r.id == requestId);
  }

  HttpRequest? findRequest(String requestId) {
    try {
      return requests.firstWhere((r) => r.id == requestId);
    } catch (e) {
      return null;
    }
  }

  RequestCollection copyWith({
    String? name,
    List<HttpRequest>? requests,
    bool? isExpanded,
    int? sortOrder,
    String? parentId,
    bool clearParentId = false,
    HttpAuth? auth,
    List<String>? activeScriptIds,
    bool? inheritScripts,
  }) {
    return RequestCollection(
      id: id,
      name: name ?? this.name,
      requests: requests ?? this.requests,
      isExpanded: isExpanded ?? this.isExpanded,
      workspaceId: workspaceId,
      icon: icon,
      color: color,
      description: description,
      sortOrder: sortOrder ?? this.sortOrder,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      auth: auth ?? this.auth,
      activeScriptIds: activeScriptIds ?? this.activeScriptIds,
      inheritScripts: inheritScripts ?? this.inheritScripts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'requests': requests.map((r) => r.toJson()).toList(),
      'isExpanded': isExpanded,
      'workspaceId': workspaceId,
      'icon': icon,
      'color': color,
      'description': description,
      'sortOrder': sortOrder,
      'parentId': parentId,
      'auth': auth.toJson(),
      'activeScriptIds': activeScriptIds,
      'inheritScripts': inheritScripts,
    };
  }

  factory RequestCollection.fromJson(Map<String, dynamic> json) {
    return RequestCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      workspaceId: json['workspaceId'] as String,
      requests: (json['requests'] as List)
          .map((r) => HttpRequest.fromJson(r as Map<String, dynamic>))
          .toList(),
      isExpanded: json['isExpanded'] as bool? ?? true,
      icon: json['icon'] as String? ?? 'folder',
      color: json['color'] as String? ?? '#8b5cf6',
      description: json['description'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      parentId: json['parentId'] as String?,
      auth: json['auth'] != null
          ? HttpAuth.fromJson(Map<String, dynamic>.from(json['auth']))
          : HttpAuth(type: AuthType.inherit),
      activeScriptIds: json['activeScriptIds'] != null
          ? List<String>.from(json['activeScriptIds'])
          : [],
      inheritScripts: json['inheritScripts'] as bool? ?? true,
    );
  }
}
