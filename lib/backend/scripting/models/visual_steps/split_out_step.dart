import '../visual_script.dart';

class SplitOutStep extends VisualStep {
  ValueSource arraySource;
  String? loopStepId;
  bool runInParallel;
  int maxConcurrency;

  SplitOutStep({
    super.id,
    super.name = 'Split Out',
    super.enabled,
    super.nextStepId,
    ValueSource? arraySource,
    this.loopStepId,
    this.runInParallel = false,
    this.maxConcurrency = 5,
  })  : arraySource = arraySource ?? ValueSource(),
        super(type: VisualStepType.splitOut);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'arraySource': arraySource.toJson(),
        'loopStepId': loopStepId,
        'runInParallel': runInParallel,
        'maxConcurrency': maxConcurrency,
      };

  factory SplitOutStep.fromJson(Map<String, dynamic> json) => SplitOutStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Split Out',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        arraySource: json['arraySource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['arraySource']))
            : ValueSource(),
        loopStepId: json['loopStepId'] as String?,
        runInParallel: json['runInParallel'] as bool? ?? false,
        maxConcurrency: json['maxConcurrency'] as int? ?? 5,
      );
}
