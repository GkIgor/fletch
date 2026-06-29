import '../visual_script.dart';

class FailStep extends VisualStep {
  FailStep({
    super.id,
    super.name = 'Fail',
    super.enabled,
    super.nextStepId,
  }) : super(type: VisualStepType.fail);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
      };

  factory FailStep.fromJson(Map<String, dynamic> json) => FailStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Fail',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
      );
}
