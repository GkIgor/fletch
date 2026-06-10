import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'value_source_form.dart';

class SetVariableStepForm extends StatefulWidget {
  final SetVariableStep step;
  final ValueChanged<SetVariableStep> onChanged;

  const SetVariableStepForm({
    super.key,
    required this.step,
    required this.onChanged,
  });

  @override
  State<SetVariableStepForm> createState() => _SetVariableStepFormState();
}

class _SetVariableStepFormState extends State<SetVariableStepForm> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.step.variableName);
  }

  @override
  void didUpdateWidget(covariant SetVariableStepForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.step.variableName != _nameController.text) {
      _nameController.text = widget.step.variableName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Set',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
              hintText: 'variable_name',
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: (val) {
              widget.step.variableName = val;
              widget.onChanged(widget.step);
            },
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'to',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: ValueSourceInlineEditor(
            source: widget.step.valueSource,
            onChanged: (source) {
              widget.step.valueSource = source;
              widget.onChanged(widget.step);
            },
          ),
        ),
      ],
    );
  }
}
