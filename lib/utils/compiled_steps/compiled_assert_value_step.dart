import 'package:fletch/utils/script_compiler.dart';

class CompiledAssertValueStep extends CompiledStep {
  final String? nextStepId;
  final CompiledValueSource left;
  final String operator;
  final CompiledValueSource right;

  CompiledAssertValueStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.left,
    required this.operator,
    required this.right,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    final leftVal = left.resolve(context);
    final rightVal = right.resolve(context);

    bool isPassed = false;
    switch (operator) {
      case '==':
        isPassed = leftVal == rightVal;
        break;
      case '!=':
        isPassed = leftVal != rightVal;
        break;
      case 'contains':
        isPassed = leftVal.contains(rightVal);
        break;
      case '>':
        final lNum = double.tryParse(leftVal);
        final rNum = double.tryParse(rightVal);
        isPassed = (lNum != null && rNum != null) ? lNum > rNum : false;
        break;
      case '<':
        final lNum = double.tryParse(leftVal);
        final rNum = double.tryParse(rightVal);
        isPassed = (lNum != null && rNum != null) ? lNum < rNum : false;
        break;
    }

    if (!isPassed) {
      context.log(id, name, 'Asserção falhou: "$leftVal" $operator "$rightVal"', level: LogLevel.error);
      return ExecutionResult(
        success: false,
        error: 'Assertion Failed: "$leftVal" $operator "$rightVal"',
      );
    }

    context.log(id, name, 'Asserção passou: "$leftVal" $operator "$rightVal"', level: LogLevel.info);
    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }
}
