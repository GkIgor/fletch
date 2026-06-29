import '../visual_script.dart';

class MarkdownConvertStep extends VisualStep {
  String operation; // "markdownToHtml", "htmlToMarkdown"
  ValueSource valueSource;
  String saveToVariable;

  MarkdownConvertStep({
    super.id,
    super.name = 'Markdown Convert',
    super.enabled,
    super.nextStepId,
    this.operation = 'markdownToHtml',
    ValueSource? valueSource,
    this.saveToVariable = '',
  })  : valueSource = valueSource ?? ValueSource(),
        super(type: VisualStepType.markdownConvert);

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

  factory MarkdownConvertStep.fromJson(Map<String, dynamic> json) => MarkdownConvertStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Markdown Convert',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        operation: json['operation'] as String? ?? 'markdownToHtml',
        valueSource: json['valueSource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['valueSource']))
            : ValueSource(),
        saveToVariable: json['saveToVariable'] as String? ?? '',
      );
}
