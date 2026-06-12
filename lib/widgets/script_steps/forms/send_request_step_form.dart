// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:fletch/utils/script_compiler.dart';
import 'visual_step_text_field.dart';

/// A lightweight, immutable reference for display inside the form's dropdown.
/// Only carries the data needed to render the picker — no bodies loaded until
/// the user actually selects a request and the compiler resolves the full ref.
class _RequestPickerItem {
  final String id;
  final String label;
  final String method;
  final String url;

  const _RequestPickerItem({
    required this.id,
    required this.label,
    required this.method,
    required this.url,
  });
}

class SendRequestStepForm extends StatefulWidget {
  final String nodeId;
  final SendRequestStep node;
  final void Function(String nodeId, VisualStep node) onUpdated;
  /// Slim request refs — only populated once per dialog open, not per rebuild.
  final List<WorkspaceRequestRef> availableRequests;

  const SendRequestStepForm({
    super.key,
    required this.nodeId,
    required this.node,
    required this.onUpdated,
    this.availableRequests = const [],
  });

  @override
  State<SendRequestStepForm> createState() => _SendRequestStepFormState();
}

class _SendRequestStepFormState extends State<SendRequestStepForm> {
  late bool _useWorkspaceRequest;

  // Lazy-built list: computed once from availableRequests.
  late final List<_RequestPickerItem> _pickerItems;

  @override
  void initState() {
    super.initState();
    _useWorkspaceRequest = widget.node.requestId != null &&
        widget.node.requestId!.isNotEmpty;

    _pickerItems = widget.availableRequests
        .map((r) => _RequestPickerItem(
              id: r.id,
              label: r.name,
              method: r.method,
              url: r.url,
            ))
        .toList();
  }

  void _switchMode(bool useWorkspace) {
    setState(() => _useWorkspaceRequest = useWorkspace);
    if (!useWorkspace) {
      widget.node.requestId = null;
      widget.onUpdated(widget.nodeId, widget.node);
    }
  }

  Color _methodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':    return AppColors.methodGet;
      case 'POST':   return AppColors.methodPost;
      case 'PUT':    return AppColors.methodPut;
      case 'DELETE': return AppColors.methodDelete;
      case 'PATCH':  return AppColors.methodPatch;
      default:       return AppColors.slate400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode toggle — uses theme's colorScheme.primary automatically
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Manual', style: TextStyle(fontSize: 11)),
              icon: Icon(Icons.edit_outlined, size: 14),
            ),
            ButtonSegment(
              value: true,
              label: Text('Workspace Request', style: TextStyle(fontSize: 11)),
              icon: Icon(Icons.folder_open_outlined, size: 14),
            ),
          ],
          selected: {_useWorkspaceRequest},
          onSelectionChanged: (s) => _switchMode(s.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            // Explicitly bind to theme primary so both light and dark work.
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary.withValues(alpha: 0.15);
              }
              return Colors.transparent;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary;
              }
              return secondaryText;
            }),
            side: WidgetStatePropertyAll(
              BorderSide(color: borderColor),
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (_useWorkspaceRequest) ...[
          _buildWorkspacePicker(isDark, secondaryText, borderColor),
        ] else ...[
          _buildManualFields(),
        ],

        const SizedBox(height: 12),
        VisualStepTextField(
          value: widget.node.saveToVariable,
          labelText: 'Save Response to Variable',
          onChanged: (val) {
            widget.node.saveToVariable = val;
            widget.onUpdated(widget.nodeId, widget.node);
          },
        ),
      ],
    );
  }

  Widget _buildWorkspacePicker(
    bool isDark,
    Color secondaryText,
    Color borderColor,
  ) {
    if (_pickerItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.statusWarning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.statusWarning.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: AppColors.statusWarning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No requests found in this workspace.',
                style: TextStyle(fontSize: 11, color: AppColors.statusWarning),
              ),
            ),
          ],
        ),
      );
    }

    final selectedId = widget.node.requestId;
    final selectedItem = selectedId != null
        ? _pickerItems.where((i) => i.id == selectedId).firstOrNull
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Workspace Request',
          style: TextStyle(fontSize: 11, color: secondaryText),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: selectedItem?.id,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          hint: Text(
            'Select a request…',
            style: TextStyle(fontSize: 12, color: secondaryText),
          ),
          items: _pickerItems.map((item) {
            return DropdownMenuItem<String>(
              value: item.id,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _methodColor(item.method).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.method,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _methodColor(item.method),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              widget.node.requestId = val;
              widget.onUpdated(widget.nodeId, widget.node);
              setState(() {});
            }
          },
        ),
        if (selectedItem != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.slate800.withValues(alpha: 0.6)
                  : AppColors.slate100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              selectedItem.url.isNotEmpty ? selectedItem.url : '(no URL)',
              style: TextStyle(
                fontSize: 10,
                color: secondaryText,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scripts attached to this request will NOT be executed to prevent loops.',
            style: TextStyle(
              fontSize: 10,
              color: secondaryText,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildManualFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: widget.node.method,
          decoration: const InputDecoration(
            labelText: 'HTTP Method',
            labelStyle: TextStyle(fontSize: 11),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'GET',    child: Text('GET')),
            DropdownMenuItem(value: 'POST',   child: Text('POST')),
            DropdownMenuItem(value: 'PUT',    child: Text('PUT')),
            DropdownMenuItem(value: 'DELETE', child: Text('DELETE')),
            DropdownMenuItem(value: 'PATCH',  child: Text('PATCH')),
          ],
          onChanged: (val) {
            if (val != null) {
              widget.node.method = val;
              widget.onUpdated(widget.nodeId, widget.node);
            }
          },
        ),
        const SizedBox(height: 12),
        VisualStepTextField(
          value: widget.node.url,
          labelText: 'URL (supports {{var}})',
          onChanged: (val) {
            widget.node.url = val;
            widget.onUpdated(widget.nodeId, widget.node);
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: widget.node.body ?? '',
          decoration: const InputDecoration(
            labelText: 'Body (JSON, text, …)',
            labelStyle: TextStyle(fontSize: 11),
            alignLabelWithHint: true,
            isDense: true,
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          minLines: 3,
          maxLines: 8,
          onChanged: (val) {
            widget.node.body = val.isEmpty ? null : val;
            widget.onUpdated(widget.nodeId, widget.node);
          },
        ),
      ],
    );
  }
}
