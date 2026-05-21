import 'dart:convert';
import 'dart:io';

import 'package:gk_http_client/core/app_config.dart';
import 'package:gk_http_client/models/workspace_models.dart';
import 'package:gk_http_client/utils/utils.dart';

class WorkspaceRepository {
  final String _path = AppConfig.workspaceDir;

  Future<List<WorkspaceModel>> getAll() async {
    final dir = Directory(_path);

    final files = dir.listSync().where((f) => f.path.endsWith('.json'));

    final List<WorkspaceModel> workspaces = [];

    for (var entity in files) {
      final file = File(entity.path);

      if (file.statSync().size > 10 * 1024 * 1024) continue;

      try {
        final content = file.readAsStringSync();
        final Map<String, dynamic> map = jsonDecode(content);
        final String? fileSignature = map['signature'];

        final dataToValidate = Map<String, dynamic>.from(map)
          ..remove('signature');

        final String currentHash = SecurityUtils.generateDynamicHash(
          jsonEncode(dataToValidate),
        );

        if (fileSignature != currentHash) continue;

        workspaces.add(WorkspaceModel.fromMap(map));
      } catch (error) {
        continue;
      }
    }

    return workspaces;
  }

  Future<void> save(WorkspaceModel ws) async {
    final Map<String, dynamic> map = ws.toMap();
    map.remove('signature');

    final String rawJson = jsonEncode(map);
    final String signature = SecurityUtils.generateDynamicHash(rawJson);

    map['signature'] = signature;

    final file = File('$_path/${ws.id}.json');
    await file.writeAsString(jsonEncode(map));
  }

  Future<WorkspaceModel?> getById(String id) async {
    final file = File('$_path/$id.json');
    if (!file.existsSync()) return null;
    try {
      final content = await file.readAsString();
      final Map<String, dynamic> map = jsonDecode(content);
      final String? fileSignature = map['signature'];

      final dataToValidate = Map<String, dynamic>.from(map)..remove('signature');
      final String currentHash = SecurityUtils.generateDynamicHash(jsonEncode(dataToValidate));

      if (fileSignature != currentHash) return null;
      return WorkspaceModel.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  Future<void> delete(String id) async {
    final file = File('$_path/$id.json');
    await file.delete();
  }
}
