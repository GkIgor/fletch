import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';

class DelayStepForm extends StatefulWidget {
  final DelayStep step;
  final ValueChanged<DelayStep> onChanged;

  const DelayStepForm({
    super.key,
    required this.step,
    required this.onChanged,
  });

  @override
  State<DelayStepForm> createState() => _DelayStepFormState();
}

class _DelayStepFormState extends State<DelayStepForm> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.step.durationMs.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant DelayStepForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync text field if the value was updated externally (e.g. undo action),
    // but avoid overriding active focus text length discrepancies.
    final externalVal = widget.step.durationMs.toString();
    if (externalVal != _controller.text && !_controller.selection.isValid) {
      _controller.text = externalVal;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.hourglass_top_rounded, size: 14, color: Colors.teal),
        const SizedBox(width: 8),
        const Text(
          'Delay execution for',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
              hintText: '1000',
            ),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            onChanged: (val) {
              final parsed = int.tryParse(val);
              if (parsed != null) {
                widget.step.durationMs = parsed;
                widget.onChanged(widget.step);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'ms',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
