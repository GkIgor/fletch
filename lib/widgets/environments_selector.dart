import 'package:flutter/material.dart';
import 'package:fletch/providers/workspace_provider.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:provider/provider.dart';

class EnvironmentsSelector extends StatelessWidget {
  const EnvironmentsSelector({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final wsProvider = Provider.of<WorkspaceProvider>(context);
    final activeEnv = wsProvider.activeEnvironment;
    final environments = wsProvider.currentWorkspace?.environments ?? [];

    return PopupMenuButton<String?>(
      tooltip: 'Select Environment',
      offset: const Offset(0, 40),
      onSelected: (envId) {
        if (envId == 'manage') {
          wsProvider.isManagingEnvironments = true;
        } else {
          wsProvider.selectEnvironment(envId);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String?>(
          value: null,
          child: Text('No Environment'),
        ),
        const PopupMenuDivider(),
        ...environments.map((env) => PopupMenuItem<String?>(
          value: env.id,
          child: Row(
            children: [
              if (activeEnv?.id == env.id)
                const Icon(Icons.check, size: 16, color: AppColors.primary)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Icon(
                WorkspaceProvider.icons[env.icon] ?? Icons.language_rounded,
                size: 14,
                color: WorkspaceProvider.iconColors[env.icon] ?? AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(env.name),
            ],
          ),
        )),
        const PopupMenuDivider(),
        const PopupMenuItem<String?>(
          value: 'manage',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 16),
              SizedBox(width: 8),
              Text('Manage Environments'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.slate800 : AppColors.slate100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              activeEnv != null
                  ? (WorkspaceProvider.icons[activeEnv.icon] ?? Icons.language_rounded)
                  : Icons.public,
              size: 14,
              color: activeEnv != null
                  ? (WorkspaceProvider.iconColors[activeEnv.icon] ?? AppColors.slate500)
                  : AppColors.slate500,
            ),
            const SizedBox(width: 8),
            Text(
              activeEnv?.name ?? 'No Environment',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.slate500),
          ],
        ),
      ),
    );
  }
}
