import '../visual_script.dart';

class LimitStep extends VisualStep {
  ValueSource arraySource;
  int limit;
  int offset;
  String saveToVariable;

  LimitStep({
    super.id,
    super.name = 'Limit',
    super.enabled,
    super.nextStepId,
    ValueSource? arraySource,
    this.limit = 10,
    this.offset = 0,
    this.saveToVariable = '',
  })  : arraySource = arraySource ?? ValueSource(),
        super(type: VisualStepType.limit);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'arraySource': arraySource.toJson(),
        'limit': limit,
        'offset': offset,
        'saveToVariable': saveToVariable,
      };

  factory LimitStep.fromJson(Map<String, dynamic> json) => LimitStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Limit',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        arraySource: json['arraySource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['arraySource']))
            : ValueSource(),
        limit: json['limit'] as int? ?? 10,
        offset: json['offset'] as int? ?? 0,
        saveToVariable: json['saveToVariable'] as String? ?? '',
      );
}
