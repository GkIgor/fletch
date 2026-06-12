import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';
import 'visual_step_text_field.dart';

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
        VisualStepTextField(
          value: node.limit.toString(),
          labelText: 'Limite (Limit)',
          keyboardType: TextInputType.number,
          onChanged: (val) {
            final parsed = int.tryParse(val);
            if (parsed != null) {
              node.limit = parsed;
              onUpdated(nodeId, node);
            }
          },
        ),
        const SizedBox(height: 12),
        VisualStepTextField(
          value: node.offset.toString(),
          labelText: 'Deslocamento (Offset)',
          keyboardType: TextInputType.number,
          onChanged: (val) {
            final parsed = int.tryParse(val);
            if (parsed != null) {
              node.offset = parsed;
              onUpdated(nodeId, node);
            }
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
