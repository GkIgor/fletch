// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'visual_step_text_field.dart';

class DateTimeStepForm extends StatelessWidget {
  final String nodeId;
  final DateTimeStep node;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const DateTimeStepForm({
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
            DropdownMenuItem(value: 'current', child: Text('Data/Hora Atual')),
            DropdownMenuItem(value: 'add', child: Text('Somar Intervalo')),
            DropdownMenuItem(value: 'subtract', child: Text('Subtrair Intervalo')),
          ],
          onChanged: (val) {
            if (val != null) {
              node.operation = val;
              onUpdated(nodeId, node);
            }
          },
        ),
        if (node.operation == 'add' || node.operation == 'subtract') ...[
          const SizedBox(height: 12),
          VisualStepTextField(
            value: node.value,
            labelText: 'Valor do Deslocamento',
            hintText: 'e.g. 1 day, 12 hours, 30 minutes',
            onChanged: (val) {
              node.value = val;
              onUpdated(nodeId, node);
            },
          ),
        ],
        const SizedBox(height: 12),
        VisualStepTextField(
          value: node.formatPattern,
          labelText: 'Padrão de Formato',
          onChanged: (val) {
            node.formatPattern = val;
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
