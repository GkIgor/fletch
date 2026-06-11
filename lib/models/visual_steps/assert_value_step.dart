import '../visual_script.dart';

class AssertValueStep extends VisualStep {
  ValueSource leftSource;
  String operator;         // e.g. "==", "!=", "contains", ">", "<"
  ValueSource rightSource;

  AssertValueStep({
    super.id,
    super.name = 'Assert Value',
    super.enabled,
    super.nextStepId,
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
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'leftSource': leftSource.toJson(),
        'operator': operator,
        'rightSource': rightSource.toJson(),
      };

  factory AssertValueStep.fromJson(Map<String, dynamic> json) => AssertValueStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Assert Value',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        leftSource: json['leftSource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['leftSource']))
            : ValueSource(),
        operator: json['operator'] as String? ?? '==',
        rightSource: json['rightSource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['rightSource']))
            : ValueSource(),
      );
}
