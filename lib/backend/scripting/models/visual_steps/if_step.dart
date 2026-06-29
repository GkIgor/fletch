import '../visual_script.dart';

class IfStep extends VisualStep {
  ValueSource leftSource;
  String operator;         // e.g. "==", "!=", "contains", ">", "<"
  ValueSource rightSource;
  String? trueStepId;
  String? falseStepId;

  IfStep({
    super.id,
    super.name = 'If Condition',
    super.enabled,
    super.nextStepId,
    ValueSource? leftSource,
    this.operator = '==',
    ValueSource? rightSource,
    this.trueStepId,
    this.falseStepId,
  })  : leftSource = leftSource ?? ValueSource(),
        rightSource = rightSource ?? ValueSource(),
        super(type: VisualStepType.ifStep);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'leftSource': leftSource.toJson(),
        'operator': operator,
        'rightSource': rightSource.toJson(),
        'trueStepId': trueStepId,
        'falseStepId': falseStepId,
      };

  factory IfStep.fromJson(Map<String, dynamic> json) => IfStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'If Condition',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        leftSource: json['leftSource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['leftSource']))
            : ValueSource(),
        operator: json['operator'] as String? ?? '==',
        rightSource: json['rightSource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['rightSource']))
            : ValueSource(),
        trueStepId: json['trueStepId'] as String?,
        falseStepId: json['falseStepId'] as String?,
      );
}
