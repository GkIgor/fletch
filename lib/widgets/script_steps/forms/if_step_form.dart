// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';

class IfStepForm extends StatelessWidget {
  final String nodeId;
  final IfStep node;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const IfStepForm({
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
        ValueSourceForm(
          label: 'Valor Esquerdo',
          source: node.leftSource,
          onChanged: (val) {
            node.leftSource = val;
            onUpdated(nodeId, node);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: node.operator,
          decoration: const InputDecoration(labelText: 'Operador', labelStyle: TextStyle(fontSize: 11)),
          items: const [
            DropdownMenuItem(value: '==', child: Text('Igual (==)')),
            DropdownMenuItem(value: '!=', child: Text('Diferente (!=)')),
            DropdownMenuItem(value: 'contains', child: Text('Contém')),
            DropdownMenuItem(value: '>', child: Text('Maior que (>)')),
            DropdownMenuItem(value: '<', child: Text('Menor que (<)')),
          ],
          onChanged: (val) {
            if (val != null) {
              node.operator = val;
              onUpdated(nodeId, node);
            }
          },
        ),
        const SizedBox(height: 12),
        ValueSourceForm(
          label: 'Valor Direito',
          source: node.rightSource,
          onChanged: (val) {
            node.rightSource = val;
            onUpdated(nodeId, node);
          },
        ),
      ],
    );
  }
}
