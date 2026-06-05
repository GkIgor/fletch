enum AuthType {
  inherit,
  none,
  apiKey,
  bearer,
  basic,
  oauth1,
  oauth2,
}

class HttpAuth {
  final AuthType type;

  // API Key config
  final String apiKeyKey;
  final String apiKeyValue;
  final String apiKeyAddTo; // 'header' or 'query'

  // Bearer Token config
  final String bearerToken;

  // Basic Auth config
  final String basicUsername;
  final String basicPassword;

  // OAuth 1.0 config
  final String oauth1ConsumerKey;
  final String oauth1ConsumerSecret;
  final String oauth1Token;
  final String oauth1TokenSecret;
  final String oauth1SignatureMethod; // 'HMAC-SHA1', 'HMAC-SHA256', 'PLAINTEXT'

  // OAuth 2.0 config
  final String oauth2AccessToken;
  final String oauth2TokenUrl;
  final String oauth2ClientId;
  final String oauth2ClientSecret;
  final String oauth2Scope;
  final String oauth2GrantType; // 'client_credentials', 'password'
  final String oauth2Username;
  final String oauth2Password;

  HttpAuth({
    this.type = AuthType.none,
    this.apiKeyKey = 'apikey',
    this.apiKeyValue = '',
    this.apiKeyAddTo = 'header',
    this.bearerToken = '',
    this.basicUsername = '',
    this.basicPassword = '',
    this.oauth1ConsumerKey = '',
    this.oauth1ConsumerSecret = '',
    this.oauth1Token = '',
    this.oauth1TokenSecret = '',
    this.oauth1SignatureMethod = 'HMAC-SHA1',
    this.oauth2AccessToken = '',
    this.oauth2TokenUrl = '',
    this.oauth2ClientId = '',
    this.oauth2ClientSecret = '',
    this.oauth2Scope = '',
    this.oauth2GrantType = 'client_credentials',
    this.oauth2Username = '',
    this.oauth2Password = '',
  });

  HttpAuth copyWith({
    AuthType? type,
    String? apiKeyKey,
    String? apiKeyValue,
    String? apiKeyAddTo,
    String? bearerToken,
    String? basicUsername,
    String? basicPassword,
    String? oauth1ConsumerKey,
    String? oauth1ConsumerSecret,
    String? oauth1Token,
    String? oauth1TokenSecret,
    String? oauth1SignatureMethod,
    String? oauth2AccessToken,
    String? oauth2TokenUrl,
    String? oauth2ClientId,
    String? oauth2ClientSecret,
    String? oauth2Scope,
    String? oauth2GrantType,
    String? oauth2Username,
    String? oauth2Password,
  }) {
    return HttpAuth(
      type: type ?? this.type,
      apiKeyKey: apiKeyKey ?? this.apiKeyKey,
      apiKeyValue: apiKeyValue ?? this.apiKeyValue,
      apiKeyAddTo: apiKeyAddTo ?? this.apiKeyAddTo,
      bearerToken: bearerToken ?? this.bearerToken,
      basicUsername: basicUsername ?? this.basicUsername,
      basicPassword: basicPassword ?? this.basicPassword,
      oauth1ConsumerKey: oauth1ConsumerKey ?? this.oauth1ConsumerKey,
      oauth1ConsumerSecret: oauth1ConsumerSecret ?? this.oauth1ConsumerSecret,
      oauth1Token: oauth1Token ?? this.oauth1Token,
      oauth1TokenSecret: oauth1TokenSecret ?? this.oauth1TokenSecret,
      oauth1SignatureMethod: oauth1SignatureMethod ?? this.oauth1SignatureMethod,
      oauth2AccessToken: oauth2AccessToken ?? this.oauth2AccessToken,
      oauth2TokenUrl: oauth2TokenUrl ?? this.oauth2TokenUrl,
      oauth2ClientId: oauth2ClientId ?? this.oauth2ClientId,
      oauth2ClientSecret: oauth2ClientSecret ?? this.oauth2ClientSecret,
      oauth2Scope: oauth2Scope ?? this.oauth2Scope,
      oauth2GrantType: oauth2GrantType ?? this.oauth2GrantType,
      oauth2Username: oauth2Username ?? this.oauth2Username,
      oauth2Password: oauth2Password ?? this.oauth2Password,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'apiKeyKey': apiKeyKey,
        'apiKeyValue': apiKeyValue,
        'apiKeyAddTo': apiKeyAddTo,
        'bearerToken': bearerToken,
        'basicUsername': basicUsername,
        'basicPassword': basicPassword,
        'oauth1ConsumerKey': oauth1ConsumerKey,
        'oauth1ConsumerSecret': oauth1ConsumerSecret,
        'oauth1Token': oauth1Token,
        'oauth1TokenSecret': oauth1TokenSecret,
        'oauth1SignatureMethod': oauth1SignatureMethod,
        'oauth2AccessToken': oauth2AccessToken,
        'oauth2TokenUrl': oauth2TokenUrl,
        'oauth2ClientId': oauth2ClientId,
        'oauth2ClientSecret': oauth2ClientSecret,
        'oauth2Scope': oauth2Scope,
        'oauth2GrantType': oauth2GrantType,
        'oauth2Username': oauth2Username,
        'oauth2Password': oauth2Password,
      };

  factory HttpAuth.fromJson(Map<String, dynamic> json) {
    return HttpAuth(
      type: AuthType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AuthType.none,
      ),
      apiKeyKey: json['apiKeyKey'] ?? 'apikey',
      apiKeyValue: json['apiKeyValue'] ?? '',
      apiKeyAddTo: json['apiKeyAddTo'] ?? 'header',
      bearerToken: json['bearerToken'] ?? '',
      basicUsername: json['basicUsername'] ?? '',
      basicPassword: json['basicPassword'] ?? '',
      oauth1ConsumerKey: json['oauth1ConsumerKey'] ?? '',
      oauth1ConsumerSecret: json['oauth1ConsumerSecret'] ?? '',
      oauth1Token: json['oauth1Token'] ?? '',
      oauth1TokenSecret: json['oauth1TokenSecret'] ?? '',
      oauth1SignatureMethod: json['oauth1SignatureMethod'] ?? 'HMAC-SHA1',
      oauth2AccessToken: json['oauth2AccessToken'] ?? '',
      oauth2TokenUrl: json['oauth2TokenUrl'] ?? '',
      oauth2ClientId: json['oauth2ClientId'] ?? '',
      oauth2ClientSecret: json['oauth2ClientSecret'] ?? '',
      oauth2Scope: json['oauth2Scope'] ?? '',
      oauth2GrantType: json['oauth2GrantType'] ?? 'client_credentials',
      oauth2Username: json['oauth2Username'] ?? '',
      oauth2Password: json['oauth2Password'] ?? '',
    );
  }
}
