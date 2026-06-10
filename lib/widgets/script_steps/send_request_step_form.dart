import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/theme/app_colors.dart';

class SendRequestStepForm extends StatefulWidget {
  final SendRequestStep step;
  final ValueChanged<SendRequestStep> onChanged;

  const SendRequestStepForm({
    super.key,
    required this.step,
    required this.onChanged,
  });

  @override
  State<SendRequestStepForm> createState() => _SendRequestStepFormState();
}

class _SendRequestStepFormState extends State<SendRequestStepForm> {
  late TextEditingController _urlController;
  late TextEditingController _varController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.step.url);
    _varController = TextEditingController(text: widget.step.saveToVariable);
  }

  @override
  void didUpdateWidget(covariant SendRequestStepForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.step.url != _urlController.text) {
      _urlController.text = widget.step.url;
    }
    if (widget.step.saveToVariable != _varController.text) {
      _varController.text = widget.step.saveToVariable;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _varController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.step.method,
                isDense: true,
                dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                items: ['GET', 'POST', 'PUT', 'DELETE'].map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(
                      m,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    widget.step.method = val;
                    widget.onChanged(widget.step);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                  hintText: 'https://api.example.com',
                ),
                style: const TextStyle(fontSize: 12),
                onChanged: (val) {
                  widget.step.url = val;
                  widget.onChanged(widget.step);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'Save response to:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _varController,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                  hintText: 'variable_name',
                ),
                style: const TextStyle(fontSize: 12),
                onChanged: (val) {
                  widget.step.saveToVariable = val;
                  widget.onChanged(widget.step);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
