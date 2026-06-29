import 'dart:convert';
import 'dart:io';

import 'package:fletch/core/app_config.dart';
import 'package:fletch/core/contracts/repository.dart';
import 'package:fletch/backend/workspace/models/workspace.dart';
import 'package:fletch/core/utils/security_utils.dart';

class WorkspaceRepository implements IRepository<WorkspaceModel> {
  final String _path = AppConfig.workspaceDir;

  Future<List<WorkspaceModel>> getAll() async {
    final dir = Directory(_path);

    if (!dir.existsSync()) {
      return [];
    }

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

  @override
  Future<void> save(WorkspaceModel ws) async {
    final Map<String, dynamic> map = ws.toMap();
    map.remove('signature');

    final String rawJson = jsonEncode(map);
    final String signature = SecurityUtils.generateDynamicHash(rawJson);

    map['signature'] = signature;

    final file = File('$_path/${ws.id}.json');
    await file.writeAsString(jsonEncode(map));
  }

  @override
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

  @override
  Future<void> delete(String id) async {
    final file = File('$_path/$id.json');
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
