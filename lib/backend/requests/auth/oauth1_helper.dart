import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class OAuth1Helper {
  static String encode(String value) {
    return Uri.encodeComponent(value)
        .replaceAll('!', '%21')
        .replaceAll("'", '%27')
        .replaceAll('(', '%28')
        .replaceAll(')', '%29')
        .replaceAll('*', '%2A');
  }

  static String generateNonce() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Url.encode(bytes).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  static String generateTimestamp() {
    return (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  }

  static String generateHeader({
    required String method,
    required String url,
    required Map<String, String> queryParams,
    required String consumerKey,
    required String consumerSecret,
    required String token,
    required String tokenSecret,
    required String signatureMethod, // 'HMAC-SHA1' or 'HMAC-SHA256' or 'PLAINTEXT'
    String? nonce,
    String? timestamp,
  }) {
    final resolvedNonce = nonce ?? generateNonce();
    final resolvedTimestamp = timestamp ?? generateTimestamp();

    // 1. Gather all parameters
    final Map<String, String> oauthParams = {
      'oauth_consumer_key': consumerKey,
      'oauth_nonce': resolvedNonce,
      'oauth_signature_method': signatureMethod,
      'oauth_timestamp': resolvedTimestamp,
      'oauth_version': '1.0',
    };
    if (token.isNotEmpty) {
      oauthParams['oauth_token'] = token;
    }

    final Map<String, String> allParams = {};
    // Add request query parameters
    queryParams.forEach((k, v) {
      allParams[encode(k)] = encode(v);
    });
    // Parse query params directly from URL if present
    final parsedUri = Uri.parse(url);
    parsedUri.queryParameters.forEach((k, v) {
      allParams[encode(k)] = encode(v);
    });
    // Add oauth parameters
    oauthParams.forEach((k, v) {
      allParams[encode(k)] = encode(v);
    });

    // Sort parameters
    final sortedKeys = allParams.keys.toList()..sort();
    final paramString = sortedKeys.map((k) => '$k=${allParams[k]}').join('&');

    // 2. Base URL (no query params, lower case scheme and host)
    final baseUrl = parsedUri.replace(queryParameters: {}).toString();

    // 3. Signature Base String
    final signatureBaseString = '${method.toUpperCase()}&${encode(baseUrl)}&${encode(paramString)}';

    // 4. Signing Key
    final signingKey = '${encode(consumerSecret)}&${encode(tokenSecret)}';

    // 5. Compute Signature
    String signature = '';
    if (signatureMethod == 'PLAINTEXT') {
      signature = signingKey;
    } else {
      final keyBytes = utf8.encode(signingKey);
      final baseBytes = utf8.encode(signatureBaseString);

      final Hash algorithm = signatureMethod == 'HMAC-SHA256' ? sha256 : sha1;
      final hmac = Hmac(algorithm, keyBytes);
      final signatureBytes = hmac.convert(baseBytes).bytes;
      signature = base64.encode(signatureBytes);
    }

    // 6. Build Header
    final headerParams = Map<String, String>.from(oauthParams);
    headerParams['oauth_signature'] = signature;

    final headerSortedKeys = headerParams.keys.toList()..sort();
    final headerString = headerSortedKeys.map((k) => '$k="${encode(headerParams[k]!)}"').join(', ');

    return 'OAuth $headerString';
  }
}
