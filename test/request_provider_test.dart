import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gk_http_client/core/app_config.dart';
import 'package:gk_http_client/models/collection_model.dart';
import 'package:gk_http_client/models/http_request.dart';
import 'package:gk_http_client/models/http_method.dart';
import 'package:gk_http_client/providers/request_provider.dart';

void main() {
  late Directory tempDir;
  late String originalWorkspaceDir;
  late String originalCollectionsDir;

  setUp(() async {
    originalWorkspaceDir = AppConfig.workspaceDir;
    originalCollectionsDir = AppConfig.collectionsDir;
    tempDir = await Directory.systemTemp.createTemp('request_provider_test_');
    AppConfig.workspaceDir = '${tempDir.path}/workspaces';
    AppConfig.collectionsDir = '${tempDir.path}/collections';
    await Directory(AppConfig.workspaceDir).create(recursive: true);
    await Directory(AppConfig.collectionsDir).create(recursive: true);
  });

  tearDown(() async {
    AppConfig.workspaceDir = originalWorkspaceDir;
    AppConfig.collectionsDir = originalCollectionsDir;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('RequestProvider management flows', () async {
    final provider = RequestProvider();
    final workspaceId = 'test-ws-id';

    // Verify initial state
    expect(provider.collections, isEmpty);
    expect(provider.selectedRequest, isNull);

    // 1. Add collections
    final collectionA = RequestCollection(
      name: 'Collection A',
      workspaceId: workspaceId,
      sortOrder: 0,
    );
    final collectionB = RequestCollection(
      name: 'Collection B',
      workspaceId: workspaceId,
      sortOrder: 1,
    );

    await provider.addCollection(collectionA);
    await provider.addCollection(collectionB);

    expect(provider.collections.length, equals(2));
    expect(provider.collections[0].name, equals('Collection A'));
    expect(provider.collections[1].name, equals('Collection B'));

    // 2. Add Requests
    final request1 = HttpRequest(
      id: 'req-1',
      name: 'Get User',
      method: HttpMethod.get,
      url: 'https://api.example.com/user',
    );
    final request2 = HttpRequest(
      id: 'req-2',
      name: 'Create User',
      method: HttpMethod.post,
      url: 'https://api.example.com/user',
    );

    provider.addRequestToCollection(collectionA.id, request1);
    provider.addRequestToCollection(collectionA.id, request2);

    expect(provider.collections[0].requests.length, equals(2));
    expect(provider.collections[0].requests[0].id, equals('req-1'));
    expect(provider.collections[0].requests[1].id, equals('req-2'));

    // 3. Rename Request
    provider.renameRequest(collectionA.id, 'req-1', 'Get Active User');
    expect(provider.collections[0].requests[0].name, equals('Get Active User'));

    // 4. Duplicate Request
    provider.duplicateRequest(collectionA.id, request2);
    // There should now be 3 requests: req-1, req-2, and copy of req-2
    expect(provider.collections[0].requests.length, equals(3));
    expect(provider.collections[0].requests[2].name, equals('Create User Copy'));
    // The ID of duplicate request should be auto-generated unique ID (not req-2)
    expect(provider.collections[0].requests[2].id, isNot(equals('req-2')));

    // 5. Move Request
    final requestToMove = provider.collections[0].requests[2];
    provider.moveRequest(
      requestId: requestToMove.id,
      sourceCollectionId: collectionA.id,
      targetCollectionId: collectionB.id,
    );

    // collectionA should have 2 requests now, collectionB should have 1 request
    expect(provider.collections[0].requests.length, equals(2));
    expect(provider.collections[1].requests.length, equals(1));
    expect(provider.collections[1].requests[0].name, equals('Create User Copy'));

    // Move and Reorder within same collection
    // Put req-2 before req-1 (Get Active User)
    provider.moveRequest(
      requestId: 'req-2',
      sourceCollectionId: collectionA.id,
      targetCollectionId: collectionA.id,
      targetRequestId: 'req-1',
    );
    expect(provider.collections[0].requests[0].id, equals('req-2'));
    expect(provider.collections[0].requests[1].id, equals('req-1'));

    // 6. Reorder Collections
    // Drag Collection B (index 1) to Collection A (index 0)
    provider.reorderCollections(collectionB.id, collectionA.id);
    expect(provider.collections[0].id, equals(collectionB.id));
    expect(provider.collections[1].id, equals(collectionA.id));
    expect(provider.collections[0].sortOrder, equals(0));
    expect(provider.collections[1].sortOrder, equals(1));
  });
}
