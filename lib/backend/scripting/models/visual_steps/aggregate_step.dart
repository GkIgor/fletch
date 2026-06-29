import '../visual_script.dart';

class AggregateStep extends VisualStep {
  ValueSource itemSource;
  String targetListVariable;

  AggregateStep({
    super.id,
    super.name = 'Aggregate',
    super.enabled,
    super.nextStepId,
    ValueSource? itemSource,
    this.targetListVariable = '',
  })  : itemSource = itemSource ?? ValueSource(),
        super(type: VisualStepType.aggregate);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'itemSource': itemSource.toJson(),
        'targetListVariable': targetListVariable,
      };

  factory AggregateStep.fromJson(Map<String, dynamic> json) => AggregateStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Aggregate',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        itemSource: json['itemSource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['itemSource']))
            : ValueSource(),
        targetListVariable: json['targetListVariable'] as String? ?? '',
      );
}
