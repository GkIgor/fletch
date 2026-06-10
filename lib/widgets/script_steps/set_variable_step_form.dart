import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'value_source_form.dart';

class SetVariableStepForm extends StatelessWidget {
  final SetVariableStep step;
  final ValueChanged<SetVariableStep> onChanged;

  const SetVariableStepForm({
    super.key,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: TextEditingController(text: step.variableName)..selection = TextSelection.collapsed(offset: step.variableName.length),
          decoration: const InputDecoration(
            labelText: 'Variable Name',
            hintText: 'e.g. auth_token',
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: (val) {
            step.variableName = val;
            onChanged(step);
          },
        ),
        const SizedBox(height: 16),
        ValueSourceForm(
          label: 'Value Source',
          source: step.valueSource,
          onChanged: (source) {
            step.valueSource = source;
            onChanged(step);
          },
        ),
      ],
    );
  }
}
