import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/theme/app_colors.dart';
import 'script_steps/step_timeline_node.dart';
import 'script_steps/set_variable_step_form.dart';
import 'script_steps/assert_value_step_form.dart';
import 'script_steps/send_request_step_form.dart';
import 'script_steps/delay_step_form.dart';

class LowCodeStepEditor extends StatefulWidget {
  final VisualScript script;
  final ValueChanged<VisualScript> onChanged;

  const LowCodeStepEditor({
    super.key,
    required this.script,
    required this.onChanged,
  });

  @override
  State<LowCodeStepEditor> createState() => _LowCodeStepEditorState();
}

class _LowCodeStepEditorState extends State<LowCodeStepEditor> {
  final Map<String, bool> _expandedSteps = {};

  void _updateScript(List<VisualStep> updatedSteps) {
    widget.onChanged(
      widget.script.copyWith(
        steps: updatedSteps,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _addStep(VisualStepType type) {
    final List<VisualStep> currentSteps = List.from(widget.script.steps);
    VisualStep newStep;
    
    switch (type) {
      case VisualStepType.setVariable:
        newStep = SetVariableStep(
          variableName: 'new_variable',
          valueSource: ValueSource(type: ValueSourceType.constant, key: 'value'),
        );
        break;
      case VisualStepType.assertValue:
        newStep = AssertValueStep(
          leftSource: ValueSource(type: ValueSourceType.responseStatusCode),
          operator: '==',
          rightSource: ValueSource(type: ValueSourceType.constant, key: '200'),
        );
        break;
      case VisualStepType.sendRequest:
        newStep = SendRequestStep(
          method: 'GET',
          url: 'https://api.example.com',
        );
        break;
      case VisualStepType.delay:
        newStep = DelayStep(durationMs: 1000);
        break;
    }

    currentSteps.add(newStep);
    _expandedSteps[newStep.id] = true;
    _updateScript(currentSteps);
  }

  void _removeStep(int index) {
    final List<VisualStep> currentSteps = List.from(widget.script.steps);
    final removed = currentSteps.removeAt(index);
    _expandedSteps.remove(removed.id);
    _updateScript(currentSteps);
  }



  void _moveStepUp(int index) {
    if (index <= 0) return;
    final List<VisualStep> currentSteps = List.from(widget.script.steps);
    final step = currentSteps.removeAt(index);
    currentSteps.insert(index - 1, step);
    _updateScript(currentSteps);
  }

  void _moveStepDown(int index) {
    if (index >= widget.script.steps.length - 1) return;
    final List<VisualStep> currentSteps = List.from(widget.script.steps);
    final step = currentSteps.removeAt(index);
    currentSteps.insert(index + 1, step);
    _updateScript(currentSteps);
  }

  void _updateStepAt(int index, VisualStep step) {
    final List<VisualStep> currentSteps = List.from(widget.script.steps);
    currentSteps[index] = step;
    _updateScript(currentSteps);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Steps list (Timeline)
        Expanded(
          child: widget.script.steps.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schema_outlined,
                        size: 48,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No steps configured in this workflow.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click a block in the side panel to add steps.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.textSecondaryLight.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  itemCount: widget.script.steps.length,
                  itemBuilder: (context, index) {
                    final step = widget.script.steps[index];
                    final isLast = index == widget.script.steps.length - 1;
                    final isExpanded = _expandedSteps[step.id] ?? false;

                    return StepTimelineNode(
                      step: step,
                      index: index,
                      isLast: isLast,
                      isExpanded: isExpanded,
                      onTap: () {
                        setState(() {
                          _expandedSteps[step.id] = !isExpanded;
                        });
                      },
                      onMoveUp: () => _moveStepUp(index),
                      onMoveDown: () => _moveStepDown(index),
                      onDelete: () => _removeStep(index),
                      content: _buildStepForm(step, index),
                    );
                  },
                ),
        ),

        // Vertical divider
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: borderColor,
        ),

        // Add blocks sidebar palette (Right side)
        Container(
          width: 180,
          color: isDark ? const Color(0xFF0F172A) : AppColors.slate50,
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ADD WORKFLOW STEPS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _buildPaletteButton(
                      'Set Variable',
                      VisualStepType.setVariable,
                      isDark,
                    ),
                    _buildPaletteButton(
                      'Assert Value',
                      VisualStepType.assertValue,
                      isDark,
                    ),
                    _buildPaletteButton(
                      'HTTP Request',
                      VisualStepType.sendRequest,
                      isDark,
                    ),
                    _buildPaletteButton(
                      'Delay',
                      VisualStepType.delay,
                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepForm(VisualStep step, int index) {
    if (step is SetVariableStep) {
      return SetVariableStepForm(
        step: step,
        onChanged: (updatedStep) => _updateStepAt(index, updatedStep),
      );
    } else if (step is AssertValueStep) {
      return AssertValueStepForm(
        step: step,
        onChanged: (updatedStep) => _updateStepAt(index, updatedStep),
      );
    } else if (step is SendRequestStep) {
      return SendRequestStepForm(
        step: step,
        onChanged: (updatedStep) => _updateStepAt(index, updatedStep),
      );
    } else if (step is DelayStep) {
      return DelayStepForm(
        step: step,
        onChanged: (updatedStep) => _updateStepAt(index, updatedStep),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPaletteButton(String text, VisualStepType type, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton.icon(
        onPressed: () => _addStep(type),
        icon: Icon(_getStepIcon(type), size: 14),
        label: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: _getStepColor(type),
          alignment: Alignment.centerLeft,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
        ),
      ),
    );
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
}
