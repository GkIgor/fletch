import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';
import 'visual_step_text_field.dart';

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
        VisualStepTextField(
          value: node.maxConcurrency.toString(),
          labelText: 'Concorrência Máxima',
          keyboardType: TextInputType.number,
          onChanged: (val) {
            final parsed = int.tryParse(val);
            if (parsed != null) {
              node.maxConcurrency = parsed;
              onUpdated(nodeId, node);
            }
          },
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Executar em Paralelo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              Switch(
                value: node.runInParallel,
                onChanged: (val) {
                  node.runInParallel = val;
                  onUpdated(nodeId, node);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
