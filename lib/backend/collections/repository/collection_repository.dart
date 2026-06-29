import 'dart:convert';

import 'package:fletch/core/app_config.dart';
import 'package:fletch/core/contracts/repository.dart';
import 'package:fletch/backend/collections/models/collection.dart';
import 'package:fletch/core/utils/security_utils.dart';
import 'package:fletch/core/repositories/generic_repository.dart';

class CollectionRepository implements IRepository<RequestCollection> {
  final String _path = AppConfig.collectionsDir;
  final GenericRepository _genericRepository;

  CollectionRepository({GenericRepository? genericRepository})
      : _genericRepository = genericRepository ?? GenericRepository();

  Future<List<RequestCollection>> getAll(String workspaceId) async {
    final List<String> filePaths = await _genericRepository.listJsonFiles(_path);
    final List<RequestCollection> collections = [];

    for (var filePath in filePaths) {
      if (await _genericRepository.getFileSize(filePath) > 10 * 1024 * 1024) {
        continue;
      }

      try {
        final Map<String, dynamic>? map = await _genericRepository.readJson(filePath);
        if (map == null) continue;

        if (map['workspaceId'] != workspaceId) continue;

        final String? fileSignature = map['signature'];

        final dataToValidate = Map<String, dynamic>.from(map)
          ..remove('signature');

        final String currentHash = SecurityUtils.generateDynamicHash(
          jsonEncode(dataToValidate),
        );

        if (fileSignature != currentHash) continue;

        collections.add(RequestCollection.fromJson(map));
      } catch (error) {
        continue;
      }
    }

    return collections;
  }

  @override
  Future<void> save(RequestCollection collection) async {
    final Map<String, dynamic> map = collection.toJson();
    map.remove('signature');

    final String rawJson = jsonEncode(map);
    final String signature = SecurityUtils.generateDynamicHash(rawJson);

    map['signature'] = signature;

    final filePath = '$_path/${collection.id}.json';
    await _genericRepository.writeJson(filePath, map);
  }

  Future<void> saveAll(List<RequestCollection> collections) async {
    for (var collection in collections) {
      await save(collection);
    }
  }

  @override
  Future<void> delete(String collectionId) async {
    final filePath = '$_path/$collectionId.json';
    await _genericRepository.delete(filePath);
  }

  Future<void> deleteAll(String workspaceId) async {
    final List<String> filePaths = await _genericRepository.listJsonFiles(_path);
    for (var filePath in filePaths) {
      if (await _genericRepository.getFileSize(filePath) > 10 * 1024 * 1024) {
        await _genericRepository.delete(filePath);
        continue;
      }

      try {
        final Map<String, dynamic>? map = await _genericRepository.readJson(filePath);
        if (map != null && map['workspaceId'] == workspaceId) {
          await _genericRepository.delete(filePath);
        }
      } catch (_) {
        // Ignora erros na exclusão em lote
      }
    }
  }

  Future<List<Map<String, dynamic>>> getCorruptedCollections(String workspaceId) async {
    final List<String> filePaths = await _genericRepository.listJsonFiles(_path);
    final List<Map<String, dynamic>> corrupted = [];

    for (var filePath in filePaths) {
      if (await _genericRepository.getFileSize(filePath) > 10 * 1024 * 1024) {
        continue;
      }

      try {
        final Map<String, dynamic>? map = await _genericRepository.readJson(filePath);
        if (map == null) continue;

        if (map['workspaceId'] != workspaceId) continue;

        final String? fileSignature = map['signature'];

        final dataToValidate = Map<String, dynamic>.from(map)
          ..remove('signature');

        final String currentHash = SecurityUtils.generateDynamicHash(
          jsonEncode(dataToValidate),
        );

        if (fileSignature != currentHash) {
          corrupted.add(map);
        }
      } catch (error) {
        continue;
      }
    }

    return corrupted;
  }

  @override
  Future<RequestCollection?> getById(String collectionId) async {
    final filePath = '$_path/$collectionId.json';
    try {
      final Map<String, dynamic>? map = await _genericRepository.readJson(filePath);
      if (map == null) return null;

      final String? fileSignature = map['signature'];

      final dataToValidate = Map<String, dynamic>.from(map)
        ..remove('signature');

      final String currentHash = SecurityUtils.generateDynamicHash(
        jsonEncode(dataToValidate),
      );

      if (fileSignature != currentHash) return null;

      return RequestCollection.fromJson(map);
    } catch (error) {
      return null;
    }
  }
}
