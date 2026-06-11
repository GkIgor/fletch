import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/theme/app_colors.dart';

class ScriptSelectorWidget extends StatelessWidget {
  final List<VisualScript> allScripts;
  final List<String> activeScriptIds;
  final bool inheritScripts;
  final String? inheritedFromName;
  final List<VisualScript> inheritedScripts;
  final ValueChanged<List<String>> onActiveScriptsChanged;
  final ValueChanged<bool> onInheritChanged;
  final VoidCallback onOpenManager;

  const ScriptSelectorWidget({
    super.key,
    required this.allScripts,
    required this.activeScriptIds,
    required this.inheritScripts,
    this.inheritedFromName,
    required this.inheritedScripts,
    required this.onActiveScriptsChanged,
    required this.onInheritChanged,
    required this.onOpenManager,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Inheritance header settings
        if (inheritedFromName != null)
          Container(
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.sidebarDark : AppColors.slate50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: inheritScripts,
                  onChanged: (val) {
                    if (val != null) {
                      onInheritChanged(val);
                    }
                  },
                  activeColor: AppColors.primary,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inherit Scripts from parent',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Inheriting from $inheritedFromName (${inheritedScripts.length} scripts)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Active Scripts list inside current scope
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Selected Scripts to Execute',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: onOpenManager,
              icon: const Icon(Icons.settings_outlined, size: 14),
              label: const Text('Manage Library', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (allScripts.isEmpty && inheritedScripts.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, style: BorderStyle.solid),
            ),
            child: Center(
              child: Text(
                'No scripts found. Click "Manage Library" to create.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView(
              children: [
                // Render inherited readonly scripts first
                if (inheritScripts && inheritedScripts.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: Text(
                      'Inherited from $inheritedFromName (Readonly)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  ...inheritedScripts.map((script) => _buildScriptTile(script, true, isDark, true)),
                  const Divider(height: 24),
                ],

                // Render local selectable scripts
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                  child: Text(
                    'Workspace Scripts Library',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                ...allScripts.map((script) {
                  final isActive = activeScriptIds.contains(script.id);
                  return _buildScriptTile(
                    script,
                    isActive,
                    isDark,
                    false,
                    onChanged: (val) {
                      final updated = List<String>.from(activeScriptIds);
                      if (val == true) {
                        updated.add(script.id);
                      } else {
                        updated.remove(script.id);
                      }
                      onActiveScriptsChanged(updated);
                    },
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildScriptTile(
    VisualScript script,
    bool isActive,
    bool isDark,
    bool isReadonly, {
    ValueChanged<bool?>? onChanged,
  }) {
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: isReadonly ? (isDark ? AppColors.sidebarDark : AppColors.slate50) : cardColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        dense: true,
        leading: Icon(
          script.isPreRequest ? Icons.arrow_circle_up_rounded : Icons.arrow_circle_down_rounded,
          color: script.isPreRequest ? Colors.blue : Colors.orange,
          size: 20,
        ),
        title: Text(
          script.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: isReadonly ? TextDecoration.none : null,
          ),
        ),
        subtitle: Text(
          '${script.isPreRequest ? "Pre-Request" : "Post-Response"} • ${script.nodes.length} nós',
          style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        ),
        trailing: isReadonly
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.slate200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Inherited', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              )
            : Checkbox(
                value: isActive,
                activeColor: AppColors.primary,
                onChanged: onChanged,
              ),
      ),
    );
  }
}
