import 'package:fletch/models/visual_script.dart';
import 'package:fletch/utils/script_compiler.dart';

class CompiledSwitchStep extends CompiledStep {
  final CompiledValueSource valueSource;
  final List<SwitchCase> cases;
  final String? defaultStepId;

  CompiledSwitchStep({
    required super.id,
    required super.name,
    required this.valueSource,
    required this.cases,
    this.defaultStepId,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    final resolvedVal = valueSource.resolve(context);
    context.log(id, name, 'Avaliando Switch para o valor: "$resolvedVal"', level: LogLevel.info);

    for (var c in cases) {
      if (c.value == resolvedVal) {
        context.log(id, name, 'Caso correspondente encontrado: "${c.value}" -> Seguindo para nó "${c.nextStepId}"', level: LogLevel.info);
        return ExecutionResult(success: true, nextNodeId: c.nextStepId);
      }
    }

    context.log(id, name, 'Nenhum caso correspondeu. Seguindo para ramificação padrão: "$defaultStepId"', level: LogLevel.info);
    return ExecutionResult(success: true, nextNodeId: defaultStepId);
  }
}
