import 'package:uuid/uuid.dart';
import 'http_method.dart';
import 'package:gk_http_client/widgets/body_editor.dart';

/// Modelo de entrada para Form Data
class FormDataEntry {
  final String id;
  String key;
  String value;
  bool isFile;
  bool enabled;

  FormDataEntry({
    String? id,
    this.key = '',
    this.value = '',
    this.isFile = false,
    this.enabled = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'key': key,
    'value': value,
    'isFile': isFile,
    'enabled': enabled,
  };

  factory FormDataEntry.fromJson(Map<String, dynamic> json) => FormDataEntry(
    id: json['id'],
    key: json['key'] ?? '',
    value: json['value'] ?? '',
    isFile: json['isFile'] ?? false,
    enabled: json['enabled'] ?? true,
  );

  FormDataEntry copyWith({
    String? key,
    String? value,
    bool? isFile,
    bool? enabled,
  }) {
    return FormDataEntry(
      id: id,
      key: key ?? this.key,
      value: value ?? this.value,
      isFile: isFile ?? this.isFile,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// Modelo de requisição HTTP
class HttpRequest {
  final String id;
  String name;
  HttpMethod method;
  String url;
  Map<String, String> queryParams;
  Map<String, String> headers;
  String? body;
  BodyType bodyType;
  List<FormDataEntry> formData;
  String? binaryPath;

  HttpRequest({
    String? id,
    required this.name,
    required this.method,
    required this.url,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    this.body,
    this.bodyType = BodyType.none,
    List<FormDataEntry>? formData,
    this.binaryPath,
  }) : id = id ?? const Uuid().v4(),
       queryParams = queryParams ?? {},
       headers = headers ?? {},
       formData = formData ?? [];

  /// Cria uma cópia da requisição com campos modificados
  HttpRequest copyWith({
    String? name,
    HttpMethod? method,
    String? url,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    String? body,
    BodyType? bodyType,
    List<FormDataEntry>? formData,
    String? binaryPath,
  }) {
    return HttpRequest(
      id: id,
      name: name ?? this.name,
      method: method ?? this.method,
      url: url ?? this.url,
      queryParams: queryParams ?? this.queryParams,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      bodyType: bodyType ?? this.bodyType,
      formData: formData ?? this.formData,
      binaryPath: binaryPath ?? this.binaryPath,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'method': method.value,
      'url': url,
      'queryParams': queryParams,
      'headers': headers,
      'body': body,
      'bodyType': bodyType.name,
      'formData': formData.map((e) => e.toJson()).toList(),
      'binaryPath': binaryPath,
    };
  }

  /// Cria a partir de JSON
  factory HttpRequest.fromJson(Map<String, dynamic> json) {
    return HttpRequest(
      id: json['id'] as String,
      name: json['name'] as String,
      method: HttpMethod.values.firstWhere(
        (m) => m.value == json['method'],
        orElse: () => HttpMethod.get,
      ),
      url: json['url'] as String,
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      headers: Map<String, String>.from(json['headers'] ?? {}),
      body: json['body'] as String?,
      bodyType: BodyType.values.firstWhere(
        (e) => e.name == json['bodyType'],
        orElse: () => BodyType.none,
      ),
      formData: (json['formData'] as List?)
          ?.map((e) => FormDataEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList() ?? [],
      binaryPath: json['binaryPath'] as String?,
    );
  }
}
