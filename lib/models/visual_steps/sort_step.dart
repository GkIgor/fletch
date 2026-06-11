import '../visual_script.dart';

class SortStep extends VisualStep {
  ValueSource arraySource;
  String sortByPath;
  bool ascending;
  String saveToVariable;

  SortStep({
    super.id,
    super.name = 'Sort',
    super.enabled,
    super.nextStepId,
    ValueSource? arraySource,
    this.sortByPath = '',
    this.ascending = true,
    this.saveToVariable = '',
  })  : arraySource = arraySource ?? ValueSource(),
        super(type: VisualStepType.sort);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'arraySource': arraySource.toJson(),
        'sortByPath': sortByPath,
        'ascending': ascending,
        'saveToVariable': saveToVariable,
      };

  factory SortStep.fromJson(Map<String, dynamic> json) => SortStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Sort',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        arraySource: json['arraySource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['arraySource']))
            : ValueSource(),
        sortByPath: json['sortByPath'] as String? ?? '',
        ascending: json['ascending'] as bool? ?? true,
        saveToVariable: json['saveToVariable'] as String? ?? '',
      );
}
