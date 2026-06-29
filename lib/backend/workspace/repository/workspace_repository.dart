import 'dart:convert';

import 'package:fletch/core/app_config.dart';
import 'package:fletch/core/contracts/repository.dart';
import 'package:fletch/backend/workspace/models/workspace.dart';
import 'package:fletch/core/utils/security_utils.dart';
import 'package:fletch/core/repositories/generic_repository.dart';

class WorkspaceRepository implements IRepository<WorkspaceModel> {
  final String _path = AppConfig.workspaceDir;
  final GenericRepository _genericRepository;

  WorkspaceRepository({GenericRepository? genericRepository})
      : _genericRepository = genericRepository ?? GenericRepository();

  Future<List<WorkspaceModel>> getAll() async {
    final List<String> filePaths = await _genericRepository.listJsonFiles(_path);
    final List<WorkspaceModel> workspaces = [];

    for (var filePath in filePaths) {
      if (await _genericRepository.getFileSize(filePath) > 10 * 1024 * 1024) {
        continue;
      }

      try {
        final Map<String, dynamic>? map = await _genericRepository.readJson(filePath);
        if (map == null) continue;

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

    final filePath = '$_path/${ws.id}.json';
    await _genericRepository.writeJson(filePath, map);
  }

  @override
  Future<WorkspaceModel?> getById(String id) async {
    final filePath = '$_path/$id.json';
    try {
      final Map<String, dynamic>? map = await _genericRepository.readJson(filePath);
      if (map == null) return null;

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
    final filePath = '$_path/$id.json';
    await _genericRepository.delete(filePath);
  }
}
