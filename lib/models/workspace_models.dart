import 'http_auth.dart';

enum WorkspaceItemType { folder, request }

class WorkspaceModel {
  final String id;
  String name;
  String description;
  String icon;
  List<EnvironmentModel> environments = [];
  String? selectedEnvironmentId;
  final DateTime createdAt;
  int requestCount;
  HttpAuth auth;

  WorkspaceModel({
    required this.name,
    this.description = '',
    String? id,
    List<EnvironmentModel>? environments,
    this.selectedEnvironmentId,
    this.icon = 'folder',
    DateTime? createdAt,
    this.requestCount = 0,
    HttpAuth? auth,
  }) : id = id ?? "ws_${DateTime.now().microsecondsSinceEpoch}",
       createdAt = createdAt ?? DateTime.now(),
       environments = environments ?? [EnvironmentModel(name: 'Default')],
       auth = auth ?? HttpAuth(type: AuthType.none);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'environments': environments.map((e) => e.toMap()).toList(),
      'selectedEnvironmentId': selectedEnvironmentId,
      'createdAt': createdAt.toIso8601String(),
      'requestCount': requestCount,
      'auth': auth.toJson(),
    };
  }

  factory WorkspaceModel.fromMap(Map<String, dynamic> map) {
    final dynamic envList = map['environments'];

    List<EnvironmentModel> loadedEnvs = [];

    if (envList != null && envList is List) {
      loadedEnvs = envList.map((e) => EnvironmentModel.fromMap(Map<String, dynamic>.from(e))).toList();
    }

    if (loadedEnvs.isEmpty) {
      loadedEnvs.add(EnvironmentModel(name: 'Default'));
    }

    return WorkspaceModel(
      name: map['name'],
      description: map['description'] ?? '',
      id: map['id'],
      icon: map['icon'] ?? 'folder',
      environments: loadedEnvs,
      selectedEnvironmentId: map['selectedEnvironmentId'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      requestCount: map['requestCount'] ?? 0,
      auth: map['auth'] != null
          ? HttpAuth.fromJson(Map<String, dynamic>.from(map['auth']))
          : HttpAuth(type: AuthType.none),
    );
  }
}

class EnvironmentModel {
  final String id;
  String name;
  String description;
  String icon;
  Map<String, WorkspaceSecretKey> variables;

  EnvironmentModel({
    String? id,
    required this.name,
    this.description = '',
    this.icon = 'language',
    Map<String, WorkspaceSecretKey>? variables,
  }) : id = id ?? "env_${DateTime.now().microsecondsSinceEpoch}",
       variables = variables ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'variables': variables.map((k, v) => MapEntry(k, v.toMap())),
    };
  }

  factory EnvironmentModel.fromMap(Map<String, dynamic> map) {
    final dynamic varMap = map['variables'];
    Map<String, WorkspaceSecretKey> loadedVars = {};

    if (varMap != null && varMap is Map) {
      varMap.forEach((key, value) {
        loadedVars[key] = WorkspaceSecretKey.fromMap(Map<String, dynamic>.from(value));
      });
    }

    return EnvironmentModel(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      icon: map['icon'] ?? 'language',
      variables: loadedVars,
    );
  }
}

class WorkspaceSecretKey {
  late String value;
  late bool isSecret;

  WorkspaceSecretKey({required this.value, this.isSecret = false});

  WorkspaceSecretKey.fromMap(Map<String, dynamic> map) {
    value = map['value'];
    isSecret = map['isSecret'] ?? false;
  }

  Map<String, dynamic> toMap() => {'value': value, 'isSecret': isSecret};
}

class WorkspaceItem {
  final String id;
  String name;
  final WorkspaceItemType type;
  final List<WorkspaceItem> children;

  WorkspaceItem({
    required this.id,
    required this.name,
    required this.type,
    this.children = const [],
  });

  //TO-DO WorkspaceItem.fromMap

  //TO-DO toMap
}
