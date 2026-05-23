import 'package:flutter/material.dart';
import 'package:fletch/models/collection_model.dart';
import 'package:fletch/providers/request_provider.dart';
import 'package:fletch/theme/app_colors.dart';

class MoveRequestDialog extends StatelessWidget {
  final List<RequestCollection> collections;
  final String currentCollectionId;

  const MoveRequestDialog({
    super.key,
    required this.collections,
    required this.currentCollectionId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 450),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.drive_file_move_rounded,
                  color: isDark ? Colors.white : Colors.black,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Move Request',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Select destination folder/collection:',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  final collection = collections[index];
                  final isCurrent = collection.id == currentCollectionId;
                  final folderColor = RequestProvider.colors[collection.color] ?? AppColors.primary;
                  final folderIcon = RequestProvider.icons[collection.icon] ?? Icons.folder_rounded;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.primary
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      color: isCurrent
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : null,
                    ),
                    child: ListTile(
                      onTap: isCurrent
                          ? null
                          : () => Navigator.of(context).pop(collection.id),
                      leading: Icon(
                        folderIcon,
                        color: folderColor,
                      ),
                      title: Text(
                        collection.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      trailing: isCurrent
                          ? const Text(
                              'Current',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(Icons.chevron_right_rounded, size: 18),
                    ),
                  );
                },
              ),
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
}
