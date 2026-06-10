import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/theme/app_colors.dart';
import 'value_source_form.dart';

class AssertValueStepForm extends StatelessWidget {
  final AssertValueStep step;
  final ValueChanged<AssertValueStep> onChanged;

  const AssertValueStepForm({
    super.key,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueSourceForm(
          label: 'Left Operand',
          source: step.leftSource,
          onChanged: (source) {
            step.leftSource = source;
            onChanged(step);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Operator: ', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: step.operator,
              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
              items: ['==', '!=', 'contains', '>', '<'].map((op) {
                return DropdownMenuItem(value: op, child: Text(op, style: const TextStyle(fontSize: 13)));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  step.operator = val;
                  onChanged(step);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        ValueSourceForm(
          label: 'Right Operand',
          source: step.rightSource,
          onChanged: (source) {
            step.rightSource = source;
            onChanged(step);
          },
        ),
      ],
    );
  }
}
