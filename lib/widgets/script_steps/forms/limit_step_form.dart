import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';

class LimitStepForm extends StatelessWidget {
  final String nodeId;
  final LimitStep node;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const LimitStepForm({
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
          controller: TextEditingController(text: node.limit.toString())
            ..selection = TextSelection.collapsed(offset: node.limit.toString().length),
          decoration: const InputDecoration(labelText: 'Limite (Limit)', labelStyle: TextStyle(fontSize: 11)),
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 12),
          onChanged: (val) {
            final parsed = int.tryParse(val);
            if (parsed != null) {
              node.limit = parsed;
              onUpdated(nodeId, node);
            }
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: TextEditingController(text: node.offset.toString())
            ..selection = TextSelection.collapsed(offset: node.offset.toString().length),
          decoration: const InputDecoration(labelText: 'Deslocamento (Offset)', labelStyle: TextStyle(fontSize: 11)),
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 12),
          onChanged: (val) {
            final parsed = int.tryParse(val);
            if (parsed != null) {
              node.offset = parsed;
              onUpdated(nodeId, node);
            }
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
