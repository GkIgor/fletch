import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/theme/app_colors.dart';
import 'forms/visual_step_text_field.dart';

class ValueSourceForm extends StatelessWidget {
  final String label;
  final ValueSource source;
  final ValueChanged<ValueSource> onChanged;

  const ValueSourceForm({
    super.key,
    required this.label,
    required this.source,
    required this.onChanged,
  });

  String _getValueSourceTypeName(ValueSourceType type) {
    switch (type) {
      case ValueSourceType.constant: return 'Constant';
      case ValueSourceType.responseBody: return 'Response JSON Body';
      case ValueSourceType.responseHeader: return 'Response Header';
      case ValueSourceType.responseStatusCode: return 'Response Status';
      case ValueSourceType.variable: return 'Active Variable';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.sidebarDark : AppColors.slate50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<ValueSourceType>(
                  value: source.type,
                  isDense: true,
                  dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                  items: ValueSourceType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        _getValueSourceTypeName(type),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      onChanged(
                        ValueSource(
                          type: val,
                          key: source.key,
                          jsonPath: source.jsonPath,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          if (source.type == ValueSourceType.constant ||
              source.type == ValueSourceType.variable ||
              source.type == ValueSourceType.responseHeader) ...[
            const SizedBox(height: 6),
            VisualStepTextField(
              value: source.key,
              labelText: source.type == ValueSourceType.constant
                  ? 'Constant Value'
                  : 'Key Name',
              hintText: source.type == ValueSourceType.constant
                  ? 'e.g. 200'
                  : 'e.g. auth_token',
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 10.0,
                ),
                labelText: source.type == ValueSourceType.constant
                    ? 'Constant Value'
                    : 'Key Name',
                labelStyle: const TextStyle(fontSize: 11),
                hintText: source.type == ValueSourceType.constant
                    ? 'e.g. 200'
                    : 'e.g. auth_token',
              ),
              onChanged: (val) {
                onChanged(
                  ValueSource(
                    type: source.type,
                    key: val,
                    jsonPath: source.jsonPath,
                  ),
                );
              },
            ),
          ],
          if (source.type == ValueSourceType.responseBody) ...[
            const SizedBox(height: 6),
            VisualStepTextField(
              value: source.jsonPath,
              labelText: 'JSON Path Selector',
              hintText: 'e.g. data.token',
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 10.0,
                ),
                labelText: 'JSON Path Selector',
                labelStyle: TextStyle(fontSize: 11),
                hintText: 'e.g. data.token',
              ),
              onChanged: (val) {
                onChanged(
                  ValueSource(
                    type: source.type,
                    key: source.key,
                    jsonPath: val,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class ValueSourceInlineEditor extends StatefulWidget {
  final ValueSource source;
  final ValueChanged<ValueSource> onChanged;

  const ValueSourceInlineEditor({
    super.key,
    required this.source,
    required this.onChanged,
  });

  @override
  State<ValueSourceInlineEditor> createState() => _ValueSourceInlineEditorState();
}

class _ValueSourceInlineEditorState extends State<ValueSourceInlineEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.source.type == ValueSourceType.responseBody
          ? widget.source.jsonPath
          : widget.source.key,
    );
  }

  @override
  void didUpdateWidget(covariant ValueSourceInlineEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final expectedVal = widget.source.type == ValueSourceType.responseBody
        ? widget.source.jsonPath
        : widget.source.key;
    if (expectedVal != _controller.text) {
      _controller.text = expectedVal;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getValueSourceTypeName(ValueSourceType type) {
    switch (type) {
      case ValueSourceType.constant:
        return 'Constant';
      case ValueSourceType.responseBody:
        return 'JSON Body';
      case ValueSourceType.responseHeader:
        return 'Header';
      case ValueSourceType.responseStatusCode:
        return 'Status';
      case ValueSourceType.variable:
        return 'Variable';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasInput = widget.source.type != ValueSourceType.responseStatusCode;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonHideUnderline(
          child: DropdownButton<ValueSourceType>(
            value: widget.source.type,
            isDense: true,
            dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
            items: ValueSourceType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  _getValueSourceTypeName(type),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                final nextSource = ValueSource(
                  type: val,
                  key: widget.source.key,
                  jsonPath: widget.source.jsonPath,
                );
                _controller.text = val == ValueSourceType.responseBody
                    ? nextSource.jsonPath
                    : nextSource.key;
                widget.onChanged(nextSource);
              }
            },
          ),
        ),
        if (hasInput) ...[
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 8.0,
                ),
                hintText: widget.source.type == ValueSourceType.constant
                    ? 'value'
                    : widget.source.type == ValueSourceType.responseBody
                        ? 'json.path'
                        : 'key',
              ),
              style: const TextStyle(fontSize: 11),
              onChanged: (val) {
                if (widget.source.type == ValueSourceType.responseBody) {
                  widget.onChanged(
                    ValueSource(
                      type: widget.source.type,
                      key: widget.source.key,
                      jsonPath: val,
                    ),
                  );
                } else {
                  widget.onChanged(
                    ValueSource(
                      type: widget.source.type,
                      key: val,
                      jsonPath: widget.source.jsonPath,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}

