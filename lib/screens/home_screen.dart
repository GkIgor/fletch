import 'package:flutter/material.dart';
import 'package:gk_http_client/models/workspace_models.dart';
import 'package:gk_http_client/providers/workspace_provider.dart';
import 'package:gk_http_client/services/navigation_service.dart';
import 'package:gk_http_client/theme/app_colors.dart';
import 'package:gk_http_client/widgets/home_header.dart';
import 'package:gk_http_client/widgets/dialogs/create_workspace_dialog.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _buttonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final WorkspaceProvider wsProvider = Provider.of<WorkspaceProvider>(
      context,
    );

    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListenableBuilder(
          listenable: wsProvider,
          builder: (context, child) {
            if (wsProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                // Header
                HomeHeader(isDark: isDark),

                // Grid
                Expanded(
                  child: wsProvider.workspaces.isEmpty
                      ? _buildEmptyState(context, wsProvider)
                      : GridView.builder(
                          padding: const EdgeInsets.all(40),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 400,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 1.5,
                              ),
                          itemCount: wsProvider.workspaces.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildAddButton(context, wsProvider);
                            }

                            WorkspaceModel ws =
                                wsProvider.workspaces[index - 1];

                            IconData icon =
                                WorkspaceProvider.icons[ws.icon] ??
                                Icons.folder;

                            Icon currentIcon = Icon(
                              icon,
                              color: WorkspaceProvider.iconColors[ws.icon],
                            );

                            return _buildWorkspaceCard(
                              context,
                              ws,
                              currentIcon,
                              (value) {
                                setState(() {
                                  wsProvider.removeWorkspace(ws.id);
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWorkspaceCard(
    BuildContext context,
    WorkspaceModel workspace,
    Icon currentIcon,
    Function(String) onDelete,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Provider.of<WorkspaceProvider>(
            context,
            listen: false,
          ).openWorkspace(workspace.id);

          NavigationService.navigateTo(AppRoute.workspace);
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      key: _buttonKey,
                      onTap: () {
                        final RenderBox button =
                            _buttonKey.currentContext!.findRenderObject()
                                as RenderBox;
                        final Offset buttonPosition = button.localToGlobal(
                          Offset.zero,
                        );

                        _openIconSelector(
                          context,
                          buttonPosition,
                          button.size,
                          workspace.id,
                        );
                      },
                      hoverColor: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: currentIcon,
                      ),
                    ),
                  ),
                    PopupMenuButton(
                    icon: Icon(Icons.more_horiz, color: AppColors.slate400),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    onSelected: (value) {
                      final provider = Provider.of<WorkspaceProvider>(context, listen: false);
                      if (value == 'edit') {
                        _showEditWorkspaceDialog(context, provider, workspace);
                      } else if (value == 'delete') {
                        provider.removeWorkspace(workspace.id);
                      }
                    },
                  ),
                ],
              ),
              const Spacer(),
              Text(
                workspace.name,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${workspace.environments.length} environments',
                style: TextStyle(color: AppColors.slate500, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(
    BuildContext context,
    WorkspaceProvider workspaceProvider,
  ) {
    return InkWell(
      onTap: () {
        _showCreateWorkspaceDialog(context, workspaceProvider);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.slate300,
            style: BorderStyle.solid,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ), // Dashed border replacement
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 32,
                color: AppColors.slate400,
              ),
              const SizedBox(height: 12),
              Text(
                'New Workspace',
                style: TextStyle(
                  color: AppColors.slate500,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WorkspaceProvider workspaceProvider,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.slate300),
          const SizedBox(height: 16),
          Text(
            'No workspaces found',
            style: TextStyle(color: AppColors.slate500, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                _showCreateWorkspaceDialog(context, workspaceProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create First Workspace'),
          ),
        ],
      ),
    );
  }

  void _showCreateWorkspaceDialog(
    BuildContext context,
    WorkspaceProvider workspaceProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => CreateWorkspaceDialog(
        workspaceProvider: workspaceProvider,
      ),
    );
  }

  void _showEditWorkspaceDialog(
    BuildContext context,
    WorkspaceProvider workspaceProvider,
    WorkspaceModel workspace,
  ) {
    final controller = TextEditingController(text: workspace.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Workspace'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Workspace Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await workspaceProvider.updateWorkspaceName(
                  workspace.id,
                  controller.text,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _openIconSelector(
    BuildContext context,
    Offset buttonPosition,
    Size buttonSize,
    String ws,
  ) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .0), // Transparent barrier
      barrierDismissible: true,
      barrierLabel: 'Icon Selector',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder:
          (
            BuildContext dialogContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            final RenderBox overlay =
                Overlay.of(context).context.findRenderObject() as RenderBox;
            final Size overlaySize = overlay.size;

            const double selectorWidth = 250;
            const double selectorHeight = 150;

            double left = buttonPosition.dx;
            double top = buttonPosition.dy + buttonSize.height;

            if (left + selectorWidth > overlaySize.width) {
              left = overlaySize.width - selectorWidth;
            }

            if (top + selectorHeight > overlaySize.height) {
              top = buttonPosition.dy - selectorHeight;
              if (top < 0) {
                top = 0;
              }
            }

            return Stack(
              children: <Widget>[
                Positioned(
                  left: left,
                  top: top,
                  child: Material(
                    color: Theme.of(context).cardColor,
                    elevation: 8.0,
                    borderRadius: BorderRadius.circular(8.0),
                    child: SizedBox(
                      width: selectorWidth,
                      height: selectorHeight,
                      child: _IconSelector(workspaceId: ws),
                    ),
                  ),
                ),
              ],
            );
          },
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
    );
  }
}

class _IconSelector extends StatelessWidget {
  const _IconSelector({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    WorkspaceProvider workspaceProvider = Provider.of<WorkspaceProvider>(
      context,
    );

    final icons = WorkspaceProvider.icons;

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      children: [
        for (final entry in icons.entries)
          IconButton(
            icon: Icon(entry.value),
            onPressed: () {
              workspaceProvider.updateWorkspaceIcon(workspaceId, entry.key);
              Navigator.pop(context);
            },
          ),
      ],
    );
  }
}
