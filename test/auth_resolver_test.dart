import 'package:flutter_test/flutter_test.dart';
import 'package:fletch/models/collection_model.dart';
import 'package:fletch/models/http_auth.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/models/http_request.dart';
import 'package:fletch/utils/auth_resolver.dart';

void main() {
  group('AuthResolver Tests', () {
    final apiKeyAuth = HttpAuth(
      type: AuthType.apiKey,
      apiKeyKey: 'X-API-Key',
      apiKeyValue: '12345',
    );

    final bearerAuth = HttpAuth(
      type: AuthType.bearer,
      bearerToken: 'token_val',
    );

    final basicAuth = HttpAuth(
      type: AuthType.basic,
      basicUsername: 'user',
      basicPassword: 'pwd',
    );

    test('direct request auth resolves immediately if not inherit', () {
      final req = HttpRequest(
        name: 'Direct request',
        method: HttpMethod.get,
        url: 'example.com',
        auth: bearerAuth,
      );

      final resolved = AuthResolver.resolveAuth(
        request: req,
        collections: [],
        workspaceAuth: apiKeyAuth,
      );

      expect(resolved.type, equals(AuthType.bearer));
      expect(resolved.bearerToken, equals('token_val'));
    });

    test('request inherits from parent collection directly', () {
      final req = HttpRequest(
        name: 'Inheriting request',
        method: HttpMethod.get,
        url: 'example.com',
        auth: HttpAuth(type: AuthType.inherit),
      );

      final col = RequestCollection(
        name: 'Collection A',
        workspaceId: 'ws1',
        requests: [req],
        auth: bearerAuth,
      );

      final resolved = AuthResolver.resolveAuth(
        request: req,
        collections: [col],
        workspaceAuth: apiKeyAuth,
      );

      expect(resolved.type, equals(AuthType.bearer));
      expect(resolved.bearerToken, equals('token_val'));
    });

    test('request inherits recursively up parent collections', () {
      final req = HttpRequest(
        name: 'Deep Inheriting request',
        method: HttpMethod.get,
        url: 'example.com',
        auth: HttpAuth(type: AuthType.inherit),
      );

      final subCol = RequestCollection(
        id: 'sub_col_id',
        name: 'Sub Collection',
        workspaceId: 'ws1',
        requests: [req],
        parentId: 'parent_col_id',
        auth: HttpAuth(type: AuthType.inherit),
      );

      final parentCol = RequestCollection(
        id: 'parent_col_id',
        name: 'Parent Collection',
        workspaceId: 'ws1',
        requests: [],
        auth: basicAuth,
      );

      final resolved = AuthResolver.resolveAuth(
        request: req,
        collections: [subCol, parentCol],
        workspaceAuth: apiKeyAuth,
      );

      expect(resolved.type, equals(AuthType.basic));
      expect(resolved.basicUsername, equals('user'));
    });

    test('request inherits all the way to workspace auth', () {
      final req = HttpRequest(
        name: 'Workspace Inheriting request',
        method: HttpMethod.get,
        url: 'example.com',
        auth: HttpAuth(type: AuthType.inherit),
      );

      final subCol = RequestCollection(
        id: 'sub_col_id',
        name: 'Sub Collection',
        workspaceId: 'ws1',
        requests: [req],
        parentId: 'parent_col_id',
        auth: HttpAuth(type: AuthType.inherit),
      );

      final parentCol = RequestCollection(
        id: 'parent_col_id',
        name: 'Parent Collection',
        workspaceId: 'ws1',
        requests: [],
        auth: HttpAuth(type: AuthType.inherit),
      );

      final resolved = AuthResolver.resolveAuth(
        request: req,
        collections: [subCol, parentCol],
        workspaceAuth: apiKeyAuth,
      );

      expect(resolved.type, equals(AuthType.apiKey));
      expect(resolved.apiKeyKey, equals('X-API-Key'));
    });

    test('getInheritedSourceName correctly identifies inheritance source', () {
      final req1 = HttpRequest(
        id: 'req1',
        name: 'Direct request',
        method: HttpMethod.get,
        url: 'example.com',
        auth: bearerAuth,
      );

      final req2 = HttpRequest(
        id: 'req2',
        name: 'Collection Inheriting',
        method: HttpMethod.get,
        url: 'example.com',
        auth: HttpAuth(type: AuthType.inherit),
      );

      final col = RequestCollection(
        id: 'col_id',
        name: 'Parent Folder',
        workspaceId: 'ws1',
        requests: [req1, req2],
        auth: basicAuth,
      );

      final req3 = HttpRequest(
        id: 'req3',
        name: 'Workspace Inheriting',
        method: HttpMethod.get,
        url: 'example.com',
        auth: HttpAuth(type: AuthType.inherit),
      );

      final colInheriting = RequestCollection(
        id: 'col_inh_id',
        name: 'Inheriting Folder',
        workspaceId: 'ws1',
        requests: [req3],
        auth: HttpAuth(type: AuthType.inherit),
      );

      final source1 = AuthResolver.getInheritedSourceName(
        request: req1,
        collections: [col, colInheriting],
      );
      final source2 = AuthResolver.getInheritedSourceName(
        request: req2,
        collections: [col, colInheriting],
      );
      final source3 = AuthResolver.getInheritedSourceName(
        request: req3,
        collections: [col, colInheriting],
      );

      expect(source1, equals('Request'));
      expect(source2, equals('Collection "Parent Folder"'));
      expect(source3, equals('Workspace'));
    });
  });
}
