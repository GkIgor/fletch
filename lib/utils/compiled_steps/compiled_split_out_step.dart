import 'dart:convert';
import 'package:fletch/utils/script_compiler.dart';

class CompiledSplitOutStep extends CompiledStep {
  final String? nextStepId;
  final CompiledValueSource arraySource;
  final String? loopStepId;
  final bool runInParallel;
  final int maxConcurrency;

  CompiledSplitOutStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.arraySource,
    this.loopStepId,
    required this.runInParallel,
    required this.maxConcurrency,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    final arrayVal = arraySource.resolve(context);
    if (arrayVal.isEmpty || loopStepId == null) {
      context.log(id, name, 'Loop Split Out abortado: array de origem vazio ou loop vazio.', level: LogLevel.warn);
      return ExecutionResult(success: true, nextNodeId: nextStepId);
    }

    List<dynamic> items = [];
    try {
      final decoded = jsonDecode(arrayVal);
      if (decoded is List) {
        items = decoded;
      } else {
        items = [decoded];
      }
    } catch (_) {
      items = [arrayVal];
    }

    context.log(id, name, 'Iniciando loop Split Out para ${items.length} itens (Paralelo: $runInParallel).', level: LogLevel.info);

    Future<void> runItem(dynamic item, int index) async {
      final itemStr = item is Map || item is List ? jsonEncode(item) : item.toString();
      
      // Setup loop iteration variables in sub-context
      final loopContext = ExecutionContext(
        variables: Map<String, String>.from(context.variables)
          ..['item'] = itemStr
          ..['index'] = index.toString(),
        headers: context.headers,
        queryParams: context.queryParams,
        url: context.url,
        body: context.body,
        statusCode: context.statusCode,
        responseBody: context.responseBody,
        responseHeaders: context.responseHeaders,
      );

      String? currentId = loopStepId;
      int stepCount = 0;
      while (currentId != null && stepCount < 500) {
        final step = nodes[currentId];
        if (step == null) break;
        stepCount++;
        final res = await step.execute(loopContext, nodes);
        if (!res.success) {
          throw Exception('Iteração do loop falhou no nó "${step.name}": ${res.error}');
        }
        currentId = res.nextNodeId;
      }

      // Propagate variables back (except loop local scope)
      loopContext.variables.forEach((k, v) {
        if (k != 'item' && k != 'index') {
          context.variables[k] = v;
        }
      });
      // Append sub-logs
      context.logs.addAll(loopContext.logs);
    }

    if (runInParallel) {
      // Chunk concurrent executions using maxConcurrency
      final int limit = maxConcurrency > 0 ? maxConcurrency : 5;
      for (int i = 0; i < items.length; i += limit) {
        final chunk = items.skip(i).take(limit).toList();
        final List<Future<void>> futures = [];
        for (int j = 0; j < chunk.length; j++) {
          futures.add(runItem(chunk[j], i + j));
        }
        await Future.wait(futures);
      }
    } else {
      // Sequential loop
      for (int i = 0; i < items.length; i++) {
        await runItem(items[i], i);
      }
    }

    context.log(id, name, 'Loop Split Out concluído.', level: LogLevel.info);
    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }
}
