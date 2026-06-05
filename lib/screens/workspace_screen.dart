import 'package:flutter/material.dart';
import 'package:fletch/providers/user_provider.dart';
import 'package:fletch/providers/workspace_provider.dart';
import 'package:fletch/widgets/environments_selector.dart';
import 'package:fletch/widgets/theme_toggle.dart';
import 'package:fletch/widgets/user_avatar.dart';
import 'package:fletch/widgets/workspace_topbar_logo.dart';
import 'package:provider/provider.dart';
import 'package:fletch/providers/request_provider.dart';
import 'package:fletch/providers/theme_provider.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:fletch/views/request_sidebar.dart';
import 'package:fletch/widgets/request_editor.dart';
import 'package:fletch/widgets/empty_request_editor.dart';
import 'package:fletch/widgets/environments_management_view.dart';
import 'package:fletch/widgets/runner_view.dart';
import 'package:fletch/widgets/workspace_auth_management_view.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  double _sidebarWidth = 280.0;
  @override
  Widget build(BuildContext context) {
    final wsProvider = Provider.of<WorkspaceProvider>(context);
    String name = 'No Workspace';

    if (wsProvider.currentWorkspace != null) {
      name = wsProvider.currentWorkspace!.name;
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final requestProvider = Provider.of<RequestProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final username = userProvider.name;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header / App Bar
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Row(
              children: [
                // Logo & Workspace Name
                WorkspaceTopBarLogo(name: name),

                const VerticalDivider(width: 32, indent: 12, endIndent: 12),

                // Environment Selector (Placeholder)
                EnvironmentsSelector(isDark: isDark),
                const SizedBox(width: 8),

                // Workspace Authentication Settings Button
                GestureDetector(
                  onTap: () {
                    wsProvider.isManagingAuth = !wsProvider.isManagingAuth;
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: wsProvider.isManagingAuth
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : (isDark ? AppColors.slate800 : AppColors.slate100),
                        borderRadius: BorderRadius.circular(6),
                        border: wsProvider.isManagingAuth
                            ? Border.all(color: AppColors.primary, width: 1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.security_rounded,
                            size: 14,
                            color: wsProvider.isManagingAuth
                                ? AppColors.primary
                                : AppColors.slate500,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Authentication',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: wsProvider.isManagingAuth
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: wsProvider.isManagingAuth
                                  ? AppColors.primary
                                  : (isDark ? AppColors.textDark : AppColors.textLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),

                // Theme Toggle
                ThemeToggle(themeProvider: themeProvider),

                const SizedBox(width: 8),

                // User Avatar
                UserAvatar(name: username),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Row(
              children: [
                // Sidebar
                RequestSidebar(width: _sidebarWidth),

                // Resizable Vertical Divider / Resize Handle
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _sidebarWidth = (_sidebarWidth + details.delta.dx).clamp(180.0, 500.0);
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: SizedBox(
                      width: 8,
                      child: Center(
                        child: Container(
                          width: 1,
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: wsProvider.isManagingEnvironments
                      ? const EnvironmentsManagementView()
                      : wsProvider.isManagingAuth
                          ? const WorkspaceAuthManagementView()
                          : requestProvider.isRunnerActive
                              ? const RunnerView()
                              : requestProvider.selectedRequest != null
                                  ? RequestEditor(
                                      key: ValueKey(requestProvider.selectedRequest!.id),
                                      request: requestProvider.selectedRequest!,
                                    )
                                  : const EmptyRequestEditor(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
