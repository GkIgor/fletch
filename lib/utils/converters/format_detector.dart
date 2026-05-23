enum CollectionFormat { native, postman, insomnia, unknown }

class FormatDetector {
  static CollectionFormat detect(dynamic json) {
    if (json is List) {
      if (json.isEmpty) return CollectionFormat.native;
      final first = json.first;
      if (first is Map && (first.containsKey('workspaceId') || first.containsKey('requests'))) {
        return CollectionFormat.native;
      }
    } else if (json is Map) {
      if ((json.containsKey('resources') && json.containsKey('__export_format')) ||
          (json.containsKey('type') && (json['type'] as String).contains('insomnia')) ||
          (json.containsKey('collection') && json.containsKey('schema_version'))) {
        return CollectionFormat.insomnia;
      }
      if (json.containsKey('info') && (json['info'] as Map).containsKey('schema')) {
        final schema = json['info']['schema'] as String;
        if (schema.contains('postman.com')) {
          return CollectionFormat.postman;
        }
      }
      if (json.containsKey('item') && json.containsKey('info')) {
        return CollectionFormat.postman;
      }
    }
    return CollectionFormat.unknown;
  }
}
