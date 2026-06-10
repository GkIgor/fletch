// Visual Script, ValueSource, and Polymorphic Steps models for Fletch visual automation scripts.
import 'package:uuid/uuid.dart';

enum ScriptMode {
  lowCode,
  advanced,
}

enum VisualStepType {
  setVariable,
  assertValue,
  sendRequest,
  delay,
}

enum ValueSourceType {
  constant,          // Static text value
  responseBody,      // HTTP response body
  responseHeader,    // HTTP response header matching key
  responseStatusCode,// HTTP status code number
  variable,          // Workspace active variable matching name
}

/// A decoupled, granular representation of a data origin.
class ValueSource {
  final ValueSourceType type;
  final String key;      // Header key or variable name
  final String jsonPath; // Dot-notation path to extract fields from JSON values

  ValueSource({
    this.type = ValueSourceType.constant,
    this.key = '',
    this.jsonPath = '',
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'key': key,
        'jsonPath': jsonPath,
      };

  factory ValueSource.fromJson(Map<String, dynamic> json) => ValueSource(
        type: ValueSourceType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ValueSourceType.constant,
        ),
        key: json['key'] as String? ?? '',
        jsonPath: json['jsonPath'] as String? ?? '',
      );
}

abstract class VisualStep {
  final String id;
  final VisualStepType type;
  bool enabled;

  VisualStep({
    String? id,
    required this.type,
    this.enabled = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson();

  static VisualStep fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = VisualStepType.values.firstWhere((e) => e.name == typeStr);
    
    switch (type) {
      case VisualStepType.setVariable:
        return SetVariableStep.fromJson(json);
      case VisualStepType.assertValue:
        return AssertValueStep.fromJson(json);
      case VisualStepType.sendRequest:
        return SendRequestStep.fromJson(json);
      case VisualStepType.delay:
        return DelayStep.fromJson(json);
    }
  }
}

class SetVariableStep extends VisualStep {
  String variableName;
  ValueSource valueSource;

  SetVariableStep({
    super.id,
    super.enabled,
    this.variableName = '',
    ValueSource? valueSource,
  })  : valueSource = valueSource ?? ValueSource(),
        super(type: VisualStepType.setVariable);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'enabled': enabled,
        'variableName': variableName,
        'valueSource': valueSource.toJson(),
      };

  factory SetVariableStep.fromJson(Map<String, dynamic> json) => SetVariableStep(
        id: json['id'] as String?,
        enabled: json['enabled'] as bool? ?? true,
        variableName: json['variableName'] as String? ?? '',
        valueSource: json['valueSource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['valueSource']))
            : ValueSource(),
      );
}

class AssertValueStep extends VisualStep {
  ValueSource leftSource;
  String operator;         // e.g. "==", "!=", "contains", ">", "<"
  ValueSource rightSource;

  AssertValueStep({
    super.id,
    super.enabled,
    ValueSource? leftSource,
    this.operator = '==',
    ValueSource? rightSource,
  })  : leftSource = leftSource ?? ValueSource(),
        rightSource = rightSource ?? ValueSource(),
        super(type: VisualStepType.assertValue);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'enabled': enabled,
        'leftSource': leftSource.toJson(),
        'operator': operator,
        'rightSource': rightSource.toJson(),
      };

  factory AssertValueStep.fromJson(Map<String, dynamic> json) => AssertValueStep(
        id: json['id'] as String?,
        enabled: json['enabled'] as bool? ?? true,
        leftSource: json['leftSource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['leftSource']))
            : ValueSource(),
        operator: json['operator'] as String? ?? '==',
        rightSource: json['rightSource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['rightSource']))
            : ValueSource(),
      );
}

class SendRequestStep extends VisualStep {
  String method;           // "GET", "POST", etc.
  String url;
  Map<String, String> headers;
  String? body;
  String saveToVariable;   // Variable name to save the response body to

  SendRequestStep({
    super.id,
    super.enabled,
    this.method = 'GET',
    this.url = '',
    Map<String, String>? headers,
    this.body,
    this.saveToVariable = '',
  })  : headers = headers ?? {},
        super(type: VisualStepType.sendRequest);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'enabled': enabled,
        'method': method,
        'url': url,
        'headers': headers,
        'body': body,
        'saveToVariable': saveToVariable,
      };

  factory SendRequestStep.fromJson(Map<String, dynamic> json) => SendRequestStep(
        id: json['id'] as String?,
        enabled: json['enabled'] as bool? ?? true,
        method: json['method'] as String? ?? 'GET',
        url: json['url'] as String? ?? '',
        headers: Map<String, String>.from(json['headers'] ?? {}),
        body: json['body'] as String?,
        saveToVariable: json['saveToVariable'] as String? ?? '',
      );
}

class DelayStep extends VisualStep {
  int durationMs;

  DelayStep({
    super.id,
    super.enabled,
    this.durationMs = 1000,
  }) : super(type: VisualStepType.delay);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'enabled': enabled,
        'durationMs': durationMs,
      };

  factory DelayStep.fromJson(Map<String, dynamic> json) => DelayStep(
        id: json['id'] as String?,
        enabled: json['enabled'] as bool? ?? true,
        durationMs: json['durationMs'] as int? ?? 1000,
      );
}

class VisualScript {
  final String id;
  String name;
  bool isPreRequest;
  ScriptMode mode;
  List<VisualStep> steps;
  String advancedCode;
  DateTime updatedAt;

  VisualScript({
    String? id,
    required this.name,
    this.isPreRequest = true,
    this.mode = ScriptMode.lowCode,
    List<VisualStep>? steps,
    this.advancedCode = '',
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        steps = steps ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  VisualScript copyWith({
    String? name,
    bool? isPreRequest,
    ScriptMode? mode,
    List<VisualStep>? steps,
    String? advancedCode,
    DateTime? updatedAt,
  }) {
    return VisualScript(
      id: id,
      name: name ?? this.name,
      isPreRequest: isPreRequest ?? this.isPreRequest,
      mode: mode ?? this.mode,
      steps: steps ?? this.steps,
      advancedCode: advancedCode ?? this.advancedCode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isPreRequest': isPreRequest,
        'mode': mode.name,
        'steps': steps.map((e) => e.toJson()).toList(),
        'advancedCode': advancedCode,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory VisualScript.fromJson(Map<String, dynamic> json) {
    return VisualScript(
      id: json['id'] as String,
      name: json['name'] as String,
      isPreRequest: json['isPreRequest'] as bool? ?? true,
      mode: ScriptMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => ScriptMode.lowCode,
      ),
      steps: (json['steps'] as List?)
              ?.map((e) => VisualStep.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      advancedCode: json['advancedCode'] as String? ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
