import '../visual_script.dart';

class SwitchStep extends VisualStep {
  ValueSource valueSource;
  List<SwitchCase> cases;
  String? defaultStepId;

  SwitchStep({
    super.id,
    super.name = 'Switch',
    super.enabled,
    super.nextStepId,
    ValueSource? valueSource,
    List<SwitchCase>? cases,
    this.defaultStepId,
  })  : valueSource = valueSource ?? ValueSource(),
        cases = cases ?? [],
        super(type: VisualStepType.switchStep);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'valueSource': valueSource.toJson(),
        'cases': cases.map((e) => e.toJson()).toList(),
        'defaultStepId': defaultStepId,
      };

  factory SwitchStep.fromJson(Map<String, dynamic> json) => SwitchStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Switch',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        valueSource: json['valueSource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['valueSource']))
            : ValueSource(),
        cases: (json['cases'] as List?)
            ?.map((e) => SwitchCase.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        defaultStepId: json['defaultStepId'] as String?,
      );
}
