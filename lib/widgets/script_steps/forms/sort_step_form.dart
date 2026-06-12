import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';
import 'visual_step_text_field.dart';

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
        VisualStepTextField(
          value: node.sortByPath,
          labelText: 'Ordenar por (JSON Path)',
          onChanged: (val) {
            node.sortByPath = val;
            onUpdated(nodeId, node);
          },
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ordem Crescente', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              Switch(
                value: node.ascending,
                onChanged: (val) {
                  node.ascending = val;
                  onUpdated(nodeId, node);
                },
              ),
            ],
          ),
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
