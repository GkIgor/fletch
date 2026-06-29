import '../visual_script.dart';

class MergeStep extends VisualStep {
  String strategy; // "deepMerge", "concatLists", "zip"
  List<String> sources; // List of variable names/keys to merge
  String saveTo;

  MergeStep({
    super.id,
    super.name = 'Merge',
    super.enabled,
    super.nextStepId,
    this.strategy = 'deepMerge',
    List<String>? sources,
    this.saveTo = '',
  })  : sources = sources ?? [],
        super(type: VisualStepType.merge);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'strategy': strategy,
        'sources': sources,
        'saveTo': saveTo,
      };

  factory MergeStep.fromJson(Map<String, dynamic> json) => MergeStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Merge',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        strategy: json['strategy'] as String? ?? 'deepMerge',
        sources: List<String>.from(json['sources'] ?? []),
        saveTo: json['saveTo'] as String? ?? '',
      );
}
