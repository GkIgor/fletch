import 'package:flutter/material.dart';
import 'package:gk_http_client/models/http_request.dart';
import 'package:gk_http_client/providers/request_provider.dart';
import 'package:gk_http_client/theme/app_colors.dart';
import 'package:gk_http_client/widgets/dialogs/move_request_dialog.dart';
import 'package:gk_http_client/widgets/dialogs/rename_request_dialog.dart';
import 'package:gk_http_client/widgets/method_badge.dart';
import 'package:provider/provider.dart';

class RequestListItem extends StatefulWidget {
  final HttpRequest request;
  final String collectionId;
  final bool isSelected;
  final VoidCallback onTap;

  const RequestListItem({
    super.key,
    required this.request,
    required this.collectionId,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<RequestListItem> createState() => _RequestListItemState();
}

class _RequestListItemState extends State<RequestListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    final collection = requestProvider.collections.firstWhere((c) => c.id == widget.collectionId);
    final folderColor = RequestProvider.colors[collection.color] ?? AppColors.primary;

    final itemWidget = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        onDoubleTap: () {
          _editRequest(requestProvider);
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? (isDark ? folderColor.withValues(alpha: 0.15) : folderColor.withValues(alpha: 0.12))
                : (_isHovered
                    ? (isDark ? folderColor.withValues(alpha: 0.08) : folderColor.withValues(alpha: 0.05))
                    : null),
            borderRadius: BorderRadius.circular(6),
            border: widget.isSelected
                ? Border(left: BorderSide(color: folderColor, width: 3))
                : const Border(
                    left: BorderSide(color: Colors.transparent, width: 3),
                  ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: MethodBadge(method: widget.request.method, small: true),
              ),
              Expanded(
                child: Text(
                  widget.request.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: widget.isSelected ? FontWeight.w500 : FontWeight.normal,
                    color: widget.isSelected
                        ? (isDark ? AppColors.textDark : folderColor)
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Opacity(
                opacity: (_isHovered || widget.isSelected) ? 0.7 : 0.0,
                child: IgnorePointer(
                  ignoring: !(_isHovered || widget.isSelected),
                  child: PopupMenuButton<String>(
                    onSelected: (val) => _handleMenuSelection(val, requestProvider),
                    itemBuilder: (_) => _buildPopupMenuItems(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      size: 16,
                      color: AppColors.slate400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final draggableWidget = Draggable<Map<String, dynamic>>(
      data: {
        'type': 'request',
        'requestId': widget.request.id,
        'collectionId': widget.collectionId,
      },
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: folderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                child: MethodBadge(method: widget.request.method, small: true),
              ),
              const SizedBox(width: 8),
              Text(
                widget.request.name,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: itemWidget,
      ),
      child: itemWidget,
    );

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        return data['type'] == 'request' && data['requestId'] != widget.request.id;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        requestProvider.moveRequest(
          requestId: data['requestId'] as String,
          sourceCollectionId: data['collectionId'] as String,
          targetCollectionId: widget.collectionId,
          targetRequestId: widget.request.id,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: isHovered
                ? Border.all(color: folderColor.withValues(alpha: 0.5), width: 1.5)
                : null,
            color: isHovered
                ? folderColor.withValues(alpha: 0.05)
                : null,
          ),
          child: GestureDetector(
            onSecondaryTapDown: (details) {
              _showContextMenu(details.globalPosition, requestProvider);
            },
            child: draggableWidget,
          ),
        );
      },
    );
  }

  List<PopupMenuEntry<String>> _buildPopupMenuItems(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white70 : Colors.black87;

    return [
      PopupMenuItem<String>(
        value: 'rename',
        child: Row(
          children: [
            Icon(Icons.edit_outlined, size: 16, color: color),
            const SizedBox(width: 8),
            const Text('Rename'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'duplicate',
        child: Row(
          children: [
            Icon(Icons.copy_rounded, size: 16, color: color),
            const SizedBox(width: 8),
            const Text('Duplicate'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'move',
        child: Row(
          children: [
            Icon(Icons.drive_file_move_outlined, size: 16, color: color),
            const SizedBox(width: 8),
            const Text('Move to Folder'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ],
        ),
      ),
    ];
  }

  void _handleMenuSelection(String value, RequestProvider provider) async {
    if (value == 'rename') {
      _editRequest(provider);
    } else if (value == 'duplicate') {
      provider.duplicateRequest(widget.collectionId, widget.request);
    } else if (value == 'move') {
      final targetCollectionId = await showDialog<String>(
        context: context,
        builder: (context) => MoveRequestDialog(
          collections: provider.collections,
          currentCollectionId: widget.collectionId,
        ),
      );
      if (targetCollectionId != null && mounted) {
        provider.moveRequest(
          requestId: widget.request.id,
          sourceCollectionId: widget.collectionId,
          targetCollectionId: targetCollectionId,
        );
      }
    } else if (value == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Request'),
          content: Text('Are you sure you want to delete "${widget.request.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirm == true && mounted) {
        provider.removeRequestFromCollection(widget.collectionId, widget.request.id);
      }
    }
  }

  void _showContextMenu(Offset position, RequestProvider provider) {
    final relativeRect = RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx + 1,
      position.dy + 1,
    );
    showMenu<String>(
      context: context,
      position: relativeRect,
      items: _buildPopupMenuItems(context),
    ).then((value) {
      if (!mounted) return;
      if (value != null) {
        _handleMenuSelection(value, provider);
      }
    });
  }

  void _editRequest(RequestProvider provider) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => RenameRequestDialog(initialName: widget.request.name),
    );
    if (newName != null && newName.trim().isNotEmpty && mounted) {
      provider.renameRequest(widget.collectionId, widget.request.id, newName.trim());
    }
  }
}
