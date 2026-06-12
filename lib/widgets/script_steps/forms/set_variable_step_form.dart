import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';
import 'visual_step_text_field.dart';

class SetVariableStepForm extends StatelessWidget {
  final String nodeId;
  final SetVariableStep node;
  final Color borderColor;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const SetVariableStepForm({
    super.key,
    required this.nodeId,
    required this.node,
    required this.borderColor,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Atribuições', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.green),
              onPressed: () {
                node.assignments.add(VariableAssignment(
                  variableName: 'var_${node.assignments.length + 1}',
                  valueSource: ValueSource(),
                ));
                onUpdated(nodeId, node);
              },
            ),
          ],
        ),
        ...node.assignments.asMap().entries.map((e) {
          final idx = e.key;
          final item = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: VisualStepTextField(
                        value: item.variableName,
                        labelText: 'Variável',
                        decoration: const InputDecoration(
                          labelText: 'Variável',
                          labelStyle: TextStyle(fontSize: 10),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          item.variableName = val;
                          onUpdated(nodeId, node);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      onPressed: () {
                        node.assignments.removeAt(idx);
                        onUpdated(nodeId, node);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ValueSourceInlineEditor(
                  source: item.valueSource,
                  onChanged: (updatedSrc) {
                    item.valueSource = updatedSrc;
                    onUpdated(nodeId, node);
                  },
                )
              ],
            ),
          );
        }),
      ],
    );
  }
}
