// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';
import 'visual_step_text_field.dart';

class JsonConvertStepForm extends StatelessWidget {
  final String nodeId;
  final JsonConvertStep node;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const JsonConvertStepForm({
    super.key,
    required this.nodeId,
    required this.node,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: node.operation,
          decoration: const InputDecoration(labelText: 'Operação', labelStyle: TextStyle(fontSize: 11)),
          items: const [
            DropdownMenuItem(value: 'deserialize', child: Text('String para JSON (Parse)')),
            DropdownMenuItem(value: 'serialize', child: Text('JSON para String (Stringify)')),
          ],
          onChanged: (val) {
            if (val != null) {
              node.operation = val;
              onUpdated(nodeId, node);
            }
          },
        ),
        const SizedBox(height: 12),
        ValueSourceForm(
          label: 'Valor de Origem',
          source: node.valueSource,
          onChanged: (val) {
            node.valueSource = val;
            onUpdated(nodeId, node);
          },
        ),
        const SizedBox(height: 12),
        VisualStepTextField(
          value: node.saveToVariable,
          labelText: 'Salvar Resultado em',
          onChanged: (val) {
            node.saveToVariable = val;
            onUpdated(nodeId, node);
          },
        ),
      ],
    );
  }
}
