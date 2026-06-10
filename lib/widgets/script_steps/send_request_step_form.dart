import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/theme/app_colors.dart';

class SendRequestStepForm extends StatelessWidget {
  final SendRequestStep step;
  final ValueChanged<SendRequestStep> onChanged;

  const SendRequestStepForm({
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
        Row(
          children: [
            DropdownButton<String>(
              value: step.method,
              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
              items: ['GET', 'POST', 'PUT', 'DELETE'].map((m) {
                return DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  step.method = val;
                  onChanged(step);
                }
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: TextEditingController(text: step.url)..selection = TextSelection.collapsed(offset: step.url.length),
                decoration: const InputDecoration(
                  labelText: 'Request URL',
                  hintText: 'https://api.example.com',
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (val) {
                  step.url = val;
                  onChanged(step);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: TextEditingController(text: step.saveToVariable)..selection = TextSelection.collapsed(offset: step.saveToVariable.length),
          decoration: const InputDecoration(
            labelText: 'Save Response to Variable',
            hintText: 'e.g. login_response',
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: (val) {
            step.saveToVariable = val;
            onChanged(step);
          },
        ),
      ],
    );
  }
}
