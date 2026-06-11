// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';

class HtmlConvertStepForm extends StatelessWidget {
  final String nodeId;
  final HtmlConvertStep node;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const HtmlConvertStepForm({
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
            DropdownMenuItem(value: 'htmlToText', child: Text('Remover tags (Limpar HTML)')),
            DropdownMenuItem(value: 'extractSelector', child: Text('Extrair Elementos (CSS)')),
            DropdownMenuItem(value: 'extractAttributes', child: Text('Extrair Atributo de Elementos')),
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
          label: 'HTML de Origem',
          source: node.valueSource,
          onChanged: (val) {
            node.valueSource = val;
            onUpdated(nodeId, node);
          },
        ),
        if (node.operation == 'extractSelector' || node.operation == 'extractAttributes') ...[
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: node.selector)
              ..selection = TextSelection.collapsed(offset: node.selector.length),
            decoration: const InputDecoration(labelText: 'Seletor CSS (e.g. a.link)', labelStyle: TextStyle(fontSize: 11)),
            style: const TextStyle(fontSize: 12),
            onChanged: (val) {
              node.selector = val;
              onUpdated(nodeId, node);
            },
          ),
        ],
        if (node.operation == 'extractAttributes') ...[
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: node.attribute)
              ..selection = TextSelection.collapsed(offset: node.attribute.length),
            decoration: const InputDecoration(labelText: 'Atributo a Extrair (e.g. href)', labelStyle: TextStyle(fontSize: 11)),
            style: const TextStyle(fontSize: 12),
            onChanged: (val) {
              node.attribute = val;
              onUpdated(nodeId, node);
            },
          ),
        ],
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
