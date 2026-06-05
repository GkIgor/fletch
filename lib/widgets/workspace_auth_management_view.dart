import 'package:flutter/material.dart';
import 'package:fletch/providers/workspace_provider.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:fletch/widgets/http_auth_editor.dart';
import 'package:provider/provider.dart';

class WorkspaceAuthManagementView extends StatefulWidget {
  const WorkspaceAuthManagementView({super.key});

  @override
  State<WorkspaceAuthManagementView> createState() =>
      _WorkspaceAuthManagementViewState();
}

class _WorkspaceAuthManagementViewState
    extends State<WorkspaceAuthManagementView> {
  @override
  Widget build(BuildContext context) {
    final wsProvider = Provider.of<WorkspaceProvider>(context);
    final workspace = wsProvider.currentWorkspace;

    if (workspace == null) {
      return const Center(
        child: Text('No active workspace.'),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final cardBgColor = isDark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workspace Authentication',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Configure default authentication credentials that collections and requests can inherit.',
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button / back button
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close settings',
                  onPressed: () {
                    wsProvider.isManagingAuth = false;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: borderColor),
            const SizedBox(height: 24),

            // Card container for settings
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HttpAuthEditor(
                    initialAuth: workspace.auth,
                    showInheritOption: false, // Workspace is root, cannot inherit
                    onChanged: (updatedAuth) async {
                      workspace.auth = updatedAuth;
                      await wsProvider.addWorkspace(workspace);
                    },
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
