import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fletch/core/app_config.dart';
import 'package:fletch/models/collection_model.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/models/http_request.dart';
import 'package:fletch/models/http_response.dart';
import 'package:fletch/models/http_auth.dart';
import 'package:fletch/providers/request_provider.dart';
import 'package:fletch/repository/collection_repository.dart';
import 'package:fletch/services/http_service.dart';
import 'package:fletch/utils/utils.dart';

// ---------------------------------------------------------------------------
// Shared mock
// ---------------------------------------------------------------------------

class _MockHttpService extends HttpService {
  final int statusCode = 200;
  _MockHttpService();

  @override
  Future<HttpResponse> send(HttpRequest request,
      {Map<String, String>? variables, HttpAuth? resolvedAuth}) async {
    return HttpResponse(
      statusCode: statusCode,
      statusMessage: statusCode == 200 ? 'OK' : 'Error',
      headers: {},
      body: '{}',
      responseTime: 5,
      contentLength: 2,
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

RequestCollection _makeCollection({
  required String id,
  required String workspaceId,
  String? parentId,
  bool isExpanded = true,
  int sortOrder = 0,
  List<HttpRequest>? requests,
}) {
  return RequestCollection(
    id: id,
    name: id,
    workspaceId: workspaceId,
    parentId: parentId,
    isExpanded: isExpanded,
    sortOrder: sortOrder,
    requests: requests ?? [],
  );
}

HttpRequest _makeRequest(String id) => HttpRequest(
      id: id,
      name: id,
      method: HttpMethod.get,
      url: 'https://example.com/$id',
    );

// ---------------------------------------------------------------------------
// Suite 1 — Collection integrity signatures
// ---------------------------------------------------------------------------

void main() {
  late Directory tempDir;
  late String originalWorkspaceDir;
  late String originalCollectionsDir;

  setUp(() async {
    originalWorkspaceDir = AppConfig.workspaceDir;
    originalCollectionsDir = AppConfig.collectionsDir;
    tempDir = await Directory.systemTemp.createTemp('fletch_critical_');
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

  // ── Signature integrity ────────────────────────────────────────────────────

  group('Collection signature integrity', () {
    test('saved collection is loadable with a valid signature', () async {
      final repo = CollectionRepository();
      final col = _makeCollection(
        id: 'col-sig-valid',
        workspaceId: 'ws-sig',
        requests: [_makeRequest('r1')],
      );

      await repo.save(col);
      final loaded = await repo.getById(col.id);

      expect(loaded, isNotNull);
      expect(loaded!.id, equals(col.id));
      expect(loaded.requests.length, equals(1));
    });

    test('returns null when the signature field is missing', () async {
      final repo = CollectionRepository();
      final col = _makeCollection(id: 'col-no-sig', workspaceId: 'ws-sig');
      await repo.save(col);

      // Remove signature from the file on disk
      final filePath = '${AppConfig.collectionsDir}/${col.id}.json';
      final raw = jsonDecode(File(filePath).readAsStringSync())
          as Map<String, dynamic>;
      raw.remove('signature');
      File(filePath).writeAsStringSync(jsonEncode(raw));

      final loaded = await repo.getById(col.id);
      expect(loaded, isNull);
    });

    test('returns null when the signature has been tampered', () async {
      final repo = CollectionRepository();
      final col = _makeCollection(id: 'col-tampered', workspaceId: 'ws-sig');
      await repo.save(col);

      final filePath = '${AppConfig.collectionsDir}/${col.id}.json';
      final raw = jsonDecode(File(filePath).readAsStringSync())
          as Map<String, dynamic>;
      raw['signature'] = 'invalid-hash-value';
      raw['name'] = 'Tampered Name';
      File(filePath).writeAsStringSync(jsonEncode(raw));

      final loaded = await repo.getById(col.id);
      expect(loaded, isNull);
    });

    test('getCorruptedCollections detects tampered files', () async {
      final repo = CollectionRepository();
      final col = _makeCollection(id: 'col-corrupt', workspaceId: 'ws-corrupt');
      await repo.save(col);

      // Tamper the file
      final filePath = '${AppConfig.collectionsDir}/${col.id}.json';
      final raw = jsonDecode(File(filePath).readAsStringSync())
          as Map<String, dynamic>;
      raw['name'] = 'Externally modified';
      File(filePath).writeAsStringSync(jsonEncode(raw));

      final corrupted = await repo.getCorruptedCollections('ws-corrupt');
      expect(corrupted, isNotEmpty);
      expect(corrupted.first['id'], equals(col.id));
    });

    test('SecurityUtils hash changes when content changes', () {
      const original = '{"name":"test"}';
      const modified = '{"name":"changed"}';
      final h1 = SecurityUtils.generateDynamicHash(original);
      final h2 = SecurityUtils.generateDynamicHash(modified);
      expect(h1, isNot(equals(h2)));
    });

    test('SecurityUtils hash is deterministic for same input', () {
      const input = '{"id":"abc","name":"stable"}';
      final h1 = SecurityUtils.generateDynamicHash(input);
      final h2 = SecurityUtils.generateDynamicHash(input);
      expect(h1, equals(h2));
    });
  });

  // ── Toggle all collections ─────────────────────────────────────────────────

  group('toggleAllCollections', () {
    test('collapses all folders when expanded: false', () async {
      final provider = RequestProvider(httpService: _MockHttpService());
      await provider.addCollection(
          _makeCollection(id: 'a', workspaceId: 'ws', isExpanded: true));
      await provider.addCollection(
          _makeCollection(id: 'b', workspaceId: 'ws', isExpanded: true));
      await provider.addCollection(
          _makeCollection(id: 'c', workspaceId: 'ws', isExpanded: false));

      provider.toggleAllCollections(expanded: false);

      expect(provider.collections.every((c) => !c.isExpanded), isTrue);
    });

    test('expands all folders when expanded: true', () async {
      final provider = RequestProvider(httpService: _MockHttpService());
      await provider.addCollection(
          _makeCollection(id: 'x', workspaceId: 'ws', isExpanded: false));
      await provider.addCollection(
          _makeCollection(id: 'y', workspaceId: 'ws', isExpanded: false));

      provider.toggleAllCollections(expanded: true);

      expect(provider.collections.every((c) => c.isExpanded), isTrue);
    });

    test('is a no-op on an empty collection list', () {
      final provider = RequestProvider(httpService: _MockHttpService());
      expect(() => provider.toggleAllCollections(expanded: false),
          returnsNormally);
      expect(provider.collections, isEmpty);
    });

    test('notifies listeners after toggling', () async {
      final provider = RequestProvider(httpService: _MockHttpService());
      await provider.addCollection(
          _makeCollection(id: 'l1', workspaceId: 'ws', isExpanded: true));

      var notified = false;
      provider.addListener(() => notified = true);

      provider.toggleAllCollections(expanded: false);
      expect(notified, isTrue);
    });
  });

  // ── Runner stop / resume ───────────────────────────────────────────────────

  group('Runner stop and resume', () {
    test('stopRunnerExecution marks runner as not running and keeps active state', () async {
      const wsId = 'ws-stop';
      final provider = RequestProvider(httpService: _MockHttpService());

      await provider.addCollection(
        _makeCollection(
          id: 'run-col',
          workspaceId: wsId,
          requests: [_makeRequest('r1'), _makeRequest('r2')],
        ),
      );

      provider.startWorkspaceRun();
      expect(provider.isRunnerActive, isTrue);

      // Calling stop must immediately flip isCurrentlyRunning to false
      provider.stopRunnerExecution();

      expect(provider.isCurrentlyRunning, isFalse,
          reason: 'stopRunnerExecution must clear the running flag');
      // The runner panel should remain open (isRunnerActive stays true)
      expect(provider.isRunnerActive, isTrue,
          reason: 'stop should not close the runner panel');
    });

    test('closing the runner resets all state', () async {
      final provider = RequestProvider(httpService: _MockHttpService());
      await provider.addCollection(
        _makeCollection(
          id: 'col-reset',
          workspaceId: 'ws-reset',
          requests: [_makeRequest('rq1')],
        ),
      );

      provider.startWorkspaceRun();
      expect(provider.isRunnerActive, isTrue);

      provider.closeRunner();

      expect(provider.isRunnerActive, isFalse);
      expect(provider.runnerItems, isEmpty);
      expect(provider.isRunningWorkspace, isFalse);
    });
  });

  group('AppConfig Environment configurations', () {
    test('AppConfig resolves environment configurations correctly', () {
      // Temporarily clear the overridden paths to test default path resolution
      AppConfig.workspaceDir = null;
      AppConfig.collectionsDir = null;

      final expectedFlavor = AppConfig.flavor;
      final String expectedDisplayName;
      final String expectedFolder;

      if (expectedFlavor == 'prod') {
        expectedDisplayName = 'Fletch';
        expectedFolder = '.fletch';
      } else if (expectedFlavor == 'staging') {
        expectedDisplayName = 'Fletch Staging';
        expectedFolder = '.fletch_staging';
      } else {
        expectedDisplayName = 'Fletch Dev';
        expectedFolder = '.fletch_dev';
      }

      expect(AppConfig.appDisplayName, equals(expectedDisplayName));
      expect(AppConfig.workspaceDir, contains('$expectedFolder/workspaces'));
      expect(AppConfig.collectionsDir, contains('$expectedFolder/collections'));
    });
  });
}
