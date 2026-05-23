import 'package:flutter/material.dart';
import 'package:fletch/models/workspace_models.dart';
import 'package:fletch/providers/workspace_provider.dart';

class CreateWorkspaceDialog extends StatefulWidget {
  final WorkspaceProvider workspaceProvider;

  const CreateWorkspaceDialog({super.key, required this.workspaceProvider});

  @override
  State<CreateWorkspaceDialog> createState() => _CreateWorkspaceDialogState();
}

class _CreateWorkspaceDialogState extends State<CreateWorkspaceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedIcon = 'bolt';

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF111827) : Colors.white;
    final inputBgColor = isDark ? const Color(0x801E293B) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08);
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
        side: BorderSide(color: borderColor),
      ),
      elevation: 24,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create New Workspace',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: labelColor,
                      size: 20,
                    ),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Workspace Name
              Text(
                'Workspace Name',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: TextStyle(fontSize: 14, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Enter workspace name...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: labelColor.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: inputBgColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6366F1),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Workspace name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: TextStyle(fontSize: 14, color: textColor),
                decoration: InputDecoration(
                  hintText: 'What is this workspace for?',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: labelColor.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: inputBgColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6366F1),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Icon Selector
              Text(
                'Choose Icon',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final key in const [
                    'bolt', 'api', 'shield', 'package', 'bar_chart',
                    'search_activity', 'code', 'cloud', 'database', 'hub',
                    'terminal', 'dns', 'deployed_code', 'security', 'lock'
                  ])
                    _buildIconOption(
                      key,
                      WorkspaceProvider.icons[key]!,
                      WorkspaceProvider.iconColors[key]!,
                      borderColor,
                    ),
                ],
              ),
              const SizedBox(height: 32),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final ws = WorkspaceModel(
                          name: _nameController.text.trim(),
                          description: _descController.text.trim(),
                          icon: _selectedIcon,
                        );
                        await widget.workspaceProvider.addWorkspace(ws);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ).copyWith(
                      elevation: WidgetStateProperty.resolveWith<double>(
                        (states) => states.contains(WidgetState.hovered) ? 6 : 0,
                      ),
                    ),
                    child: const Text(
                      'Create Workspace',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconOption(
    String key,
    IconData icon,
    Color color,
    Color borderColor,
  ) {
    final isSelected = _selectedIcon == key;
 
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIcon = key;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 18,
        ),
      ),
    );
  }
}
