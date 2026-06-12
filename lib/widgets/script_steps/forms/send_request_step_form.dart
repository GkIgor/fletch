// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'visual_step_text_field.dart';

class SendRequestStepForm extends StatelessWidget {
  final String nodeId;
  final SendRequestStep node;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const SendRequestStepForm({
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
          value: node.method,
          decoration: const InputDecoration(labelText: 'Método HTTP', labelStyle: TextStyle(fontSize: 11)),
          items: const [
            DropdownMenuItem(value: 'GET', child: Text('GET')),
            DropdownMenuItem(value: 'POST', child: Text('POST')),
            DropdownMenuItem(value: 'PUT', child: Text('PUT')),
            DropdownMenuItem(value: 'DELETE', child: Text('DELETE')),
          ],
          onChanged: (val) {
            if (val != null) {
              node.method = val;
              onUpdated(nodeId, node);
            }
          },
        ),
        const SizedBox(height: 12),
        VisualStepTextField(
          value: node.url,
          labelText: 'URL (Aceita {{var}})',
          onChanged: (val) {
            node.url = val;
            onUpdated(nodeId, node);
          },
        ),
        const SizedBox(height: 12),
        VisualStepTextField(
          value: node.saveToVariable,
          labelText: 'Salvar Resposta na Variável',
          onChanged: (val) {
            node.saveToVariable = val;
            onUpdated(nodeId, node);
          },
        ),
      ],
    );
  }
}
