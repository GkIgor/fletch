import 'package:flutter/material.dart';
import 'package:gk_http_client/providers/workspace_provider.dart';
import 'package:gk_http_client/widgets/dialogs/manage_collection.dart';
import 'package:provider/provider.dart';
import 'package:gk_http_client/models/collection_model.dart';
import 'package:gk_http_client/providers/request_provider.dart';
import 'package:gk_http_client/theme/app_colors.dart';
import 'package:gk_http_client/widgets/collection_folder.dart';
import 'package:gk_http_client/widgets/custom_scrollbar.dart';
import 'package:gk_http_client/widgets/request_list_item.dart';

class RequestSidebar extends StatefulWidget {
  const RequestSidebar({super.key});

  @override
  State<RequestSidebar> createState() => _RequestSidebarState();
}

class _RequestSidebarState extends State<RequestSidebar> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsProvider = Provider.of<WorkspaceProvider>(context, listen: false);
      final requestProvider = Provider.of<RequestProvider>(
        context,
        listen: false,
      );

      if (wsProvider.currentWorkspace != null) {
        requestProvider.loadCollections(wsProvider.currentWorkspace!.id);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestProvider = Provider.of<RequestProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 280,
      color: isDark ? AppColors.sidebarDark : AppColors.slate50,
      child: Column(
        children: [
          _SearchFilter(
            isDark: isDark,
            controller: _searchController,
            onChanged: (value) {
              requestProvider.setSearchFilter(value);
            },
          ),

          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          Expanded(
            child: CustomScrollbar(
              controller: _scrollController,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                children: [
                  ...requestProvider.filteredCollections.map((collection) {
                    return _Collection(
                      context: context,
                      provider: requestProvider,
                      collection: collection,
                    );
                  }),

                  if (requestProvider.filteredCollections.isEmpty &&
                      requestProvider.searchFilter.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No matches found',
                          style: TextStyle(
                            color: AppColors.slate400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          _NewCollectionButton(isDark: isDark),
        ],
      ),
    );
  }
}

class _NewCollectionButton extends StatelessWidget {
  const _NewCollectionButton({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () {
            _openNewCollectionDialog(context, isDark);
          },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 16, color: AppColors.slate500),
                const SizedBox(width: 4),
                Text(
                  'New Collection',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openNewCollectionDialog(BuildContext context, bool isDark) {
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
          ),
        );
      },
    );
  }
}

class _Collection extends StatelessWidget {
  final BuildContext context;
  final RequestProvider provider;
  final RequestCollection collection;

  const _Collection({
    required this.context,
    required this.provider,
    required this.collection,
  });

  @override
  Widget build(BuildContext context) {
    return CollectionFolder(
      collection: collection,
      isExpanded: collection.isExpanded,
      onToggle: () {
        provider.toggleCollectionExpansion(collection.id);
      },
      child: Column(
        children: collection.requests.map((request) {
          final isSelected = provider.selectedRequest?.id == request.id;

          return RequestListItem(
            request: request,
            collectionId: collection.id,
            isSelected: isSelected,
            onTap: () {
              provider.selectRequest(request);
              Provider.of<WorkspaceProvider>(context, listen: false)
                  .isManagingEnvironments = false;
            },
          );
        }).toList(),
      ),
    );
  }
}

class _SearchFilter extends StatelessWidget {
  const _SearchFilter({
    required this.isDark,
    required this.controller,
    required this.onChanged,
  });

  final bool isDark;
  final TextEditingController controller;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(Icons.search_rounded, size: 16, color: AppColors.slate400),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
                decoration: InputDecoration(
                  hintText: 'Filter requests...',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.slate400),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.only(bottom: 12),
                ),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
