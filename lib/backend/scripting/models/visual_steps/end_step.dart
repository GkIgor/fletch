import '../visual_script.dart';

class EndStep extends VisualStep {
  EndStep({
    super.id,
    super.name = 'End',
    super.enabled,
    super.nextStepId,
  }) : super(type: VisualStepType.end);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
      };

  factory EndStep.fromJson(Map<String, dynamic> json) => EndStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'End',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
      );
}
