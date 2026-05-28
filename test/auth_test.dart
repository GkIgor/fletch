import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fletch/models/http_auth.dart';
import 'package:fletch/utils/oauth1_helper.dart';
import 'package:fletch/providers/request_provider.dart';

void main() {
  group('HttpAuth Model Tests', () {
    test('HttpAuth defaults to AuthType.none and proper defaults', () {
      final auth = HttpAuth();
      expect(auth.type, equals(AuthType.none));
      expect(auth.apiKeyKey, equals('apikey'));
      expect(auth.apiKeyAddTo, equals('header'));
      expect(auth.oauth1SignatureMethod, equals('HMAC-SHA1'));
      expect(auth.oauth2GrantType, equals('client_credentials'));
    });

    test('HttpAuth serialization & deserialization (toJson & fromJson)', () {
      final original = HttpAuth(
        type: AuthType.oauth1,
        apiKeyKey: 'custom-key',
        apiKeyValue: 'custom-val',
        apiKeyAddTo: 'query',
        bearerToken: 'token-xyz',
        basicUsername: 'user1',
        basicPassword: 'pass1',
        oauth1ConsumerKey: 'ckey',
        oauth1ConsumerSecret: 'csecret',
        oauth1Token: 'otoken',
        oauth1TokenSecret: 'osecret',
        oauth1SignatureMethod: 'HMAC-SHA256',
        oauth2AccessToken: 'access-123',
        oauth2TokenUrl: 'https://example.com/oauth/token',
        oauth2ClientId: 'cid',
        oauth2ClientSecret: 'csecret2',
        oauth2Scope: 'read write',
        oauth2GrantType: 'password',
        oauth2Username: 'oauth-user',
        oauth2Password: 'oauth-pass',
      );

      final json = original.toJson();
      final parsed = HttpAuth.fromJson(json);

      expect(parsed.type, equals(AuthType.oauth1));
      expect(parsed.apiKeyKey, equals('custom-key'));
      expect(parsed.apiKeyValue, equals('custom-val'));
      expect(parsed.apiKeyAddTo, equals('query'));
      expect(parsed.bearerToken, equals('token-xyz'));
      expect(parsed.basicUsername, equals('user1'));
      expect(parsed.basicPassword, equals('pass1'));
      expect(parsed.oauth1ConsumerKey, equals('ckey'));
      expect(parsed.oauth1ConsumerSecret, equals('csecret'));
      expect(parsed.oauth1Token, equals('otoken'));
      expect(parsed.oauth1TokenSecret, equals('osecret'));
      expect(parsed.oauth1SignatureMethod, equals('HMAC-SHA256'));
      expect(parsed.oauth2AccessToken, equals('access-123'));
      expect(parsed.oauth2TokenUrl, equals('https://example.com/oauth/token'));
      expect(parsed.oauth2ClientId, equals('cid'));
      expect(parsed.oauth2ClientSecret, equals('csecret2'));
      expect(parsed.oauth2Scope, equals('read write'));
      expect(parsed.oauth2GrantType, equals('password'));
      expect(parsed.oauth2Username, equals('oauth-user'));
      expect(parsed.oauth2Password, equals('oauth-pass'));
    });

    test('HttpAuth.copyWith copies fields correctly', () {
      final base = HttpAuth(type: AuthType.basic, basicUsername: 'u1');
      final updated = base.copyWith(
        type: AuthType.bearer,
        bearerToken: 'new-bearer',
      );

      expect(updated.type, equals(AuthType.bearer));
      expect(updated.bearerToken, equals('new-bearer'));
      expect(updated.basicUsername, equals('u1')); // preserved
    });
  });

  group('OAuth1Helper Tests', () {
    test('RFC 5849 encoding handles special characters correctly', () {
      // RFC 5849 encoding expects uppercase percent encoding for characters: !'()*
      final encoded = OAuth1Helper.encode("Hello! 'World' (test) *");
      expect(encoded, equals("Hello%21%20%27World%27%20%28test%29%20%2A"));
    });

    test('generateHeader returns structured header and signatures', () {
      final header = OAuth1Helper.generateHeader(
        method: 'GET',
        url: 'https://photos.example.net/photos',
        queryParams: {'file': 'vacation.jpg', 'size': 'original'},
        consumerKey: 'dpf43faf30294j5j',
        consumerSecret: 'kd94hf93c411744e',
        token: 'nnch734d00sl2jdk',
        tokenSecret: 'pfkkdhi9sl3r4s00',
        signatureMethod: 'HMAC-SHA1',
        nonce: 'kllo9940pd9333jh',
        timestamp: '1191242096',
      );

      expect(header, startsWith('OAuth '));
      expect(header, contains('oauth_consumer_key="dpf43faf30294j5j"'));
      expect(header, contains('oauth_token="nnch734d00sl2jdk"'));
      expect(header, contains('oauth_signature_method="HMAC-SHA1"'));
      // Expect a calculated signature
      expect(header, contains('oauth_signature="'));
    });
  });

  group('OAuth 2.0 Token Fetcher integration', () {
    late HttpServer server;
    late RequestProvider provider;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      provider = RequestProvider();
    });

    tearDown(() async {
      await server.close();
    });

    test('fetchOAuth2Token succeeds with client_credentials flow', () async {
      server.listen((HttpRequest request) async {
        expect(request.method, equals('POST'));
        expect(request.headers.value(HttpHeaders.contentTypeHeader),
            equals('application/x-www-form-urlencoded'));

        final body = await utf8.decoder.bind(request).join();
        final params = Uri.splitQueryString(body);

        expect(params['grant_type'], equals('client_credentials'));
        expect(params['client_id'], equals('my-client-id'));
        expect(params['client_secret'], equals('my-secret'));

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'access_token': 'returned-oauth2-token-12345',
            'token_type': 'Bearer',
          }));
        await request.response.close();
      });

      final token = await provider.fetchOAuth2Token(
        tokenUrl: 'http://localhost:${server.port}/token',
        grantType: 'client_credentials',
        clientId: 'my-client-id',
        clientSecret: 'my-secret',
        scope: 'read',
        username: '',
        password: '',
      );

      expect(token, equals('returned-oauth2-token-12345'));
    });

    test('fetchOAuth2Token succeeds with password grant flow', () async {
      server.listen((HttpRequest request) async {
        final body = await utf8.decoder.bind(request).join();
        final params = Uri.splitQueryString(body);

        expect(params['grant_type'], equals('password'));
        expect(params['username'], equals('user-bob'));
        expect(params['password'], equals('pass-bob'));

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'access_token': 'returned-password-token-999',
          }));
        await request.response.close();
      });

      final token = await provider.fetchOAuth2Token(
        tokenUrl: 'http://localhost:${server.port}/token',
        grantType: 'password',
        clientId: 'my-client-id',
        clientSecret: 'my-secret',
        scope: '',
        username: 'user-bob',
        password: 'pass-bob',
      );

      expect(token, equals('returned-password-token-999'));
    });

    test('fetchOAuth2Token handles non-200 HTTP failure responses', () async {
      server.listen((HttpRequest request) async {
        request.response
          ..statusCode = HttpStatus.unauthorized
          ..write('Unauthorized Request');
        await request.response.close();
      });

      expect(
        () => provider.fetchOAuth2Token(
          tokenUrl: 'http://localhost:${server.port}/token',
          grantType: 'client_credentials',
          clientId: 'client',
          clientSecret: 'secret',
          scope: '',
          username: '',
          password: '',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
