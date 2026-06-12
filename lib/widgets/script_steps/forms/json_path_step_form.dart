import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';
import 'visual_step_text_field.dart';

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
        VisualStepTextField(
          value: node.jsonPathExpression,
          labelText: 'Caminho Dot Notation (e.g. data.items[0].name)',
          onChanged: (val) {
            node.jsonPathExpression = val;
            onUpdated(nodeId, node);
          },
        ),
        const SizedBox(height: 12),
        VisualStepTextField(
          value: node.saveToVariable,
          labelText: 'Salvar Resultado em',
          onChanged: (val) {
            node.saveToVariable = val;
            onUpdated(nodeId, node);
          },
        ),
      ],
    );
  }
}
