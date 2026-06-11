// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';

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
          TextField(
            controller: TextEditingController(text: node.value)
              ..selection = TextSelection.collapsed(offset: node.value.length),
            decoration: const InputDecoration(
              labelText: 'Valor do Deslocamento',
              labelStyle: TextStyle(fontSize: 11),
              hintText: 'e.g. 1 day, 12 hours, 30 minutes',
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: (val) {
              node.value = val;
              onUpdated(nodeId, node);
            },
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: TextEditingController(text: node.formatPattern)
            ..selection = TextSelection.collapsed(offset: node.formatPattern.length),
          decoration: const InputDecoration(labelText: 'Padrão de Formato', labelStyle: TextStyle(fontSize: 11)),
          style: const TextStyle(fontSize: 12),
          onChanged: (val) {
            node.formatPattern = val;
            onUpdated(nodeId, node);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: TextEditingController(text: node.saveToVariable)
            ..selection = TextSelection.collapsed(offset: node.saveToVariable.length),
          decoration: const InputDecoration(labelText: 'Salvar Resultado em', labelStyle: TextStyle(fontSize: 11)),
          style: const TextStyle(fontSize: 12),
          onChanged: (val) {
            node.saveToVariable = val;
            onUpdated(nodeId, node);
          },
        ),
      ],
    );
  }
}
