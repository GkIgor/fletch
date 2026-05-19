import 'package:flutter/material.dart';
import 'package:gk_http_client/models/http_request.dart';
import 'package:gk_http_client/theme/app_colors.dart';
import 'package:gk_http_client/theme/app_theme.dart';
import 'package:dotted_border/dotted_border.dart' as db;
import 'package:file_picker/file_picker.dart' as picker;
import 'package:path/path.dart' as p;

enum BodyType { none, json, formData, xml, binary }

class BodyEditor extends StatefulWidget {
  final HttpRequest request;
  final Function(HttpRequest) onChanged;

  const BodyEditor({
    super.key,
    required this.request,
    required this.onChanged,
  });

  @override
  State<BodyEditor> createState() => _BodyEditorState();
}

class _BodyEditorState extends State<BodyEditor> {
  late TextEditingController _textController;
  late ScrollController _textScrollController;
  late ScrollController _lineNumbersScrollController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.request.body);
    _textScrollController = ScrollController();
    _lineNumbersScrollController = ScrollController();

    // Sync line numbers scroll with text scroll
    _textScrollController.addListener(() {
      if (_lineNumbersScrollController.hasClients) {
        _lineNumbersScrollController.jumpTo(_textScrollController.offset);
      }
    });
  }

  @override
  void didUpdateWidget(BodyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.id != widget.request.id ||
        (oldWidget.request.body != widget.request.body && _textController.text != widget.request.body)) {
      _textController.text = widget.request.body ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _textScrollController.dispose();
    _lineNumbersScrollController.dispose();
    super.dispose();
  }

  void _updateRequest({
    String? body,
    BodyType? type,
    List<FormDataEntry>? formData,
    String? binaryPath,
  }) {
    final updated = widget.request.copyWith(
      body: body,
      bodyType: type,
      formData: formData,
      binaryPath: binaryPath,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selector Row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              _buildTypeOption('None', BodyType.none),
              _buildTypeOption('JSON', BodyType.json),
              _buildTypeOption('Form Data', BodyType.formData),
              _buildTypeOption('XML', BodyType.xml),
              _buildTypeOption('Binary', BodyType.binary),
            ],
          ),
        ),

        // Editor Area
        Expanded(
          child: _buildSelectedEditor(isDark),
        ),
      ],
    );
  }

  Widget _buildTypeOption(String label, BodyType type) {
    final isSelected = widget.request.bodyType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: InkWell(
        onTap: () => _updateRequest(type: type),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.slate500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedEditor(bool isDark) {
    switch (widget.request.bodyType) {
      case BodyType.none:
        return _buildNonePlaceholder();
      case BodyType.json:
      case BodyType.xml:
        return _buildTextEditor(isDark, widget.request.bodyType == BodyType.json ? 'JSON' : 'XML');
      case BodyType.formData:
        return _FormDataEditor(
          entries: widget.request.formData,
          onChanged: (data) => _updateRequest(formData: data),
        );
      case BodyType.binary:
        return _BinaryEditor(
          path: widget.request.binaryPath,
          onChanged: (path) => _updateRequest(binaryPath: path),
        );
    }
  }

  Widget _buildNonePlaceholder() {
    return Center(
      child: Text(
        'This request does not have a body',
        style: TextStyle(color: AppColors.slate500, fontSize: 13),
      ),
    );
  }

  Widget _buildTextEditor(bool isDark, String mode) {
    final lineCount = _textController.text.split('\n').length;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Line Numbers (Left Side) - Standard IDE behavior
            Container(
              width: 40,
              padding: const EdgeInsets.only(top: 16),
              // color: AppColors.slate800,
              color: AppColors.slate800.withValues(alpha: 0.5),
              child: ListView.builder(
                controller: _lineNumbersScrollController,
                itemCount: lineCount,
                physics: const NeverScrollableScrollPhysics(), // Managed by listener
                itemBuilder: (context, index) => Container(
                  height: 19.3, // Match TextField line height approximately
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: AppColors.slate400,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),

            // Straight Border Separator
            Container(
              width: 1,
              color: borderColor,
            ),

            // Text Input Area
            Expanded(
              child: TextField(
                controller: _textController,
                scrollController: _textScrollController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: AppTheme.codeStyle(
                  fontSize: 13,
                  color: Colors.white, // Contrast for code
                ),
                decoration: InputDecoration(
                  hintText: 'Enter $mode body...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                onChanged: (val) {
                  _updateRequest(body: val);
                  setState(() {}); // Update line numbers count
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormDataEditor extends StatefulWidget {
  final List<FormDataEntry> entries;
  final Function(List<FormDataEntry>) onChanged;

  const _FormDataEditor({required this.entries, required this.onChanged});

  @override
  State<_FormDataEditor> createState() => _FormDataEditorState();
}

class _FormDataEditorState extends State<_FormDataEditor> {
  late List<FormDataEntry> _rows;

  @override
  void initState() {
    super.initState();
    _rows = List.from(widget.entries);
    if (_rows.isEmpty) {
      _rows.add(FormDataEntry());
    }
  }

  void _notify() => widget.onChanged(_rows.where((e) => e.key.isNotEmpty || e.value.isNotEmpty).toList());

  void _addRow() {
    setState(() {
      _rows.add(FormDataEntry());
    });
  }

  void _removeRow(int index) {
    setState(() {
      _rows.removeAt(index);
      if (_rows.isEmpty) _rows.add(FormDataEntry());
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              const SizedBox(width: 40), // For checkbox
              Expanded(
                flex: 3,
                child: Text('KEY', style: _headerStyle()),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text('VALUE', style: _headerStyle()),
              ),
              const SizedBox(width: 12),
              const SizedBox(width: 120, child: Text('TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate500))),
              const SizedBox(width: 32), // For trash
            ],
          ),
        ),

        // Scrollable Rows
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _rows.length,
            itemBuilder: (context, index) {
              return _FormDataRow(
                key: ValueKey(_rows[index].id),
                entry: _rows[index],
                onChanged: () => _notify(),
                onDelete: () => _removeRow(index),
                borderColor: borderColor,
                isDark: isDark,
              );
            },
          ),
        ),

        // Add Row Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: InkWell(
            onTap: _addRow,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add, size: 16, color: AppColors.slate400),
                  SizedBox(width: 8),
                  Text(
                    'Add Row',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _headerStyle() => const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: AppColors.slate500,
      );
}

class _FormDataRow extends StatefulWidget {
  final FormDataEntry entry;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final Color borderColor;
  final bool isDark;

  const _FormDataRow({
    super.key,
    required this.entry,
    required this.onChanged,
    required this.onDelete,
    required this.borderColor,
    required this.isDark,
  });

  @override
  State<_FormDataRow> createState() => _FormDataRowState();
}

class _FormDataRowState extends State<_FormDataRow> {
  bool _isHovering = false;
  bool _isTrashHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: widget.borderColor)),
        ),
        child: Row(
          children: [
            // Round Checkbox
            SizedBox(
              width: 40,
              child: Checkbox(
                value: widget.entry.enabled,
                onChanged: (val) {
                  widget.entry.enabled = val ?? true;
                  widget.onChanged();
                  setState(() {});
                },
                shape: const CircleBorder(),
                visualDensity: VisualDensity.compact,
              ),
            ),

            // Key Field
            Expanded(
              flex: 3,
              child: TextField(
                controller: TextEditingController(text: widget.entry.key)..selection = TextSelection.fromPosition(TextPosition(offset: widget.entry.key.length)),
                onChanged: (val) {
                  widget.entry.key = val;
                  widget.onChanged();
                },
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Key',
                  hintStyle: TextStyle(color: AppColors.slate500.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Value Field
            Expanded(
              flex: 2,
              child: widget.entry.isFile
                  ? _FileSelector(
                      path: widget.entry.value,
                      onChanged: (path) {
                        widget.entry.value = path;
                        widget.onChanged();
                        setState(() {});
                      },
                      isDark: widget.isDark,
                    )
                  : TextField(
                      controller: TextEditingController(text: widget.entry.value)..selection = TextSelection.fromPosition(TextPosition(offset: widget.entry.value.length)),
                      onChanged: (val) {
                        widget.entry.value = val;
                        widget.onChanged();
                      },
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Value',
                        hintStyle: TextStyle(color: AppColors.slate500.withValues(alpha: 0.5)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            // Type Selector
            SizedBox(
              width: 120,
              child: DropdownButton<bool>(
                value: widget.entry.isFile,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, size: 16),
                style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.white : Colors.black),
                items: const [
                  DropdownMenuItem(value: false, child: Text('Text')),
                  DropdownMenuItem(value: true, child: Text('File')),
                ],
                onChanged: (val) {
                  widget.entry.isFile = val ?? false;
                  widget.entry.value = '';
                  widget.onChanged();
                  setState(() {});
                },
              ),
            ),

            // Trash Icon (Only on hover)
            SizedBox(
              width: 32,
              child: _isHovering
                  ? MouseRegion(
                      onEnter: (_) => setState(() => _isTrashHovering = true),
                      onExit: (_) => setState(() => _isTrashHovering = false),
                      child: IconButton(
                        onPressed: widget.onDelete,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: _isTrashHovering ? Colors.red : AppColors.slate500,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileSelector extends StatelessWidget {
  final String path;
  final Function(String) onChanged;
  final bool isDark;

  const _FileSelector({required this.path, required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        try {
          final result = await picker.FilePicker.platform.pickFiles();
          if (result != null && result.files.single.path != null) {
            onChanged(result.files.single.path!);
          }
        } catch (e) {
          debugPrint('File picker error: $e');
        }
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.slate200),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const Icon(Icons.attach_file_rounded, size: 14, color: AppColors.slate500),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                path.isEmpty ? 'Select file...' : p.basename(path),
                style: TextStyle(
                  fontSize: 12,
                  color: path.isEmpty ? AppColors.slate500.withValues(alpha: 0.5) : (isDark ? Colors.white : Colors.black),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BinaryEditor extends StatelessWidget {
  final String? path;
  final Function(String?) onChanged;
  const _BinaryEditor({this.path, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: db.DottedBorder(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        strokeWidth: 1.5,
        dashPattern: const [6, 4],
        borderType: db.BorderType.RRect,
        radius: const Radius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text('Select a file to upload', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textDark : AppColors.textLight)),
              const SizedBox(height: 8),
              Text('Drag and drop your file here or click the button below', style: TextStyle(fontSize: 13, color: AppColors.slate500), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (path != null && path!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.insert_drive_file, size: 18, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(p.basename(path!), style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      IconButton(onPressed: () => onChanged(null), icon: const Icon(Icons.close, size: 16), visualDensity: VisualDensity.compact),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: () async {
                  try {
                    final result = await picker.FilePicker.platform.pickFiles();
                    if (result != null) onChanged(result.files.single.path);
                  } catch (e) {
                    debugPrint('File picker error: $e');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
                child: const Text('Choose File'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
