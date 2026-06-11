import '../visual_script.dart';

class JsonConvertStep extends VisualStep {
  String operation; // "serialize", "deserialize"
  ValueSource valueSource;
  String saveToVariable;

  JsonConvertStep({
    super.id,
    super.name = 'JSON Convert',
    super.enabled,
    super.nextStepId,
    this.operation = 'deserialize',
    ValueSource? valueSource,
    this.saveToVariable = '',
  })  : valueSource = valueSource ?? ValueSource(),
        super(type: VisualStepType.jsonConvert);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'operation': operation,
        'valueSource': valueSource.toJson(),
        'saveToVariable': saveToVariable,
      };

  factory JsonConvertStep.fromJson(Map<String, dynamic> json) => JsonConvertStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'JSON Convert',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        operation: json['operation'] as String? ?? 'deserialize',
        valueSource: json['valueSource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['valueSource']))
            : ValueSource(),
        saveToVariable: json['saveToVariable'] as String? ?? '',
      );
}
