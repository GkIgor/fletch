// Visual Script, ValueSource, and Graph-based Steps models for Fletch visual automation scripts.
import 'package:uuid/uuid.dart';

import 'visual_steps/set_variable_step.dart';
import 'visual_steps/assert_value_step.dart';
import 'visual_steps/if_step.dart';
import 'visual_steps/send_request_step.dart';
import 'visual_steps/delay_step.dart';
import 'visual_steps/switch_step.dart';
import 'visual_steps/merge_step.dart';
import 'visual_steps/split_out_step.dart';
import 'visual_steps/aggregate_step.dart';
import 'visual_steps/date_time_step.dart';
import 'visual_steps/sort_step.dart';
import 'visual_steps/limit_step.dart';
import 'visual_steps/remove_duplicates_step.dart';
import 'visual_steps/crypto_step.dart';
import 'visual_steps/json_convert_step.dart';
import 'visual_steps/xml_convert_step.dart';
import 'visual_steps/html_convert_step.dart';
import 'visual_steps/markdown_convert_step.dart';
import 'visual_steps/json_path_step.dart';
import 'visual_steps/header_builder_step.dart';
import 'visual_steps/start_step.dart';
import 'visual_steps/fail_step.dart';
import 'visual_steps/end_step.dart';

export 'visual_steps/set_variable_step.dart';
export 'visual_steps/assert_value_step.dart';
export 'visual_steps/if_step.dart';
export 'visual_steps/send_request_step.dart';
export 'visual_steps/delay_step.dart';
export 'visual_steps/switch_step.dart';
export 'visual_steps/merge_step.dart';
export 'visual_steps/split_out_step.dart';
export 'visual_steps/aggregate_step.dart';
export 'visual_steps/date_time_step.dart';
export 'visual_steps/sort_step.dart';
export 'visual_steps/limit_step.dart';
export 'visual_steps/remove_duplicates_step.dart';
export 'visual_steps/crypto_step.dart';
export 'visual_steps/json_convert_step.dart';
export 'visual_steps/xml_convert_step.dart';
export 'visual_steps/html_convert_step.dart';
export 'visual_steps/markdown_convert_step.dart';
export 'visual_steps/json_path_step.dart';
export 'visual_steps/header_builder_step.dart';
export 'visual_steps/start_step.dart';
export 'visual_steps/fail_step.dart';
export 'visual_steps/end_step.dart';

enum ScriptMode {
  lowCode,
  advanced,
}

enum VisualStepType {
  setVariable,
  assertValue,
  sendRequest,
  delay,
  switchStep,
  merge,
  splitOut,
  aggregate,
  dateTime,
  ifStep,
  sort,
  limit,
  removeDuplicates,
  crypto,
  jsonConvert,
  xmlConvert,
  htmlConvert,
  markdownConvert,
  jsonPathStep,
  headerBuilder,
  start,
  fail,
  end,
}

enum ValueSourceType {
  constant,          // Static text value
  responseBody,      // HTTP response body
  responseHeader,    // HTTP response header matching key
  responseStatusCode,// HTTP status code number
  variable,          // Workspace active variable matching name
}

/// A decoupled, granular representation of a data origin.
class ValueSource {
  final ValueSourceType type;
  final String key;      // Header key or variable name
  final String jsonPath; // Dot-notation path to extract fields from JSON values

  ValueSource({
    this.type = ValueSourceType.constant,
    this.key = '',
    this.jsonPath = '',
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'key': key,
        'jsonPath': jsonPath,
      };

  factory ValueSource.fromJson(Map<String, dynamic> json) => ValueSource(
        type: ValueSourceType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ValueSourceType.constant,
        ),
        key: json['key'] as String? ?? '',
        jsonPath: json['jsonPath'] as String? ?? '',
      );
}

/// Helper model for SetVariableStep representing a single variable assignment.
class VariableAssignment {
  String variableName;
  ValueSource valueSource;

  VariableAssignment({
    this.variableName = '',
    ValueSource? valueSource,
  }) : valueSource = valueSource ?? ValueSource();

  Map<String, dynamic> toJson() => {
        'variableName': variableName,
        'valueSource': valueSource.toJson(),
      };

  factory VariableAssignment.fromJson(Map<String, dynamic> json) => VariableAssignment(
        variableName: json['variableName'] as String? ?? '',
        valueSource: json['valueSource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['valueSource']))
            : ValueSource(),
      );
}

/// Helper model for SwitchStep representing a branch destination based on matching value.
class SwitchCase {
  String value;
  String? nextStepId;

  SwitchCase({
    this.value = '',
    this.nextStepId,
  });

