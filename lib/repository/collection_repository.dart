import 'dart:convert';
import 'dart:io';
import 'package:gk_http_client/core/app_config.dart';
import 'package:gk_http_client/models/collection_model.dart';
import 'package:gk_http_client/utils/utils.dart';

class CollectionRepository {
  final String _path = AppConfig.collectionsDir;

  Future<List<RequestCollection>> getAll(String workspaceId) async {
    final dir = Directory(_path);

    if (!dir.existsSync()) {
      return [];
    }

    final files = dir.listSync().where((f) => f.path.endsWith('.json'));
    final List<RequestCollection> collections = [];

    for (var entity in files) {
      final file = File(entity.path);

      if (file.statSync().size > 10 * 1024 * 1024) continue;

      try {
        final content = file.readAsStringSync();
        final Map<String, dynamic> map = jsonDecode(content);

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

  Future<void> save(RequestCollection collection) async {
    final Map<String, dynamic> map = collection.toJson();
    map.remove('signature');

    final String rawJson = jsonEncode(map);
    final String signature = SecurityUtils.generateDynamicHash(rawJson);

    map['signature'] = signature;

    final file = File('$_path/${collection.id}.json');
    await file.writeAsString(jsonEncode(map));
  }

  Future<void> saveAll(List<RequestCollection> collections) async {
    for (var collection in collections) {
      await save(collection);
    }
  }

  Future<void> delete(String collectionId) async {
    final file = File('$_path/$collectionId.json');
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<void> deleteAll(String workspaceId) async {
    final dir = Directory(_path);
    if (dir.existsSync()) {
      final files = dir.listSync().where((f) => f.path.endsWith('.json'));
      for (var entry in files) {
        final file = File(entry.path);

        if (file.statSync().size > 10 * 1024 * 1024) {
          await file.delete();
          continue;
        }

        if (jsonDecode(await file.readAsString())['workspaceId'] ==
            workspaceId) {
          await file.delete();
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> getCorruptedCollections(String workspaceId) async {
    final dir = Directory(_path);
    if (!dir.existsSync()) {
      return [];
    }

    final files = dir.listSync().where((f) => f.path.endsWith('.json'));
    final List<Map<String, dynamic>> corrupted = [];

    for (var entity in files) {
      final file = File(entity.path);

      if (file.statSync().size > 10 * 1024 * 1024) continue;

      try {
        final content = file.readAsStringSync();
        final Map<String, dynamic> map = jsonDecode(content);

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

  Future<RequestCollection?> getById(String collectionId) async {
    final file = File('$_path/$collectionId.json');

    if (!file.existsSync()) {
      return null;
    }

    try {
      final content = file.readAsStringSync();
      final Map<String, dynamic> map = jsonDecode(content);
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
