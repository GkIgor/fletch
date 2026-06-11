import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';

class JsonPathStepForm extends StatelessWidget {
  final String nodeId;
  final JsonPathStep node;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const JsonPathStepForm({
    super.key,
    required this.nodeId,
    required this.node,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueSourceForm(
          label: 'Valor de Origem (Objeto/Array)',
          source: node.valueSource,
          onChanged: (val) {
            node.valueSource = val;
            onUpdated(nodeId, node);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: TextEditingController(text: node.jsonPathExpression)
            ..selection = TextSelection.collapsed(offset: node.jsonPathExpression.length),
          decoration: const InputDecoration(labelText: 'Caminho Dot Notation (e.g. data.items[0].name)', labelStyle: TextStyle(fontSize: 11)),
          style: const TextStyle(fontSize: 12),
          onChanged: (val) {
            node.jsonPathExpression = val;
            onUpdated(nodeId, node);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: TextEditingController(text: node.saveToVariable)
            ..selection = TextSelection.collapsed(offset: node.saveToVariable.length),
          decoration: const InputDecoration(labelText: 'Salvar Resultado em', labelStyle: TextStyle(fontSize: 11)),
          style: const TextStyle(fontSize: 12),
          onChanged: (val) {
            node.saveToVariable = val;
            onUpdated(nodeId, node);
          },
        ),
      ],
    );
  }
}
