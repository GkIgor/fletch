import 'package:flutter/material.dart';
import 'package:fletch/theme/app_colors.dart';

enum ExportFormat { native, postman, insomniaJson, insomniaYaml }

class ExportFormatDialog extends StatelessWidget {
  const ExportFormatDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.file_upload_rounded,
                  color: isDark ? Colors.white : Colors.black,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Export Format',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFormatOption(
              context,
              title: 'Native Client Format',
              description: 'Save collections in the native format of this client (.json)',
              icon: Icons.code_rounded,
              format: ExportFormat.native,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildFormatOption(
              context,
              title: 'Postman Collection v2.1',
              description: 'Export all collections grouped into a Postman collection (.json)',
              icon: Icons.api_rounded,
              format: ExportFormat.postman,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildFormatOption(
              context,
              title: 'Insomnia v4 (JSON)',
              description: 'Export all collections and folders in Insomnia v4 format (.json)',
              icon: Icons.storage_rounded,
              format: ExportFormat.insomniaJson,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildFormatOption(
              context,
              title: 'Insomnia v5 (YAML)',
              description: 'Export all collections and folders in Insomnia v5 format (.yaml)',
              icon: Icons.description_rounded,
              format: ExportFormat.insomniaYaml,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required ExportFormat format,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(format),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
