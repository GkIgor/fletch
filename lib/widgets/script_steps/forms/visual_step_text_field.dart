import 'package:flutter/material.dart';

class VisualStepTextField extends StatefulWidget {
  final String value;
  final String labelText;
  final String? hintText;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final TextStyle? style;
  final InputDecoration? decoration;
  final bool isDense;

  const VisualStepTextField({
    super.key,
    required this.value,
    required this.labelText,
    this.hintText,
    required this.onChanged,
    this.keyboardType,
    this.style,
    this.decoration,
    this.isDense = true,
  });

  @override
  State<VisualStepTextField> createState() => _VisualStepTextFieldState();
}

class _VisualStepTextFieldState extends State<VisualStepTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant VisualStepTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      // Position the cursor at the end when externally updated
      _controller.selection = TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: widget.decoration ??
          InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            labelStyle: const TextStyle(fontSize: 11),
            isDense: widget.isDense,
          ),
      keyboardType: widget.keyboardType,
      style: widget.style ?? const TextStyle(fontSize: 12),
      onChanged: widget.onChanged,
    );
  }
}
