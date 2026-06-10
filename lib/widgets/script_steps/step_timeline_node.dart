import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/theme/app_colors.dart';

class StepTimelineNode extends StatelessWidget {
  final VisualStep step;
  final int index;
  final bool isLast;
  final bool isExpanded;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;
  final Widget content;

  const StepTimelineNode({
    super.key,
    required this.step,
    required this.index,
    required this.isLast,
    required this.isExpanded,
    required this.onTap,
    required this.onToggleEnabled,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
    required this.content,
  });

  String _getStepTitle(VisualStepType type) {
    switch (type) {
      case VisualStepType.setVariable: return 'Set Variable';
      case VisualStepType.assertValue: return 'Assert Value';
      case VisualStepType.sendRequest: return 'Send HTTP Request';
      case VisualStepType.delay: return 'Delay Timer';
    }
  }

  IconData _getStepIcon(VisualStepType type) {
    switch (type) {
      case VisualStepType.setVariable: return Icons.account_tree_outlined;
      case VisualStepType.assertValue: return Icons.fact_check_outlined;
      case VisualStepType.sendRequest: return Icons.http_outlined;
      case VisualStepType.delay: return Icons.hourglass_top_outlined;
    }
  }

  Color _getStepColor(VisualStepType type) {
    switch (type) {
      case VisualStepType.setVariable: return AppColors.primary;
      case VisualStepType.assertValue: return Colors.orange;
      case VisualStepType.sendRequest: return Colors.blue;
      case VisualStepType.delay: return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timelineColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator line
          Container(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.enabled 
                        ? _getStepColor(step.type)
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: timelineColor,
                    ),
                  ),
              ],
            ),
          ),
          // Content block card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 16, bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timeline Node header
                  InkWell(
                    onTap: onTap,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                      child: Row(
                        children: [
                          Icon(
                            _getStepIcon(step.type),
                            size: 18,
                            color: step.enabled ? _getStepColor(step.type) : AppColors.slate500,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _getStepTitle(step.type),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: step.enabled 
                                  ? (isDark ? AppColors.textDark : AppColors.textLight)
                                  : AppColors.slate500,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: step.enabled,
                            onChanged: onToggleEnabled,
                            activeColor: AppColors.primary,
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 16),
                            onPressed: index > 0 ? onMoveUp : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                            onPressed: !isLast ? onMoveDown : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.statusError),
                            onPressed: onDelete,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Render Expanded Form configuration settings
                  if (isExpanded)
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: content,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
