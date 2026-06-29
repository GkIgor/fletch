import '../visual_script.dart';

class DelayStep extends VisualStep {
  int durationMs;

  DelayStep({
    super.id,
    super.name = 'Delay',
    super.enabled,
    super.nextStepId,
    this.durationMs = 1000,
  }) : super(type: VisualStepType.delay);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'durationMs': durationMs,
      };

  factory DelayStep.fromJson(Map<String, dynamic> json) => DelayStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Delay',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        durationMs: json['durationMs'] as int? ?? 1000,
      );
}
