import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:fletch/models/collection_model.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/models/http_request.dart';
import 'package:fletch/providers/request_provider.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:fletch/widgets/dialogs/manage_collection.dart';
import 'package:fletch/widgets/dialogs/rename_request_dialog.dart';
import 'package:provider/provider.dart';

class CollectionFolder extends StatefulWidget {
  final RequestCollection collection;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child; // List of requests and nested collections

  const CollectionFolder({
    super.key,
    required this.collection,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  State<CollectionFolder> createState() => _CollectionFolderState();
}

class _CollectionFolderState extends State<CollectionFolder> {
  bool _isHovered = false;
  bool _isDragOver = false;
  double _dragY = 0.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final collectionProvider = Provider.of<RequestProvider>(context);
    final folderColor = RequestProvider.colors[widget.collection.color] ?? AppColors.primary;
    final folderIcon = RequestProvider.icons[widget.collection.icon] ?? Icons.folder_rounded;

    Widget folderHeader = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _isHovered ? folderColor.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: InkWell(
          onTap: widget.onToggle,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 6.0,
            ),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: widget.isExpanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.slate400,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  folderIcon,
                  size: 16,
                  color: folderColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.collection.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                ),
                Opacity(
                  opacity: 0.7,
                  child: PopupMenuButton<void>(
                    onSelected: (_) {},
                    itemBuilder: (_) => _buildPopupMenuItems(collectionProvider, context),
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      size: 16,
                      color: AppColors.slate400,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Apply Tooltip if description is present
    if (widget.collection.description != null && widget.collection.description!.isNotEmpty) {
      folderHeader = Tooltip(
        message: widget.collection.description!,
        waitDuration: const Duration(milliseconds: 500),
        child: folderHeader,
      );
    }

    // Wrap header in GestureDetector for right-click context menu
    folderHeader = GestureDetector(
      onSecondaryTapDown: (details) {
        _showContextMenu(details.globalPosition, collectionProvider);
      },
      child: folderHeader,
    );

    // Make the header Draggable
    final draggableHeader = Draggable<Map<String, dynamic>>(
      data: {
        'type': 'collection',
        'collectionId': widget.collection.id,
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
              Icon(
                folderIcon,
                size: 16,
                color: folderColor,
              ),
              const SizedBox(width: 8),
              Text(
                widget.collection.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: folderHeader,
      ),
      child: folderHeader,
    );

    // DragTarget managing drop target regions
    final dragTargetHeader = DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data['type'] == 'request') return true;
        if (data['type'] == 'collection') {
          return data['collectionId'] != widget.collection.id;
        }
        return false;
      },
      onMove: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final localPos = renderBox.globalToLocal(details.offset);
        setState(() {
          _dragY = localPos.dy;
        });
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data['type'] == 'request') {
          collectionProvider.moveRequest(
            requestId: data['requestId'] as String,
            sourceCollectionId: data['collectionId'] as String,
            targetCollectionId: widget.collection.id,
          );
        } else if (data['type'] == 'collection') {
          final draggedId = data['collectionId'] as String;
          if (_dragY < 8) {
            collectionProvider.reorderCollections(draggedId, widget.collection.id, before: true);
          } else if (_dragY > 24) {
            collectionProvider.reorderCollections(draggedId, widget.collection.id, before: false);
          } else {
            collectionProvider.nestCollection(draggedId, widget.collection.id);
          }
        }
        setState(() {
          _isDragOver = false;
        });
      },
      onLeave: (_) {
        setState(() {
          _isDragOver = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        _isDragOver = candidateData.isNotEmpty;
        final isRequest = candidateData.isNotEmpty && candidateData.first?['type'] == 'request';

        bool isTopZone = false;
        bool isBottomZone = false;
        bool isMiddleZone = isRequest;

        if (_isDragOver && !isRequest) {
          if (_dragY < 8) {
            isTopZone = true;
          } else if (_dragY > 24) {
            isBottomZone = true;
          } else {
            isMiddleZone = true;
          }
        }

        Widget headerWidget = draggableHeader;

        if (isMiddleZone) {
          headerWidget = DottedBorder(
            color: folderColor,
            strokeWidth: 1.5,
            dashPattern: const [4, 4],
            borderType: BorderType.RRect,
            radius: const Radius.circular(6),
            padding: EdgeInsets.zero,
            child: headerWidget,
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border(
              top: isTopZone
                  ? BorderSide(color: folderColor, width: 2.0)
                  : BorderSide.none,
              bottom: isBottomZone
                  ? BorderSide(color: folderColor, width: 2.0)
                  : BorderSide.none,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isMiddleZone ? folderColor.withValues(alpha: 0.12) : null,
            ),
            child: headerWidget,
          ),
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dragTargetHeader,
        if (widget.isExpanded) ...[
          const SizedBox(height: 4),
          Container(
            margin: const EdgeInsets.only(left: 18),
            padding: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: folderColor.withValues(alpha: isDark ? 0.35 : 0.25),
                  width: 1.5,
                ),
              ),
            ),
            child: widget.child,
          ),
        ],
      ],
    );
  }

  List<PopupMenuEntry<void>> _buildPopupMenuItems(
    RequestProvider provider,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white70 : Colors.black87;

    return [
      PopupMenuItem(
        onTap: () => provider.startCollectionRun(widget.collection),
        child: Row(
          children: [
            Icon(Icons.play_circle_outline_rounded, size: 16, color: color),
            const SizedBox(width: 8),
            const Text('Run Folder'),
          ],
        ),
      ),
      PopupMenuItem(
        onTap: () => _createNewRequest(context, provider),
        child: Row(
          children: [
            Icon(Icons.add_rounded, size: 16, color: color),
            const SizedBox(width: 8),
            const Text('Create New Request'),
          ],
        ),
      ),
      PopupMenuItem(
        onTap: () {
          Future.delayed(
            Duration.zero,
            () {
              if (context.mounted) {
                _createNewSubFolder(context, provider);
              }
            },
          );
        },
        child: Row(
          children: [
            Icon(Icons.create_new_folder_rounded, size: 16, color: color),
            const SizedBox(width: 8),
            const Text('Create Sub-Folder'),
          ],
        ),
      ),
      PopupMenuItem(
        onTap: () {
          Future.delayed(
            Duration.zero,
            () {
              if (context.mounted) {
                _openEditCollectionDialog(context, isDark);
              }
            },
          );
        },
        child: Row(
          children: [
            Icon(Icons.edit_rounded, size: 16, color: color),
            const SizedBox(width: 8),
            const Text('Edit Folder'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        onTap: () {
          Future.delayed(Duration.zero, () async {
            if (!context.mounted) return;
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Folder'),
                content: Text('Are you sure you want to delete "${widget.collection.name}"? This will delete all requests and nested folders inside it.'),
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
            if (confirm == true && context.mounted) {
              await provider.removeCollection(widget.collection.id);
            }
          });
        },
        child: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete Folder', style: TextStyle(color: Colors.redAccent)),
          ],
        ),
      ),
    ];
  }

  void _showContextMenu(Offset position, RequestProvider provider) {
    final relativeRect = RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx + 1,
      position.dy + 1,
    );
    showMenu<void>(
      context: context,
      position: relativeRect,
      items: _buildPopupMenuItems(provider, context),
    );
  }

  void _openEditCollectionDialog(BuildContext context, bool isDark) {
    final Map<String, IconData> icons = RequestProvider.icons;
    final Map<String, Color> colors = RequestProvider.colors;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: NewCollectionDialogBody(
            icons: icons,
            colors: colors,
            isDark: isDark,
            collection: widget.collection,
          ),
        );
      },
    );
  }

  Future<void> _createNewRequest(
    BuildContext context,
    RequestProvider provider,
  ) async {
    final newRequest = HttpRequest(
      id: UniqueKey().toString(),
      name: 'New Request',
      method: HttpMethod.get,
      url: '',
    );

    final updatedCollection = widget.collection.copyWith(
      requests: [...widget.collection.requests, newRequest],
    );

    await provider.updateCollection(updatedCollection);
  }

  Future<void> _createNewSubFolder(
    BuildContext context,
    RequestProvider provider,
  ) async {
    final subFolderName = await showDialog<String>(
      context: context,
      builder: (context) => const RenameRequestDialog(
        initialName: 'New Sub-folder',
        title: 'Create Sub-Folder',
        label: 'SUB-FOLDER NAME',
      ),
    );
    if (subFolderName != null && subFolderName.trim().isNotEmpty) {
      await provider.createSubCollection(widget.collection.id, subFolderName.trim());
    }
  }
}
