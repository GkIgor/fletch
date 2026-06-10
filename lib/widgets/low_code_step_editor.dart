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

  void _toggleStepEnabled(int index, bool enabled) {
    final List<VisualStep> currentSteps = List.from(widget.script.steps);
    final step = currentSteps[index];
    step.enabled = enabled;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.script.steps.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schema_outlined,
                    size: 48,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No steps configured in this workflow.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a visual block below to begin.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.borderDark : AppColors.textSecondaryLight.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 80),
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
                  onToggleEnabled: (val) => _toggleStepEnabled(index, val),
                  onMoveUp: () => _moveStepUp(index),
                  onMoveDown: () => _moveStepDown(index),
                  onDelete: () => _removeStep(index),
                  content: _buildStepForm(step, index),
                );
              },
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.sidebarDark : AppColors.slate100,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAddButton('Set Variable', VisualStepType.setVariable, isDark),
              _buildAddButton('Assert Value', VisualStepType.assertValue, isDark),
              _buildAddButton('HTTP Request', VisualStepType.sendRequest, isDark),
              _buildAddButton('Delay', VisualStepType.delay, isDark),
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

  Widget _buildAddButton(String text, VisualStepType type, bool isDark) {
    return ElevatedButton.icon(
      onPressed: () => _addStep(type),
      icon: Icon(_getStepIcon(type), size: 14),
      label: Text(text, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: _getStepColor(type),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
    );
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
}
