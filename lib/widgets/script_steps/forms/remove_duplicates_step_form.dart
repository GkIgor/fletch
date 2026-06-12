import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';
import 'visual_step_text_field.dart';

class RemoveDuplicatesStepForm extends StatelessWidget {
  final String nodeId;
  final RemoveDuplicatesStep node;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const RemoveDuplicatesStepForm({
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
          label: 'Array de Origem',
          source: node.arraySource,
          onChanged: (val) {
            node.arraySource = val;
            onUpdated(nodeId, node);
          },
        ),
        const SizedBox(height: 12),
        VisualStepTextField(
          value: node.comparePath,
          labelText: 'Comparar por (JSON Path)',
          onChanged: (val) {
            node.comparePath = val;
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
