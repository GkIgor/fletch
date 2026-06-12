// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';
import 'visual_step_text_field.dart';

class CryptoStepForm extends StatelessWidget {
  final String nodeId;
  final CryptoStep node;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const CryptoStepForm({
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
          decoration: const InputDecoration(labelText: 'Algoritmo', labelStyle: TextStyle(fontSize: 11)),
          items: const [
            DropdownMenuItem(value: 'hashMD5', child: Text('MD5')),
            DropdownMenuItem(value: 'hashSHA256', child: Text('SHA-256')),
            DropdownMenuItem(value: 'hmacSHA256', child: Text('HMAC (SHA-256)')),
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
        if (node.operation == 'hmacSHA256') ...[
          const SizedBox(height: 12),
          ValueSourceForm(
            label: 'Chave Secreta (Key)',
            source: node.keySource ?? ValueSource(),
            onChanged: (val) {
              node.keySource = val;
              onUpdated(nodeId, node);
            },
          ),
        ],
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
