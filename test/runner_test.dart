import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gk_http_client/core/app_config.dart';
import 'package:gk_http_client/models/collection_model.dart';
import 'package:gk_http_client/models/http_method.dart';
import 'package:gk_http_client/models/http_request.dart';
import 'package:gk_http_client/models/http_response.dart';
import 'package:gk_http_client/providers/request_provider.dart';
import 'package:gk_http_client/services/http_service.dart';

class MockHttpService extends HttpService {
  @override
  Future<HttpResponse> send(HttpRequest request, {Map<String, String>? variables}) async {
    if (request.url.contains('fail')) {
      return HttpResponse(
        statusCode: 500,
        statusMessage: 'Internal Server Error',
        headers: {},
        body: 'Failed',
        responseTime: 10,
        contentLength: 6,
      );
    }
    return HttpResponse(
      statusCode: 200,
      statusMessage: 'OK',
      headers: {'content-type': 'application/json'},
      body: '{"success": true}',
      responseTime: 15,
      contentLength: 17,
    );
  }
}

void main() {
  late Directory tempDir;
  late String originalWorkspaceDir;
  late String originalCollectionsDir;
  late MockHttpService mockHttpService;

  setUp(() async {
    originalWorkspaceDir = AppConfig.workspaceDir;
    originalCollectionsDir = AppConfig.collectionsDir;
    tempDir = await Directory.systemTemp.createTemp('runner_test_');
    AppConfig.workspaceDir = '${tempDir.path}/workspaces';
    AppConfig.collectionsDir = '${tempDir.path}/collections';
    await Directory(AppConfig.workspaceDir).create(recursive: true);
    await Directory(AppConfig.collectionsDir).create(recursive: true);
    mockHttpService = MockHttpService();
  });

  tearDown(() async {
    AppConfig.workspaceDir = originalWorkspaceDir;
    AppConfig.collectionsDir = originalCollectionsDir;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Runner recursive request gathering and order verification', () async {
    final provider = RequestProvider(httpService: mockHttpService);
    final workspaceId = 'test-ws';

    // Set up nested hierarchy:
    // Root Folder
    //  - req-1
    //  - Sub Folder 1 (parentId: root)
    //     - req-2
    //     - Sub Folder 2 (parentId: sub1)
    //        - req-3
    //  - Sub Folder 3 (parentId: root)
    //     - req-4
    final root = RequestCollection(
      id: 'root',
      name: 'Root Folder',
      workspaceId: workspaceId,
      sortOrder: 0,
      requests: [
        HttpRequest(id: 'req-1', name: 'Req 1', method: HttpMethod.get, url: 'https://example.com/1'),
      ],
    );

    final sub1 = RequestCollection(
      id: 'sub1',
      name: 'Sub Folder 1',
      workspaceId: workspaceId,
      parentId: 'root',
      sortOrder: 0,
      requests: [
        HttpRequest(id: 'req-2', name: 'Req 2', method: HttpMethod.get, url: 'https://example.com/2'),
      ],
    );

    final sub2 = RequestCollection(
      id: 'sub2',
      name: 'Sub Folder 2',
      workspaceId: workspaceId,
      parentId: 'sub1',
      sortOrder: 0,
      requests: [
        HttpRequest(id: 'req-3', name: 'Req 3', method: HttpMethod.get, url: 'https://example.com/3'),
      ],
    );

    final sub3 = RequestCollection(
      id: 'sub3',
      name: 'Sub Folder 3',
      workspaceId: workspaceId,
      parentId: 'root',
      sortOrder: 1,
      requests: [
        HttpRequest(id: 'req-4', name: 'Req 4', method: HttpMethod.get, url: 'https://example.com/4'),
      ],
    );

    // Save mock collections directly in provider state
    await provider.addCollection(root);
    await provider.addCollection(sub1);
    await provider.addCollection(sub2);
    await provider.addCollection(sub3);

    // 1. Verify recursive gather for Collection Run
    provider.startCollectionRun(root);
    expect(provider.isRunnerActive, isTrue);
    expect(provider.isRunningWorkspace, isFalse);
    expect(provider.runnerCollection?.id, equals('root'));
    expect(provider.runnerItems.length, equals(4));

    // Order should be Root -> Sub1 -> Sub2 -> Sub3
    expect(provider.runnerItems[0].request.id, equals('req-1'));
    expect(provider.runnerItems[1].request.id, equals('req-2'));
    expect(provider.runnerItems[2].request.id, equals('req-3'));
    expect(provider.runnerItems[3].request.id, equals('req-4'));

    provider.closeRunner();
    expect(provider.isRunnerActive, isFalse);
    expect(provider.runnerItems, isEmpty);
  });

  test('Runner workspace gathering and execution flows', () async {
    final provider = RequestProvider(httpService: mockHttpService);
    final workspaceId = 'test-ws';

    final collA = RequestCollection(
      id: 'collA',
      name: 'Collection A',
      workspaceId: workspaceId,
      sortOrder: 0,
      requests: [
        HttpRequest(id: 'req-a', name: 'Req A', method: HttpMethod.get, url: 'https://example.com/a'),
      ],
    );

    final collB = RequestCollection(
      id: 'collB',
      name: 'Collection B',
      workspaceId: workspaceId,
      sortOrder: 1,
      requests: [
        HttpRequest(id: 'req-b', name: 'Req B', method: HttpMethod.get, url: 'https://example.com/fail'),
      ],
    );

    await provider.addCollection(collA);
    await provider.addCollection(collB);

    // 1. Start workspace run
    provider.startWorkspaceRun();
    expect(provider.isRunnerActive, isTrue);
    expect(provider.isRunningWorkspace, isTrue);
    expect(provider.runnerItems.length, equals(2));
    expect(provider.runnerItems[0].request.id, equals('req-a'));
    expect(provider.runnerItems[1].request.id, equals('req-b'));

    // 2. Select/Deselect verification
    provider.setRunnerItemSelection(1, false);
    expect(provider.runnerItems[1].isSelected, isFalse);

    // Run session: req-a (selected, success), req-b (not selected, pending)
    await provider.executeRunnerSession();
    expect(provider.runnerItems[0].status, equals('success'));
    expect(provider.runnerItems[1].status, equals('pending'));

    // Re-enable and run both
    provider.setRunnerItemSelection(1, true);
    await provider.executeRunnerSession();
    expect(provider.runnerItems[0].status, equals('success'));
    expect(provider.runnerItems[1].status, equals('failure'));
    expect(provider.runnerItems[1].errorMessage, contains('HTTP Status: 500'));

    // Test toggle all
    provider.toggleAllRunnerItems(false);
    expect(provider.runnerItems.every((item) => !item.isSelected), isTrue);

    provider.toggleAllRunnerItems(true);
    expect(provider.runnerItems.every((item) => item.isSelected), isTrue);

    // Test delay settings
    provider.setRunnerDelay(10);
    expect(provider.runnerDelayMs, equals(10));
  });
}
