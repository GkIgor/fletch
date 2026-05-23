import 'package:flutter/material.dart';
import 'package:gk_http_client/models/collection_model.dart';
import 'package:gk_http_client/models/http_method.dart';
import 'package:gk_http_client/models/http_request.dart';
import 'package:gk_http_client/providers/request_provider.dart';
import 'package:gk_http_client/theme/app_colors.dart';
import 'package:gk_http_client/widgets/dialogs/manage_collection.dart';
import 'package:provider/provider.dart';

class CollectionFolder extends StatelessWidget {
  final RequestCollection collection;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child; // Lista de requisições

  const CollectionFolder({
    super.key,
    required this.collection,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final collectionProvider = Provider.of<RequestProvider>(context);

    final folderHeader = InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded,
              size: 16,
              color: AppColors.slate400,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                collection.name,
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
                itemBuilder: (_) =>
                    _popupMenuItems(collectionProvider, context),
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  size: 16,
                  color: AppColors.slate400,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final draggableHeader = Draggable<Map<String, dynamic>>(
      data: {
        'type': 'collection',
        'collectionId': collection.id,
      },
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primary, width: 1.5),
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
                Icons.folder_rounded,
                size: 16,
                color: AppColors.slate400,
              ),
              const SizedBox(width: 8),
              Text(
                collection.name,
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

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data['type'] == 'request') {
          return true;
        }
        if (data['type'] == 'collection') {
          return data['collectionId'] != collection.id;
        }
        return false;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data['type'] == 'request') {
          collectionProvider.moveRequest(
            requestId: data['requestId'] as String,
            sourceCollectionId: data['collectionId'] as String,
            targetCollectionId: collection.id,
          );
        } else if (data['type'] == 'collection') {
          collectionProvider.reorderCollections(
            data['collectionId'] as String,
            collection.id,
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: isHovered
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5)
                : null,
            color: isHovered
                ? AppColors.primary.withValues(alpha: 0.05)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              draggableHeader,
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: child,
                ),
            ],
          ),
        );
      },
    );
  }

  List<PopupMenuItem<void>> _popupMenuItems(
    RequestProvider provider,
    BuildContext context,
  ) {
    return [
      PopupMenuItem(
        onTap: () async {
          await _createNewRequest(context, provider);
        },
        child: const Text('Create New Request'),
      ),
      PopupMenuItem(
        onTap: () {
          _openEditCollectionDialog(
            context,
            Theme.of(context).brightness == Brightness.dark,
          );
        },
        child: const Text('Edit'),
      ),
      PopupMenuItem(
        onTap: () async {
          await provider.removeCollection(collection.id);
        },
        child: const Text('Delete'),
      ),
    ];
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
            collection: collection,
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

    final updatedCollection = collection.copyWith(
      requests: [...collection.requests, newRequest],
    );

    await provider.updateCollection(updatedCollection);
  }
}
