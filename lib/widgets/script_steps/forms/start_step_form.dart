// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';

class StartStepForm extends StatelessWidget {
  final String nodeId;
  final StartStep node;
  final void Function(String nodeId, VisualStep node) onUpdated;

  const StartStepForm({
    super.key,
    required this.nodeId,
    required this.node,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.play_circle_outline_rounded,
                    color: Colors.green.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ponto de Entrada',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Este nó representa o ponto inicial do script de automação. Ele é obrigatório e sua execução avança imediatamente para o próximo nó conectado.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
