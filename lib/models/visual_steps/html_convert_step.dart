import '../visual_script.dart';

class HtmlConvertStep extends VisualStep {
  String operation; // "htmlToText", "extractSelector", "extractAttributes"
  ValueSource valueSource;
  String selector;
  String attribute;
  String saveToVariable;

  HtmlConvertStep({
    super.id,
    super.name = 'HTML Convert',
    super.enabled,
    super.nextStepId,
    this.operation = 'htmlToText',
    ValueSource? valueSource,
    this.selector = '',
    this.attribute = '',
    this.saveToVariable = '',
  })  : valueSource = valueSource ?? ValueSource(),
        super(type: VisualStepType.htmlConvert);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'operation': operation,
        'valueSource': valueSource.toJson(),
        'selector': selector,
        'attribute': attribute,
        'saveToVariable': saveToVariable,
      };

  factory HtmlConvertStep.fromJson(Map<String, dynamic> json) => HtmlConvertStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'HTML Convert',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        operation: json['operation'] as String? ?? 'htmlToText',
        valueSource: json['valueSource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['valueSource']))
            : ValueSource(),
        selector: json['selector'] as String? ?? '',
        attribute: json['attribute'] as String? ?? '',
        saveToVariable: json['saveToVariable'] as String? ?? '',
      );
}