  Map<String, dynamic> toJson() => {
        'value': value,
        'nextStepId': nextStepId,
      };

  factory SwitchCase.fromJson(Map<String, dynamic> json) => SwitchCase(
        value: json['value'] as String? ?? '',
        nextStepId: json['nextStepId'] as String?,
      );
}

abstract class VisualStep {
  final String id;
  final VisualStepType type;
  String name;
  bool enabled;
  String? nextStepId;

  VisualStep({
    String? id,
    required this.type,
    required this.name,
    this.enabled = true,
    this.nextStepId,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson();

  static VisualStep fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = VisualStepType.values.firstWhere((e) => e.name == typeStr);
    
    switch (type) {
      case VisualStepType.setVariable:
        return SetVariableStep.fromJson(json);
      case VisualStepType.assertValue:
        return AssertValueStep.fromJson(json);
      case VisualStepType.sendRequest:
        return SendRequestStep.fromJson(json);
      case VisualStepType.delay:
        return DelayStep.fromJson(json);
      case VisualStepType.switchStep:
        return SwitchStep.fromJson(json);
      case VisualStepType.merge:
        return MergeStep.fromJson(json);
      case VisualStepType.splitOut:
        return SplitOutStep.fromJson(json);
      case VisualStepType.aggregate:
        return AggregateStep.fromJson(json);
      case VisualStepType.dateTime:
        return DateTimeStep.fromJson(json);
      case VisualStepType.ifStep:
        return IfStep.fromJson(json);
      case VisualStepType.sort:
        return SortStep.fromJson(json);
      case VisualStepType.limit:
        return LimitStep.fromJson(json);
      case VisualStepType.removeDuplicates:
        return RemoveDuplicatesStep.fromJson(json);
      case VisualStepType.crypto:
        return CryptoStep.fromJson(json);
      case VisualStepType.jsonConvert:
        return JsonConvertStep.fromJson(json);
      case VisualStepType.xmlConvert:
        return XmlConvertStep.fromJson(json);
      case VisualStepType.htmlConvert:
        return HtmlConvertStep.fromJson(json);
      case VisualStepType.markdownConvert:
        return MarkdownConvertStep.fromJson(json);
      case VisualStepType.jsonPathStep:
        return JsonPathStep.fromJson(json);
      case VisualStepType.headerBuilder:
        return HeaderBuilderStep.fromJson(json);
      case VisualStepType.start:
        return StartStep.fromJson(json);
      case VisualStepType.fail:
        return FailStep.fromJson(json);
      case VisualStepType.end:
        return EndStep.fromJson(json);
    }
  }
}

class VisualScript {
  final String id;
  String name;
  bool isPreRequest;
  ScriptMode mode;
  Map<String, VisualStep> nodes;
  String? startNodeId;
  String advancedCode;
  DateTime updatedAt;

  VisualScript({
    String? id,
    required this.name,
    this.isPreRequest = true,
    this.mode = ScriptMode.lowCode,
    Map<String, VisualStep>? nodes,
    this.startNodeId,
    this.advancedCode = '',
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        nodes = nodes ?? {},
        updatedAt = updatedAt ?? DateTime.now();

  VisualScript copyWith({
    String? name,
    bool? isPreRequest,
    ScriptMode? mode,
    Map<String, VisualStep>? nodes,
    String? startNodeId,
    String? advancedCode,
    DateTime? updatedAt,
  }) {
    return VisualScript(
      id: id,
      name: name ?? this.name,
      isPreRequest: isPreRequest ?? this.isPreRequest,
      mode: mode ?? this.mode,
      nodes: nodes ?? this.nodes,
      startNodeId: startNodeId ?? this.startNodeId,
      advancedCode: advancedCode ?? this.advancedCode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isPreRequest': isPreRequest,
        'mode': mode.name,
        'nodes': nodes.map((k, v) => MapEntry(k, v.toJson())),
        'startNodeId': startNodeId,
        'advancedCode': advancedCode,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory VisualScript.fromJson(Map<String, dynamic> json) {
    final nodesJson = json['nodes'] as Map? ?? {};
    final Map<String, VisualStep> parsedNodes = {};
    nodesJson.forEach((k, v) {
      parsedNodes[k.toString()] = VisualStep.fromJson(Map<String, dynamic>.from(v));
    });

    return VisualScript(
      id: json['id'] as String,
      name: json['name'] as String,
      isPreRequest: json['isPreRequest'] as bool? ?? true,
      mode: ScriptMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => ScriptMode.lowCode,
      ),
      nodes: parsedNodes,
      startNodeId: json['startNodeId'] as String?,
      advancedCode: json['advancedCode'] as String? ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
