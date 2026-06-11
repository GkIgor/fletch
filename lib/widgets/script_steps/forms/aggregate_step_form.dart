import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';

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
        TextField(
          controller: TextEditingController(text: node.targetListVariable)
            ..selection = TextSelection.collapsed(offset: node.targetListVariable.length),
          decoration: const InputDecoration(labelText: 'Variável de Destino (Lista)', labelStyle: TextStyle(fontSize: 11)),
          style: const TextStyle(fontSize: 12),
          onChanged: (val) {
            node.targetListVariable = val;
            onUpdated(nodeId, node);
          },
        ),
      ],
    );
  }
}
