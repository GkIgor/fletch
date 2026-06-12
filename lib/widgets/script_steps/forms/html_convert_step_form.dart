// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/widgets/script_steps/value_source_form.dart';
import 'visual_step_text_field.dart';

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
          VisualStepTextField(
            value: node.selector,
            labelText: 'Seletor CSS (e.g. a.link)',
            onChanged: (val) {
              node.selector = val;
              onUpdated(nodeId, node);
            },
          ),
        ],
        if (node.operation == 'extractAttributes') ...[
          const SizedBox(height: 12),
          VisualStepTextField(
            value: node.attribute,
            labelText: 'Atributo a Extrair (e.g. href)',
            onChanged: (val) {
              node.attribute = val;
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
