// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';
import 'visual_step_text_field.dart';

class HeaderBuilderStepForm extends StatelessWidget {
  final String nodeId;
  final HeaderBuilderStep node;
  final Color borderColor;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const HeaderBuilderStepForm({
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
        DropdownButtonFormField<String>(
          value: node.authType,
          decoration: const InputDecoration(labelText: 'Autorização', labelStyle: TextStyle(fontSize: 11)),
          items: const [
            DropdownMenuItem(value: 'none', child: Text('Nenhuma')),
            DropdownMenuItem(value: 'bearer', child: Text('Bearer Token')),
            DropdownMenuItem(value: 'basic', child: Text('Basic Auth (credentials)')),
            DropdownMenuItem(value: 'apiKey', child: Text('API Key (X-API-Key)')),
          ],
          onChanged: (val) {
            if (val != null) {
              node.authType = val;
              onUpdated(nodeId, node);
            }
          },
        ),
        if (node.authType != 'none') ...[
          const SizedBox(height: 12),
          ValueSourceForm(
            label: node.authType == 'bearer'
                ? 'Token'
                : node.authType == 'basic'
                    ? 'usuário:senha'
                    : 'Chave (API Key)',
            source: node.tokenSource,
            onChanged: (val) {
              node.tokenSource = val;
              onUpdated(nodeId, node);
            },
          ),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Cabeçalhos Adicionais', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.green),
              onPressed: () {
                node.additionalHeaders['Header-${node.additionalHeaders.length + 1}'] = '';
                onUpdated(nodeId, node);
              },
            ),
          ],
        ),
        ...node.additionalHeaders.entries.map((entry) {
          final k = entry.key;
          final v = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: VisualStepTextField(
                    value: k,
                    labelText: '',
                    hintText: 'Chave',
                    decoration: const InputDecoration(hintText: 'Chave', isDense: true, hintStyle: TextStyle(fontSize: 10)),
                    style: const TextStyle(fontSize: 11),
                    onChanged: (newKey) {
                      if (newKey.trim().isNotEmpty && newKey != k) {
                        node.additionalHeaders.remove(k);
                        node.additionalHeaders[newKey] = v;
                        onUpdated(nodeId, node);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: VisualStepTextField(
                    value: v,
                    labelText: '',
                    hintText: 'Valor',
                    decoration: const InputDecoration(hintText: 'Valor', isDense: true, hintStyle: TextStyle(fontSize: 10)),
                    style: const TextStyle(fontSize: 11),
                    onChanged: (newVal) {
                      node.additionalHeaders[k] = newVal;
                      onUpdated(nodeId, node);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                  onPressed: () {
                    node.additionalHeaders.remove(k);
                    onUpdated(nodeId, node);
                  },
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        VisualStepTextField(
          value: node.saveToVariable,
          labelText: 'Salvar Headers em',
          onChanged: (val) {
            node.saveToVariable = val;
            onUpdated(nodeId, node);
          },
        ),
      ],
    );
  }
}
