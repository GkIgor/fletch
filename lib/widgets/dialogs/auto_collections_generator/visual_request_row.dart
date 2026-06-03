import 'package:flutter/material.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/theme/app_colors.dart';
import 'generator_models.dart';
import 'generator_utils.dart';

class VisualRequestRow extends StatelessWidget {
  final RequestConfig request;
  final bool isDark;
  final VoidCallback onDelete;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  const VisualRequestRow({
    super.key,
    required this.request,
    required this.isDark,
    required this.onDelete,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // Method badge in a fixed width container to ensure all inputs align perfectly
          SizedBox(
            width: 48,
            child: Align(
              alignment: Alignment.center,
              child: _buildMethodBadge(request.method),
            ),
          ),
          const SizedBox(width: 6),
          // Path / Name input field with compact styling (border bottom only, no background)
          SizedBox(
            width: 350,
            child: TextFormField(
              initialValue: request.name,
              focusNode: request.focusNode,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
              decoration: InputDecoration(
                filled: false,
                isDense: true,
                hintText: 'e.g. /users/profile or Get User Profile',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: AppColors.slate500.withValues(alpha: 0.5),
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1.0,
                  ),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1.0,
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              ),
              onChanged: onChanged,
              onFieldSubmitted: (_) => onSubmitted(),
            ),
          ),
          const Spacer(),
          // Delete button
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Remove Request',
          ),
        ],
      ),
    );
  }

  Widget _buildMethodBadge(HttpMethod method) {
    final color = getMethodColor(method.value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Text(
        method.value,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
