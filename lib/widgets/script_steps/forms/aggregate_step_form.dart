import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';
import 'visual_step_text_field.dart';

class AggregateStepForm extends StatelessWidget {
  final String nodeId;
  final AggregateStep node;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const AggregateStepForm({
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
          label: 'Item a Acumular',
          source: node.itemSource,
          onChanged: (val) {
            node.itemSource = val;
            onUpdated(nodeId, node);
          },
        ),
        const SizedBox(height: 12),
        VisualStepTextField(
          value: node.targetListVariable,
          labelText: 'Variável de Destino (Lista)',
          onChanged: (val) {
            node.targetListVariable = val;
            onUpdated(nodeId, node);
          },
        ),
      ],
    );
  }
}
