import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';

class DelayStepForm extends StatelessWidget {
  final DelayStep step;
  final ValueChanged<DelayStep> onChanged;

  const DelayStepForm({
    super.key,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: step.durationMs.toString())..selection = TextSelection.collapsed(offset: step.durationMs.toString().length),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Duration (ms)',
        hintText: 'e.g. 1000',
      ),
      style: const TextStyle(fontSize: 13),
      onChanged: (val) {
        step.durationMs = int.tryParse(val) ?? 1000;
        onChanged(step);
      },
    );
  }
}
