import 'package:flutter/material.dart';
import 'package:gk_http_client/providers/workspace_provider.dart';
import 'package:gk_http_client/services/navigation_service.dart';
import 'package:gk_http_client/theme/app_colors.dart';
import 'package:provider/provider.dart';

class SelectWorkspaceForEnvironmentsDialog extends StatelessWidget {
  const SelectWorkspaceForEnvironmentsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final wsProvider = Provider.of<WorkspaceProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final backgroundColor = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08);
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final listTileHoverColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    final workspaces = wsProvider.workspaces;

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
        side: BorderSide(color: borderColor),
      ),
      elevation: 24,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 460,
        constraints: const BoxConstraints(maxHeight: 520),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Workspace',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: labelColor,
                    size: 20,
                  ),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Select a workspace to manage its environments and variables.',
              style: TextStyle(
                fontSize: 14,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 24),

            // Workspaces List
            Flexible(
              child: workspaces.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_off_rounded,
                              size: 48,
                              color: labelColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No workspaces found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please create a workspace first.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: labelColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: workspaces.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ws = workspaces[index];
                        final iconData = WorkspaceProvider.icons[ws.icon] ?? Icons.folder_open_rounded;
                        final iconColor = WorkspaceProvider.iconColors[ws.icon] ?? AppColors.primary;

                        return InkWell(
                          onTap: () {
                            wsProvider.openWorkspace(ws.id);
                            wsProvider.isManagingEnvironments = true;
                            NavigationService.navigateTo(AppRoute.workspace);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          hoverColor: listTileHoverColor,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: iconColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    iconData,
                                    color: iconColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ws.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      if (ws.description.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          ws.description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: labelColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: labelColor.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
