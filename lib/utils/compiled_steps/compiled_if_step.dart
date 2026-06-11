import 'package:fletch/utils/script_compiler.dart';

class CompiledIfStep extends CompiledStep {
  final CompiledValueSource left;
  final String operator;
  final CompiledValueSource right;
  final String? trueStepId;
  final String? falseStepId;

  CompiledIfStep({
    required super.id,
    required super.name,
    required this.left,
    required this.operator,
    required this.right,
    this.trueStepId,
    this.falseStepId,
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

    if (isPassed) {
      context.log(id, name, 'Condição IF verdadeira: "$leftVal" $operator "$rightVal". Seguindo caminho True.', level: LogLevel.info);
      return ExecutionResult(success: true, nextNodeId: trueStepId);
    } else {
      context.log(id, name, 'Condição IF falsa: "$leftVal" $operator "$rightVal". Seguindo caminho False.', level: LogLevel.info);
      return ExecutionResult(success: true, nextNodeId: falseStepId);
    }
  }
}
