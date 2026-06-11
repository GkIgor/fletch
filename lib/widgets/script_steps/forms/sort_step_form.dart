import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';

class SortStepForm extends StatelessWidget {
  final String nodeId;
  final SortStep node;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const SortStepForm({
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
          controller: TextEditingController(text: node.sortByPath)
            ..selection = TextSelection.collapsed(offset: node.sortByPath.length),
          decoration: const InputDecoration(labelText: 'Ordenar por (JSON Path)', labelStyle: TextStyle(fontSize: 11)),
          style: const TextStyle(fontSize: 12),
          onChanged: (val) {
            node.sortByPath = val;
            onUpdated(nodeId, node);
          },
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Ordem Crescente', style: TextStyle(fontSize: 11)),
          value: node.ascending,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            node.ascending = val;
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
