import 'package:flutter_test/flutter_test.dart';
import 'package:fletch/models/collection_model.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/models/http_request.dart';
import 'package:fletch/widgets/body_editor.dart';
import 'package:fletch/utils/converters/format_detector.dart';
import 'package:fletch/utils/converters/postman_converter.dart';
import 'package:fletch/utils/converters/insomnia_converter.dart';
import 'package:fletch/utils/converters/yaml_helper.dart';

void main() {
  group('FormatDetector Tests', () {
    test('detects Native format correctly', () {
      final nativeJson = [
        {
          'id': 'coll-1',
          'name': 'Native Collection',
          'workspaceId': 'ws-1',
          'requests': []
        }
      ];
      expect(FormatDetector.detect(nativeJson), equals(CollectionFormat.native));
    });

    test('detects Postman format correctly', () {
      final postmanJson = {
        'info': {
          'name': 'My Collection',
          'schema': 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json'
        },
        'item': []
      };
      expect(FormatDetector.detect(postmanJson), equals(CollectionFormat.postman));
    });

    test('detects Insomnia format correctly', () {
      final insomniaJson = {
        '_type': 'export',
        '__export_format': 4,
        'resources': []
      };
      expect(FormatDetector.detect(insomniaJson), equals(CollectionFormat.insomnia));
    });
  });

  group('PostmanConverter Tests', () {
    test('imports Postman v2.1 collections correctly', () {
      final postmanJson = {
        'info': {
          'name': 'Postman Test',
          'description': 'Test collection'
        },
        'item': [
          {
            'name': 'Sub Folder',
            'item': [
              {
                'name': 'GET Request',
                'request': {
                  'method': 'GET',
                  'header': [
                    {'key': 'Content-Type', 'value': 'application/json'}
                  ],
                  'url': {
                    'raw': 'https://api.example.com/users?page=2',
                    'query': [
                      {'key': 'page', 'value': '2'}
                    ]
                  }
                }
              }
            ]
          }
        ]
      };

      final result = PostmanConverter.importCollection(postmanJson, 'test-ws');
      expect(result.length, equals(2)); // root collection + sub folder

      final root = result.firstWhere((c) => c.parentId == null);
      expect(root.name, equals('Postman Test'));

      final subFolder = result.firstWhere((c) => c.parentId == root.id);
      expect(subFolder.name, equals('Sub Folder'));
      expect(subFolder.requests.length, equals(1));

      final req = subFolder.requests.first;
      expect(req.name, equals('GET Request'));
      expect(req.method, equals(HttpMethod.get));
      expect(req.url, equals('https://api.example.com/users?page=2'));
      expect(req.headers['Content-Type'], equals('application/json'));
      expect(req.queryParams['page'], equals('2'));
    });

    test('exports to Postman collection correctly', () {
      final root = RequestCollection(
        id: 'root-id',
        name: 'Root Folder',
        workspaceId: 'test-ws',
      );
      final sub = RequestCollection(
        id: 'sub-id',
        name: 'Sub Folder',
        workspaceId: 'test-ws',
        parentId: 'root-id',
      );
      final req = HttpRequest(
        name: 'POST req',
        method: HttpMethod.post,
        url: 'https://example.com',
        headers: {'Authorization': 'Bearer token'},
      );
      sub.requests.add(req);

      final exported = PostmanConverter.exportCollection([root, sub], 'My Workspace');
      expect(exported['info']['name'], equals('Workspace - My Workspace'));
      expect(exported['item'].length, equals(1)); // Root folder is top level

      final rootFolderJson = exported['item'][0];
      expect(rootFolderJson['name'], equals('Root Folder'));
      expect(rootFolderJson['item'].length, equals(1)); // Sub folder inside root

      final subFolderJson = rootFolderJson['item'][0];
      expect(subFolderJson['name'], equals('Sub Folder'));
      expect(subFolderJson['item'].length, equals(1)); // Request inside sub folder

      final reqJson = subFolderJson['item'][0];
      expect(reqJson['name'], equals('POST req'));
      expect(reqJson['request']['method'], equals('POST'));
      expect(reqJson['request']['url']['raw'], equals('https://example.com'));
    });
  });

  group('InsomniaConverter Tests', () {
    test('imports Insomnia v4 collections correctly', () {
      final insomniaJson = {
        '_type': 'export',
        '__export_format': 4,
        'resources': [
          {
            '_id': 'wrk_1',
            '_type': 'workspace',
            'name': 'Insomnia Workspace',
          },
          {
            '_id': 'fld_1',
            'parentId': 'wrk_1',
            '_type': 'request_group',
            'name': 'Root Folder',
          },
          {
            '_id': 'req_1',
            'parentId': 'fld_1',
            '_type': 'request',
            'name': 'GET Request',
            'method': 'GET',
            'url': 'https://api.example.com',
            'headers': [
              {'name': 'Accept', 'value': '*/*'}
            ]
          }
        ]
      };

      final result = InsomniaConverter.importCollection(insomniaJson, 'test-ws');
      expect(result.length, equals(1)); // 1 folder (request_group)

      final folder = result.first;
      expect(folder.id, equals('fld_1'));
      expect(folder.name, equals('Root Folder'));
      expect(folder.parentId, isNull); // Points to workspace in Insomnia, so is root level in our model
      expect(folder.requests.length, equals(1));

      final req = folder.requests.first;
      expect(req.name, equals('GET Request'));
      expect(req.method, equals(HttpMethod.get));
      expect(req.url, equals('https://api.example.com'));
      expect(req.headers['Accept'], equals('*/*'));
    });

    test('exports to Insomnia export format correctly', () {
      final root = RequestCollection(
        id: 'root-id',
        name: 'Root Folder',
        workspaceId: 'test-ws',
      );
      final req = HttpRequest(
        id: 'req-id',
        name: 'PATCH req',
        method: HttpMethod.patch,
        url: 'https://example.com',
      );
      root.requests.add(req);

      final exported = InsomniaConverter.exportCollection([root], 'test-ws', 'My Workspace');
      expect(exported['_type'], equals('export'));
      expect(exported['__export_format'], equals(4));

      final resources = exported['resources'] as List;
      expect(resources.length, equals(3)); // Workspace, request_group, request

      final workspaceRes = resources.firstWhere((r) => r['_type'] == 'workspace');
      expect(workspaceRes['name'], equals('My Workspace'));

      final folderRes = resources.firstWhere((r) => r['_type'] == 'request_group');
      expect(folderRes['_id'], equals('root-id'));
      expect(folderRes['name'], equals('Root Folder'));
      expect(folderRes['parentId'], equals(workspaceRes['_id']));

      final requestRes = resources.firstWhere((r) => r['_type'] == 'request');
      expect(requestRes['_id'], equals('req-id'));
      expect(requestRes['name'], equals('PATCH req'));
      expect(requestRes['parentId'], equals('root-id'));
      expect(requestRes['method'], equals('PATCH'));
    });

    test('imports Insomnia v5 YAML format correctly', () {
      final yamlContent = '''
_type: export
__export_format: 4
resources:
  - _id: wrk_1
    _type: workspace
    name: Insomnia Workspace
  - _id: fld_1
    parentId: wrk_1
    _type: request_group
    name: Root Folder
  - _id: req_1
    parentId: fld_1
    _type: request
    name: GET Request
    method: GET
    url: https://api.example.com
    headers:
      - name: Accept
        value: "*/*"
''';
      final decoded = YamlHelper.parse(yamlContent);
      final result = InsomniaConverter.importCollection(decoded, 'test-ws');
      expect(result.length, equals(1));

      final folder = result.first;
      expect(folder.id, equals('fld_1'));
      expect(folder.name, equals('Root Folder'));
      expect(folder.requests.length, equals(1));

      final req = folder.requests.first;
      expect(req.name, equals('GET Request'));
      expect(req.url, equals('https://api.example.com'));
    });

    test('exports to Insomnia v5 YAML format correctly', () {
      final root = RequestCollection(
        id: 'root-id',
        name: 'Root Folder',
        workspaceId: 'test-ws',
      );
      final req = HttpRequest(
        id: 'req-id',
        name: 'GET req',
        method: HttpMethod.get,
        url: 'https://example.com',
        body: '{\n  "key": "value"\n}',
        bodyType: BodyType.json,
      );
      root.requests.add(req);

      final exportedMap = InsomniaConverter.exportCollection(
        [root],
        'test-ws',
        'My Workspace',
        exportFormat: 5,
      );

      final yamlStr = YamlHelper.toYaml(exportedMap);
      expect(yamlStr, contains('__export_format: 5'));
      expect(yamlStr, contains('name: My Workspace'));
      expect(yamlStr, contains('text:'));

      // Check roundtrip parse
      final parsed = YamlHelper.parse(yamlStr);
      expect(parsed['_type'], equals('export'));
      expect(parsed['__export_format'], equals(5));

      final imported = InsomniaConverter.importCollection(parsed, 'new-ws');
      expect(imported.length, equals(1));
      expect(imported[0].name, equals('Root Folder'));
      expect(imported[0].requests[0].body, equals('{\n  "key": "value"\n}'));
    });
  });

  group('YamlHelper.toYaml Tests', () {
    test('serializes maps and lists correctly', () {
      final data = {
        'a': 1,
        'b': 'simple string',
        'c': 'string with : and # and [ ]',
        'd': true,
        'e': null,
        'list': [
          'item1',
          {'nestedKey': 'nestedValue'}
        ]
      };
      final yaml = YamlHelper.toYaml(data);
      final parsed = YamlHelper.parse(yaml);
      expect(parsed['a'], equals(1));
      expect(parsed['b'], equals('simple string'));
      expect(parsed['c'], equals('string with : and # and [ ]'));
      expect(parsed['d'], equals(true));
      expect(parsed['e'], isNull);
      expect(parsed['list'][0], equals('item1'));
      expect(parsed['list'][1]['nestedKey'], equals('nestedValue'));
    });
  });
}
