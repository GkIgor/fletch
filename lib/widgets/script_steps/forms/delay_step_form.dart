import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';

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
    return TextField(
      controller: TextEditingController(text: node.durationMs.toString())
        ..selection = TextSelection.collapsed(offset: node.durationMs.toString().length),
      decoration: const InputDecoration(labelText: 'Duração (ms)', labelStyle: TextStyle(fontSize: 11)),
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 12),
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
