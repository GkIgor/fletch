import '../visual_script.dart';

class SendRequestStep extends VisualStep {
  String method;           // "GET", "POST", etc.
  String url;
  Map<String, String> headers;
  String? body;
  String saveToVariable;   // Variable name to save the response body to
  /// When set, uses the referenced workspace HttpRequest's method/url/headers/body.
  /// Scripts attached to that request are NOT executed (anti-loop guard).
  String? requestId;

  SendRequestStep({
    super.id,
    super.name = 'HTTP Request',
    super.enabled,
    super.nextStepId,
    this.method = 'GET',
    this.url = '',
    Map<String, String>? headers,
    this.body,
    this.saveToVariable = '',
    this.requestId,
  })  : headers = headers ?? {},
        super(type: VisualStepType.sendRequest);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'method': method,
        'url': url,
        'headers': headers,
        'body': body,
        'saveToVariable': saveToVariable,
        'requestId': requestId,
      };

  factory SendRequestStep.fromJson(Map<String, dynamic> json) => SendRequestStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'HTTP Request',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        method: json['method'] as String? ?? 'GET',
        url: json['url'] as String? ?? '',
        headers: Map<String, String>.from(json['headers'] ?? {}),
        body: json['body'] as String?,
        saveToVariable: json['saveToVariable'] as String? ?? '',
        requestId: json['requestId'] as String?,
      );
}
