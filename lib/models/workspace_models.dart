enum WorkspaceItemType { folder, request }

class WorkspaceModel {
  final String id;
  String name;
  String icon;
  List<EnvironmentModel> environments = [];
  String? selectedEnvironmentId;

  WorkspaceModel({
    required this.name,
    String? id,
    List<EnvironmentModel>? environments,
    this.selectedEnvironmentId,
    this.icon = 'folder',
  }) : id = id ?? "ws_${DateTime.now().microsecondsSinceEpoch}",
       environments = environments ?? [EnvironmentModel(name: 'Default')];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'environments': environments.map((e) => e.toMap()).toList(),
      'selectedEnvironmentId': selectedEnvironmentId,
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
      id: map['id'],
      icon: map['icon'],
      environments: loadedEnvs,
      selectedEnvironmentId: map['selectedEnvironmentId'],
    );
  }
}

class EnvironmentModel {
  final String id;
  String name;
  Map<String, WorkspaceSecretKey> variables;

  EnvironmentModel({
    String? id,
    required this.name,
    Map<String, WorkspaceSecretKey>? variables,
  }) : id = id ?? "env_${DateTime.now().microsecondsSinceEpoch}",
       variables = variables ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
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
