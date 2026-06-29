import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fletch/backend/collections/converters/yaml_helper.dart';
import 'package:fletch/backend/collections/converters/postman_converter.dart';
import 'package:fletch/backend/collections/converters/insomnia_converter.dart';
import 'package:fletch/backend/collections/converters/format_detector.dart';

void main() {
  group('Real-World Temp Files Parsing Tests', () {
    test('parses Pagar.me v5 postman collection', () {
      final file = File('temp/Pagar.me v5.postman_collection.json');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      final decoded = jsonDecode(content);

      final format = FormatDetector.detect(decoded);
      expect(format, equals(CollectionFormat.postman));

      final collections = PostmanConverter.importCollection(decoded, 'test-ws');
      expect(collections, isNotEmpty);

      int totalRequests = 0;
      for (var col in collections) {
        totalRequests += col.requests.length;
      }
      expect(totalRequests, greaterThan(0));
    });

    test('parses Insomnia_2026-05-22 yaml collection', () {
      final file = File('temp/Insomnia_2026-05-22.yaml');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      final decoded = YamlHelper.parse(content);

      final format = FormatDetector.detect(decoded);
      expect(format, equals(CollectionFormat.insomnia));

      final collections = InsomniaConverter.importCollection(
        decoded,
        'test-ws',
      );
      expect(collections, isNotEmpty);

      int totalRequests = 0;
      for (var col in collections) {
        totalRequests += col.requests.length;
      }
      expect(totalRequests, greaterThan(0));
    });
  });
}
