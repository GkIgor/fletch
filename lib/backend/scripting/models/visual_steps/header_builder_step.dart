import '../visual_script.dart';

class HeaderBuilderStep extends VisualStep {
  String authType; // "none", "bearer", "basic", "apiKey"
  ValueSource tokenSource;
  Map<String, String> additionalHeaders;
  String saveToVariable;

  HeaderBuilderStep({
    super.id,
    super.name = 'Header Builder',
    super.enabled,
    super.nextStepId,
    this.authType = 'none',
    ValueSource? tokenSource,
    Map<String, String>? additionalHeaders,
    this.saveToVariable = 'headers',
  })  : tokenSource = tokenSource ?? ValueSource(),
        additionalHeaders = additionalHeaders ?? {},
        super(type: VisualStepType.headerBuilder);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'authType': authType,
        'tokenSource': tokenSource.toJson(),
        'additionalHeaders': additionalHeaders,
        'saveToVariable': saveToVariable,
      };

  factory HeaderBuilderStep.fromJson(Map<String, dynamic> json) => HeaderBuilderStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Header Builder',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        authType: json['authType'] as String? ?? 'none',
        tokenSource: json['tokenSource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['tokenSource']))
            : ValueSource(),
        additionalHeaders: Map<String, String>.from(json['additionalHeaders'] ?? {}),
        saveToVariable: json['saveToVariable'] as String? ?? 'headers',
      );
}
