import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';

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
        TextField(
          controller: TextEditingController(text: node.comparePath)
            ..selection = TextSelection.collapsed(offset: node.comparePath.length),
          decoration: const InputDecoration(labelText: 'Comparar por (JSON Path)', labelStyle: TextStyle(fontSize: 11)),
          style: const TextStyle(fontSize: 12),
          onChanged: (val) {
            node.comparePath = val;
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
