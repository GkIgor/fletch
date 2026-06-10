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

    return Row(
      children: [
        Expanded(
          child: ValueSourceInlineEditor(
            source: step.leftSource,
            onChanged: (source) {
              step.leftSource = source;
              onChanged(step);
            },
          ),
        ),
        const SizedBox(width: 8),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: step.operator,
            isDense: true,
            dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
            items: ['==', '!=', 'contains', '>', '<'].map((op) {
              return DropdownMenuItem(
                value: op,
                child: Text(
                  op,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                step.operator = val;
                onChanged(step);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ValueSourceInlineEditor(
            source: step.rightSource,
            onChanged: (source) {
              step.rightSource = source;
              onChanged(step);
            },
          ),
        ),
      ],
    );
  }
}
