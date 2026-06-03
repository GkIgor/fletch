import 'package:flutter/material.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/providers/request_provider.dart';
import 'package:fletch/theme/app_colors.dart';
import 'generator_models.dart';
import 'generator_utils.dart';
import 'visual_request_row.dart';

class VisualCollectionCard extends StatelessWidget {
  final CollectionConfig collection;
  final int index;
  final bool isDark;
  final int depth;
  final VoidCallback onToggleExpand;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onRemove;
  final Function(HttpMethod) onAddRequest;
  final Function(int) onRemoveRequest;
  final Function(int, String) onRequestNameChanged;
  final Function(int, HttpMethod) onAddRequestAfter;
  final ValueChanged<String> onIconSelected;
  final ValueChanged<String> onColorSelected;

  const VisualCollectionCard({
    super.key,
    required this.collection,
    required this.index,
    required this.isDark,
    required this.depth,
    required this.onToggleExpand,
    required this.onNameChanged,
    required this.onRemove,
    required this.onAddRequest,
    required this.onRemoveRequest,
    required this.onRequestNameChanged,
    required this.onAddRequestAfter,
    required this.onIconSelected,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = hexToColor(collection.color);
    final icons = RequestProvider.icons;
    final activeIcon = icons[collection.icon] ?? Icons.folder_rounded;

    return Container(
      margin: EdgeInsets.only(bottom: 16, left: depth * 16.0),
      decoration: BoxDecoration(
        // Color matches the LIVE TREE PREVIEW background color
        color: isDark ? const Color(0xFF0F172A) : AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          // Collection Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Row(
              children: [
                // Expand / Collapse Arrow
                IconButton(
                  icon: Icon(
                    collection.isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                    size: 20,
                    color: isDark ? AppColors.textDark.withValues(alpha: 0.7) : AppColors.textLight.withValues(alpha: 0.7),
                  ),
                  onPressed: onToggleExpand,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 2),
                // Visual component to render chosen collection icon
                Icon(
                  activeIcon,
                  size: 16,
                  color: activeColor,
                ),
                const SizedBox(width: 8),
                // Collection name input field
                Expanded(
                  child: TextFormField(
                    initialValue: collection.name,
                    focusNode: collection.nameFocusNode,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      hintText: 'Collection Name',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: AppColors.slate500.withValues(alpha: 0.5),
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1.2,
                        ),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary, width: 1.8),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    ),
                    onChanged: onNameChanged,
                  ),
                ),
                const SizedBox(width: 12),
                // Quick Add Request Buttons Row (moved from the bottom)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuickMethodButton(HttpMethod.get),
                    const SizedBox(width: 4),
                    _buildQuickMethodButton(HttpMethod.post),
                    const SizedBox(width: 4),
                    _buildQuickMethodButton(HttpMethod.put),
                    const SizedBox(width: 4),
                    _buildQuickMethodButton(HttpMethod.delete),
                    const SizedBox(width: 4),
                    _buildQuickMethodButton(HttpMethod.patch),
                  ],
                ),
                const SizedBox(width: 12),
                // Icon selector dropdown/popup
                _buildCollectionIconSelector(activeIcon, activeColor),
                const SizedBox(width: 12),
                // Color selector dropdown/popup
                _buildCollectionColorSelector(activeColor),
                const SizedBox(width: 12),
                // Delete collection button
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete Collection',
                ),
              ],
            ),
          ),

          if (collection.isExpanded) ...[
            Divider(
              height: 1,
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            ),
            // Requests List
            if (collection.requests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 18.0, right: 12.0, top: 8.0, bottom: 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: activeColor.withValues(alpha: 0.5),
                        width: 2.0,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Column(
                    children: List.generate(collection.requests.length, (reqIdx) {
                      final req = collection.requests[reqIdx];
                      return VisualRequestRow(
                        request: req,
                        isDark: isDark,
                        onDelete: () => onRemoveRequest(reqIdx),
                        onChanged: (val) => onRequestNameChanged(reqIdx, val),
                        onSubmitted: () => onAddRequestAfter(reqIdx, req.method),
                      );
                    }),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickMethodButton(HttpMethod method) {
    final color = getMethodColor(method.value);
    return InkWell(
      onTap: () => onAddRequest(method),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 8, color: color),
            const SizedBox(width: 1),
            Text(
              method.value,
              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionIconSelector(IconData activeIcon, Color activeColor) {
    final icons = RequestProvider.icons;
    return PopupMenuButton<String>(
      tooltip: 'Folder Icon',
      onSelected: onIconSelected,
      itemBuilder: (context) {
        return icons.entries.map((entry) {
          return PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                Icon(entry.value, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  entry.key,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Icon(
        activeIcon,
        size: 18,
        color: activeColor.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildCollectionColorSelector(Color activeColor) {
    final colors = RequestProvider.colors;
    return PopupMenuButton<String>(
      tooltip: 'Folder Color',
      onSelected: onColorSelected,
      itemBuilder: (context) {
        return colors.entries.map((entry) {
          return PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: entry.value,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getColorName(entry.key),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: activeColor,
          shape: BoxShape.circle,
          border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
        ),
      ),
    );
  }

  String _getColorName(String hex) {
    switch (hex) {
      case '#8b5cf6':
        return 'Purple';
      case '#10b981':
        return 'Green';
      case '#f59e0b':
        return 'Orange';
      case '#f43f5e':
        return 'Red';
      default:
        return 'Color';
    }
  }
}
