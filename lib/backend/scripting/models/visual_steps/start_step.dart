import '../visual_script.dart';

class StartStep extends VisualStep {
  StartStep({
    super.id,
    super.name = 'Início',
    super.enabled,
    super.nextStepId,
  }) : super(type: VisualStepType.start);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
      };

  factory StartStep.fromJson(Map<String, dynamic> json) => StartStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Início',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
      );
}
