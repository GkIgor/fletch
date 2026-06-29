import '../visual_script.dart';

class SetVariableStep extends VisualStep {
  List<VariableAssignment> assignments;

  SetVariableStep({
    super.id,
    super.name = 'Set/Edit Fields',
    super.enabled,
    super.nextStepId,
    List<VariableAssignment>? assignments,
  })  : assignments = assignments ?? [],
        super(type: VisualStepType.setVariable);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'assignments': assignments.map((e) => e.toJson()).toList(),
      };

  factory SetVariableStep.fromJson(Map<String, dynamic> json) => SetVariableStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Set/Edit Fields',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        assignments: (json['assignments'] as List?)
            ?.map((e) => VariableAssignment.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
