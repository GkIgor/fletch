import '../visual_script.dart';

class JsonPathStep extends VisualStep {
  ValueSource valueSource;
  String jsonPathExpression;
  String saveToVariable;

  JsonPathStep({
    super.id,
    super.name = 'JSON Path',
    super.enabled,
    super.nextStepId,
    ValueSource? valueSource,
    this.jsonPathExpression = '',
    this.saveToVariable = '',
  })  : valueSource = valueSource ?? ValueSource(),
        super(type: VisualStepType.jsonPathStep);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'valueSource': valueSource.toJson(),
        'jsonPathExpression': jsonPathExpression,
        'saveToVariable': saveToVariable,
      };

  factory JsonPathStep.fromJson(Map<String, dynamic> json) => JsonPathStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'JSON Path',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        valueSource: json['valueSource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['valueSource']))
            : ValueSource(),
        jsonPathExpression: json['jsonPathExpression'] as String? ?? '',
        saveToVariable: json['saveToVariable'] as String? ?? '',
      );
}
