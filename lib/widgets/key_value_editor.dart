import 'package:flutter/material.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:fletch/widgets/interpolated_text_controller.dart';

class KeyValueEditor extends StatefulWidget {
  final Map<String, String> initialValues;
  final Function(Map<String, String>) onChanged;
  final String keyHint;
  final String valueHint;

  const KeyValueEditor({
    super.key,
    required this.initialValues,
    required this.onChanged,
    this.keyHint = 'Key',
    this.valueHint = 'Value',
  });

  @override
  State<KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<KeyValueEditor> {
  late List<_RowData> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.initialValues.entries
        .map((e) => _RowData(
              key: e.key,
              value: e.value,
              keyController: InterpolatedTextController(text: e.key),
              valueController: InterpolatedTextController(text: e.value),
              focusNode: FocusNode(),
            ))
        .toList();
    _addNewRow();
  }

  @override
  void dispose() {
    for (var row in _rows) {
      row.keyController.dispose();
      row.valueController.dispose();
      row.focusNode.dispose();
    }
    super.dispose();
  }

  void _notifyChanges() {
    final Map<String, String> result = {};
    for (var row in _rows) {
      if (row.key.trim().isNotEmpty) {
        result[row.key.trim()] = row.value.trim();
      }
    }
    widget.onChanged(result);
  }

  void _addNewRow() {
    final focusNode = FocusNode();
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        _cleanupRows();
      }
    });

    setState(() {
      _rows.add(_RowData(
        keyController: InterpolatedTextController(),
        valueController: InterpolatedTextController(),
        focusNode: focusNode,
      ));
    });
  }

  void _cleanupRows() {
    bool changed = false;
    // We iterate backwards to remove safely, but keep at least one row
    for (int i = _rows.length - 1; i >= 0; i--) {
      final row = _rows[i];
      if (row.key.isEmpty && row.value.isEmpty && _rows.length > 1) {
        // If it's not the last row and it's empty, or if focus is lost and it's empty
        if (!row.focusNode.hasFocus) {
          row.keyController.dispose();
          row.valueController.dispose();
          row.focusNode.dispose();
          _rows.removeAt(i);
          changed = true;
        }
      }
    }
    if (changed) {
      setState(() {});
      _notifyChanges();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Labels
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, left: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    widget.keyHint.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppColors.slate500,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: Text(
                    widget.valueHint.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppColors.slate500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rows
          ...List.generate(_rows.length, (index) {
            final row = _rows[index];
            final isLast = index == _rows.length - 1;

            return Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  _cleanupRows();
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Key Field
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: row.keyController,
                        onChanged: (val) {
                          row.key = val;
                          if (isLast && val.isNotEmpty) {
                            _addNewRow();
                          }
                          _notifyChanges();
                        },
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                        ),
                        decoration: InputDecoration(
                          hintText: 'key',
                          hintStyle: TextStyle(color: AppColors.slate500.withValues(alpha: 0.5), fontSize: 13),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Value Field
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: row.valueController,
                        onChanged: (val) {
                          row.value = val;
                          if (isLast && val.isNotEmpty) {
                            _addNewRow();
                          }
                          _notifyChanges();
                        },
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                        ),
                        decoration: InputDecoration(
                          hintText: 'value',
                          hintStyle: TextStyle(color: AppColors.slate500.withValues(alpha: 0.5), fontSize: 13),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RowData {
  String key;
  String value;
  final InterpolatedTextController keyController;
  final InterpolatedTextController valueController;
  final FocusNode focusNode;

  _RowData({
    this.key = '',
    this.value = '',
    required this.keyController,
    required this.valueController,
    required this.focusNode,
  });
}
