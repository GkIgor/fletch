import '../visual_script.dart';

class RemoveDuplicatesStep extends VisualStep {
  ValueSource arraySource;
  String comparePath;
  String saveToVariable;

  RemoveDuplicatesStep({
    super.id,
    super.name = 'Remove Duplicates',
    super.enabled,
    super.nextStepId,
    ValueSource? arraySource,
    this.comparePath = '',
    this.saveToVariable = '',
  })  : arraySource = arraySource ?? ValueSource(),
        super(type: VisualStepType.removeDuplicates);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'arraySource': arraySource.toJson(),
        'comparePath': comparePath,
        'saveToVariable': saveToVariable,
      };

  factory RemoveDuplicatesStep.fromJson(Map<String, dynamic> json) => RemoveDuplicatesStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Remove Duplicates',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        arraySource: json['arraySource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['arraySource']))
            : ValueSource(),
        comparePath: json['comparePath'] as String? ?? '',
        saveToVariable: json['saveToVariable'] as String? ?? '',
      );
}
