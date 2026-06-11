// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';

class MergeStepForm extends StatelessWidget {
  final String nodeId;
  final MergeStep node;
  final Color borderColor;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const MergeStepForm({
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
          value: node.strategy,
          decoration: const InputDecoration(labelText: 'Estratégia de Merge', labelStyle: TextStyle(fontSize: 11)),
          items: const [
            DropdownMenuItem(value: 'deepMerge', child: Text('Deep Merge (Mapas)')),
            DropdownMenuItem(value: 'concatLists', child: Text('Concatenar Listas')),
            DropdownMenuItem(value: 'zip', child: Text('Parear Listas (Zip)')),
          ],
          onChanged: (val) {
            if (val != null) {
              node.strategy = val;
              onUpdated(nodeId, node);
            }
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Fontes a Unir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.green),
              onPressed: () {
                node.sources.add('globals.var_name');
                onUpdated(nodeId, node);
              },
            ),
          ],
        ),
        ...node.sources.asMap().entries.map((e) {
          final idx = e.key;
          final src = e.value;
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: src)
                    ..selection = TextSelection.collapsed(offset: src.length),
                  decoration: InputDecoration(labelText: 'Variável ${idx + 1}', labelStyle: const TextStyle(fontSize: 10)),
                  style: const TextStyle(fontSize: 11),
                  onChanged: (val) {
                    node.sources[idx] = val;
                    onUpdated(nodeId, node);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                onPressed: () {
                  node.sources.removeAt(idx);
                  onUpdated(nodeId, node);
                },
              )
            ],
          );
        }),
        const SizedBox(height: 12),
        TextField(
          controller: TextEditingController(text: node.saveTo)
            ..selection = TextSelection.collapsed(offset: node.saveTo.length),
          decoration: const InputDecoration(labelText: 'Salvar Resultado em', labelStyle: TextStyle(fontSize: 11)),
          style: const TextStyle(fontSize: 12),
          onChanged: (val) {
            node.saveTo = val;
            onUpdated(nodeId, node);
          },
        ),
      ],
    );
  }
}
