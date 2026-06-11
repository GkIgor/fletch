import '../visual_script.dart';

class DateTimeStep extends VisualStep {
  String operation; // "current", "add", "subtract", "format"
  String value; // Offset/Value e.g. "1 day" or format string
  String formatPattern; // Format output e.g. "yyyy-MM-dd"
  String saveToVariable;

  DateTimeStep({
    super.id,
    super.name = 'Date & Time',
    super.enabled,
    super.nextStepId,
    this.operation = 'current',
    this.value = '',
    this.formatPattern = 'yyyy-MM-dd HH:mm:ss',
    this.saveToVariable = '',
  }) : super(type: VisualStepType.dateTime);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'operation': operation,
        'value': value,
        'formatPattern': formatPattern,
        'saveToVariable': saveToVariable,
      };

  factory DateTimeStep.fromJson(Map<String, dynamic> json) => DateTimeStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Date & Time',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        operation: json['operation'] as String? ?? 'current',
        value: json['value'] as String? ?? '',
        formatPattern: json['formatPattern'] as String? ?? 'yyyy-MM-dd HH:mm:ss',
        saveToVariable: json['saveToVariable'] as String? ?? '',
      );
}
