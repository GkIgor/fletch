import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/theme/app_colors.dart';

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
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.sidebarDark : AppColors.slate50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              DropdownButton<ValueSourceType>(
                value: source.type,
                dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                items: ValueSourceType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getValueSourceTypeName(type), style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    onChanged(ValueSource(type: val, key: source.key, jsonPath: source.jsonPath));
                  }
                },
              ),
              const SizedBox(width: 12),
              if (source.type == ValueSourceType.constant ||
                  source.type == ValueSourceType.variable ||
                  source.type == ValueSourceType.responseHeader)
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: source.key)..selection = TextSelection.collapsed(offset: source.key.length),
                    decoration: InputDecoration(
                      labelText: source.type == ValueSourceType.constant ? 'Constant Value' : 'Key Name',
                      hintText: source.type == ValueSourceType.constant ? 'e.g. 200' : 'e.g. auth_token',
                    ),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (val) {
                      onChanged(ValueSource(type: source.type, key: val, jsonPath: source.jsonPath));
                    },
                  ),
                ),
            ],
          ),
          if (source.type == ValueSourceType.responseBody) ...[
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: source.jsonPath)..selection = TextSelection.collapsed(offset: source.jsonPath.length),
              decoration: const InputDecoration(
                labelText: 'JSON Path Selector',
                hintText: 'e.g. data.token',
              ),
              style: const TextStyle(fontSize: 12),
              onChanged: (val) {
                onChanged(ValueSource(type: source.type, key: source.key, jsonPath: val));
              },
            ),
          ],
        ],
      ),
    );
  }
}
