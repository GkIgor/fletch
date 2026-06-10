import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/theme/app_colors.dart';

class StepTimelineNode extends StatelessWidget {
  final VisualStep step;
  final int index;
  final bool isLast;
  final bool isExpanded;
  final VoidCallback onTap;
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
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
    required this.content,
  });

  String _getStepTitle(VisualStepType type) {
    switch (type) {
      case VisualStepType.setVariable:
        return 'Set Variable';
      case VisualStepType.assertValue:
        return 'Assert Value';
      case VisualStepType.sendRequest:
        return 'Send HTTP Request';
      case VisualStepType.delay:
        return 'Delay Timer';
    }
  }

  IconData _getStepIcon(VisualStepType type) {
    switch (type) {
      case VisualStepType.setVariable:
        return Icons.account_tree_outlined;
      case VisualStepType.assertValue:
        return Icons.fact_check_outlined;
      case VisualStepType.sendRequest:
        return Icons.http_outlined;
      case VisualStepType.delay:
        return Icons.hourglass_top_outlined;
    }
  }

  Color _getStepColor(VisualStepType type) {
    switch (type) {
      case VisualStepType.setVariable:
        return AppColors.primary;
      case VisualStepType.assertValue:
        return Colors.orange;
      case VisualStepType.sendRequest:
        return Colors.blue;
      case VisualStepType.delay:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timelineColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Stack(
      children: [
        // Timeline vertical connector line
        if (!isLast)
          Positioned(
            left: 17, // Center of the 36px wide timeline area (18px - 1px half-width = 17px)
            top: 11,
            bottom: 0,
            child: Container(
              width: 2,
              color: timelineColor,
            ),
          ),
        // Timeline indicator dot
        Positioned(
          left: 13, // Center of the 36px area (18px - 5px radius = 13px)
          top: 11,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStepColor(step.type),
            ),
          ),
        ),
        // Content block card
        Padding(
          padding: const EdgeInsets.only(left: 36.0), // Indent to clear the timeline area
          child: Container(
            margin: const EdgeInsets.only(right: 16, bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline Node header
                InkWell(
                  onTap: onTap,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStepIcon(step.type),
                          size: 16,
                          color: _getStepColor(step.type),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _getStepTitle(step.type),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        // Expansion chevron
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppColors.slate500,
                        ),
                        const SizedBox(width: 12),
                        // Compact Action controls
                        IconButton(
                          icon: const Icon(Icons.arrow_upward_rounded, size: 14),
                          onPressed: index > 0 ? onMoveUp : null,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: 'Move Up',
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_downward_rounded, size: 14),
                          onPressed: !isLast ? onMoveDown : null,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: 'Move Down',
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 14,
                            color: AppColors.statusError,
                          ),
                          onPressed: onDelete,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: 'Delete',
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
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(12.0),
                    child: content,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
