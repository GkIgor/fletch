import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';
import 'visual_step_text_field.dart';

class SwitchStepForm extends StatelessWidget {
  final String nodeId;
  final SwitchStep node;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const SwitchStepForm({
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
          label: 'Variável de Origem',
          source: node.valueSource,
          onChanged: (val) {
            node.valueSource = val;
            onUpdated(nodeId, node);
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Casos de Teste', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.green),
              onPressed: () {
                node.cases.add(SwitchCase(value: 'valor_${node.cases.length + 1}'));
                onUpdated(nodeId, node);
              },
            ),
          ],
        ),
        ...node.cases.asMap().entries.map((e) {
          final idx = e.key;
          final c = e.value;
          return Row(
            children: [
              Expanded(
                child: VisualStepTextField(
                  value: c.value,
                  labelText: 'Caso ${idx + 1}',
                  onChanged: (val) {
                    c.value = val;
                    onUpdated(nodeId, node);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                onPressed: () {
                  node.cases.removeAt(idx);
                  onUpdated(nodeId, node);
                },
              )
            ],
          );
        }),
      ],
    );
  }
}
