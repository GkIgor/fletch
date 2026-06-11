import 'package:fletch/utils/script_compiler.dart';

class CompiledDateTimeStep extends CompiledStep {
  final String? nextStepId;
  final String operation;
  final String value;
  final String formatPattern;
  final String saveToVariable;

  CompiledDateTimeStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.operation,
    required this.value,
    required this.formatPattern,
    required this.saveToVariable,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    if (saveToVariable.isEmpty) {
      return ExecutionResult(success: true, nextNodeId: nextStepId);
    }

    DateTime now = DateTime.now();

    if (operation == 'add' || operation == 'subtract') {
      final multiplier = operation == 'add' ? 1 : -1;
      final parts = value.split(' ');
      if (parts.length >= 2) {
        final amount = int.tryParse(parts[0]) ?? 0;
        final unit = parts[1].toLowerCase();
        if (unit.contains('day')) {
          now = now.add(Duration(days: amount * multiplier));
        } else if (unit.contains('hour')) {
          now = now.add(Duration(hours: amount * multiplier));
        } else if (unit.contains('minute')) {
          now = now.add(Duration(minutes: amount * multiplier));
        } else if (unit.contains('second')) {
          now = now.add(Duration(seconds: amount * multiplier));
        }
      }
    }

    String result;
    if (formatPattern == 'timestampMs') {
      result = now.millisecondsSinceEpoch.toString();
    } else {
      // In Fletch, we can use simple format mapper, or fallback to ISO String
      result = now.toIso8601String();
    }

    context.variables[saveToVariable] = result;
    context.log(id, name, 'Data calculada ($operation): $result salva em "$saveToVariable"', level: LogLevel.info);
    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }
}
