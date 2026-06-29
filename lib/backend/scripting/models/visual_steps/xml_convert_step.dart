import '../visual_script.dart';

class XmlConvertStep extends VisualStep {
  String operation; // "xmlToJson", "jsonToXml"
  ValueSource valueSource;
  String saveToVariable;

  XmlConvertStep({
    super.id,
    super.name = 'XML Convert',
    super.enabled,
    super.nextStepId,
    this.operation = 'xmlToJson',
    ValueSource? valueSource,
    this.saveToVariable = '',
  })  : valueSource = valueSource ?? ValueSource(),
        super(type: VisualStepType.xmlConvert);

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

  factory XmlConvertStep.fromJson(Map<String, dynamic> json) => XmlConvertStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'XML Convert',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        operation: json['operation'] as String? ?? 'xmlToJson',
        valueSource: json['valueSource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['valueSource']))
            : ValueSource(),
        saveToVariable: json['saveToVariable'] as String? ?? '',
      );
}
