import 'package:uuid/uuid.dart';
import 'http_request.dart';

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
  }) : id = id ?? const Uuid().v4(),
       requests = requests ?? [];

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
    };
  }

  factory RequestCollection.fromJson(Map<String, dynamic> json) {
    return RequestCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      requests: (json['requests'] as List)
          .map((r) => HttpRequest.fromJson(r as Map<String, dynamic>))
          .toList(),
      isExpanded: json['isExpanded'] as bool? ?? true,
      workspaceId: json['workspaceId'] as String,
      icon: json['icon'] as String? ?? 'folder',
      color: json['color'] as String? ?? '#8b5cf6',
      description: json['description'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
