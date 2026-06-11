import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';

class SplitOutStepForm extends StatelessWidget {
  final String nodeId;
  final SplitOutStep node;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const SplitOutStepForm({
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
          controller: TextEditingController(text: node.maxConcurrency.toString())
            ..selection = TextSelection.collapsed(offset: node.maxConcurrency.toString().length),
          decoration: const InputDecoration(labelText: 'Concorrência Máxima', labelStyle: TextStyle(fontSize: 11)),
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 12),
          onChanged: (val) {
            final parsed = int.tryParse(val);
            if (parsed != null) {
              node.maxConcurrency = parsed;
              onUpdated(nodeId, node);
            }
          },
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Executar em Paralelo', style: TextStyle(fontSize: 11)),
          value: node.runInParallel,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            node.runInParallel = val;
            onUpdated(nodeId, node);
          },
        ),
      ],
    );
  }
}
