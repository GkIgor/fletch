import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'visual_step_text_field.dart';

class DelayStepForm extends StatelessWidget {
  final String nodeId;
  final DelayStep node;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const DelayStepForm({
    super.key,
    required this.nodeId,
    required this.node,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return VisualStepTextField(
      value: node.durationMs.toString(),
      labelText: 'Duração (ms)',
      keyboardType: TextInputType.number,
      onChanged: (val) {
        final parsed = int.tryParse(val);
        if (parsed != null) {
          node.durationMs = parsed;
          onUpdated(nodeId, node);
        }
      },
    );
  }
}
