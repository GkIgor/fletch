import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fletch/models/runner_item_state.dart';
import 'package:fletch/providers/request_provider.dart';
import 'package:fletch/providers/workspace_provider.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:fletch/theme/app_theme.dart';
import 'package:fletch/widgets/response_viewer.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/models/http_response.dart';

class RunnerView extends StatefulWidget {
  const RunnerView({super.key});

  @override
  State<RunnerView> createState() => _RunnerViewState();
}

class _RunnerViewState extends State<RunnerView> {
  late TextEditingController _delayController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<RequestProvider>(context, listen: false);
    _delayController = TextEditingController(text: provider.runnerDelayMs.toString());
  }

  @override
  void dispose() {
    _delayController.dispose();
    super.dispose();
  }

  Color _getMethodColor(HttpMethod method) {
    switch (method) {
      case HttpMethod.get:
        return AppColors.methodGet;
      case HttpMethod.post:
        return AppColors.methodPost;
      case HttpMethod.put:
        return AppColors.methodPut;
      case HttpMethod.delete:
        return AppColors.methodDelete;
      case HttpMethod.patch:
        return AppColors.methodPatch;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RequestProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    // Calculate metrics
    final total = provider.runnerItems.length;
    final selectedItems = provider.runnerItems.where((item) => item.isSelected).toList();
    final selectedCount = selectedItems.length;
    final successCount = provider.runnerItems.where((item) => item.isSelected && item.status == 'success').length;
    final failureCount = provider.runnerItems.where((item) => item.isSelected && item.status == 'failure').length;
    final completedCount = successCount + failureCount;

    // Calculate duration and avg response time
    int totalDuration = 0;
    int successDurationCount = 0;
    for (var item in selectedItems) {
      if (item.response != null) {
        totalDuration += item.response!.responseTime;
        successDurationCount++;
      }
    }
    final avgResponseTime = successDurationCount > 0
        ? (totalDuration / successDurationCount).toStringAsFixed(0)
        : '0';

    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          // 1. Top Control Bar (Header)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.play_circle_fill_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.isRunningWorkspace ? 'Workspace Runner' : 'Folder Runner',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider.isRunningWorkspace
                            ? 'Sequential execution of requests in workspace'
                            : 'Folder: ${provider.runnerCollection?.name ?? ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (provider.isCurrentlyRunning) {
                      provider.stopRunnerExecution();
                    }
                    provider.closeRunner();
                  },
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close Runner',
                ),
              ],
            ),
          ),

          // 2. Main split view
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Column: Execution List and Controls
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: borderColor)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Stats Cards
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: GridView.count(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 8,
                            shrinkWrap: true,
                            childAspectRatio: 2.2,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildStatCard(
                                title: 'Requests',
                                value: '$completedCount / $selectedCount',
                                icon: Icons.playlist_play_rounded,
                                color: AppColors.primary,
                                isDark: isDark,
                                cardColor: cardColor,
                              ),
                              _buildStatCard(
                                title: 'Success',
                                value: '$successCount',
                                icon: Icons.check_circle_outline_rounded,
                                color: AppColors.statusSuccess,
                                isDark: isDark,
                                cardColor: cardColor,
                              ),
                              _buildStatCard(
                                title: 'Failed',
                                value: '$failureCount',
                                icon: Icons.error_outline_rounded,
                                color: AppColors.statusError,
                                isDark: isDark,
                                cardColor: cardColor,
                              ),
                              _buildStatCard(
                                title: 'Avg Time',
                                value: '${avgResponseTime}ms',
                                icon: Icons.timer_outlined,
                                color: AppColors.statusInfo,
                                isDark: isDark,
                                cardColor: cardColor,
                              ),
                            ],
                          ),
                        ),

                        Divider(height: 1, color: borderColor),

                        // Delay and Run controls
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              // Delay Input
                              SizedBox(
                                width: 140,
                                child: TextField(
                                  controller: _delayController,
                                  keyboardType: TextInputType.number,
                                  enabled: !provider.isCurrentlyRunning,
                                  decoration: InputDecoration(
                                    labelText: 'Delay (ms)',
                                    labelStyle: const TextStyle(fontSize: 12),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 13),
                                  onChanged: (val) {
                                    final ms = int.tryParse(val) ?? 0;
                                    provider.setRunnerDelay(ms);
                                  },
                                ),
                              ),
                              const Spacer(),
                              // Selection controls
                              if (!provider.isCurrentlyRunning) ...[
                                TextButton.icon(
                                  onPressed: () => provider.toggleAllRunnerItems(true),
                                  icon: const Icon(Icons.select_all_rounded, size: 16),
                                  label: const Text('All', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => provider.toggleAllRunnerItems(false),
                                  icon: const Icon(Icons.deselect_rounded, size: 16),
                                  label: const Text('None', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 16),
                              // Run/Stop Button
                              ElevatedButton.icon(
                                onPressed: selectedCount == 0
                                    ? null
                                    : () {
                                        if (provider.isCurrentlyRunning) {
                                          provider.stopRunnerExecution();
                                        } else {
                                          final wsProvider = Provider.of<WorkspaceProvider>(context, listen: false);
                                          final activeEnv = wsProvider.activeEnvironment;
                                          final Map<String, String> variables = activeEnv?.variables.map((k, v) => MapEntry(k, v.value)) ?? {};
                                          provider.executeRunnerSession(
                                            variables: variables,
                                            workspaceAuth: wsProvider.currentWorkspace?.auth,
                                          );
                                        }
                                      },
                                icon: Icon(
                                  provider.isCurrentlyRunning
                                      ? Icons.stop_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  provider.isCurrentlyRunning ? 'Stop' : 'Run',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: provider.isCurrentlyRunning
                                      ? AppColors.statusError
                                      : AppColors.statusSuccess,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Divider(height: 1, color: borderColor),

                        // Request Checklist List
                        Expanded(
                          child: ListView.separated(
                            itemCount: total,
                            separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
                            itemBuilder: (context, index) {
                              final item = provider.runnerItems[index];
                              final isSelected = item.isSelected;
                              final isCurrent = provider.runnerCurrentIndex == index;
                              final isHighlight = provider.selectedRunnerItem == item;

                              return InkWell(
                                onTap: () {
                                  provider.selectRunnerItem(item);
                                },
                                child: Container(
                                  color: isHighlight
                                      ? AppColors.primary.withValues(alpha: 0.08)
                                      : (isCurrent ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent),
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                                  child: Row(
                                    children: [
                                      // Checkbox
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: isSelected,
                                          activeColor: AppColors.primary,
                                          onChanged: provider.isCurrentlyRunning
                                              ? null
                                              : (val) {
                                                  provider.setRunnerItemSelection(index, val ?? false);
                                                },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Method Badge
                                      Container(
                                        width: 60,
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getMethodColor(item.request.method).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: _getMethodColor(item.request.method).withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Text(
                                          item.request.method.value,
                                          style: TextStyle(
                                            color: _getMethodColor(item.request.method),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Request Name and URL
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.request.name.isNotEmpty
                                                  ? item.request.name
                                                  : 'Untitled Request',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white : Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.request.url.isNotEmpty ? item.request.url : 'No URL',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Status Indicator
                                      _buildStatusWidget(item),
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
                ),

                // Right Column: Request/Response Detailed Pane
                Expanded(
                  flex: 6,
                  child: provider.selectedRunnerItem == null
                      ? _buildEmptyDetailsPane(isDark)
                      : _buildDetailsPane(provider.selectedRunnerItem!, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusWidget(RunnerItemState item) {
    switch (item.status) {
      case 'running':
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        );
      case 'success':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.response != null) ...[
              Text(
                '${item.response!.statusCode}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.statusSuccess,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.statusSuccess,
              size: 16,
            ),
          ],
        );
      case 'failure':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.response != null && item.response!.statusCode > 0) ...[
              Text(
                '${item.response!.statusCode}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.statusError,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(
              Icons.error_rounded,
              color: AppColors.statusError,
              size: 16,
            ),
          ],
        );
      case 'pending':
      default:
        return Icon(
          Icons.hourglass_empty_rounded,
          color: Colors.grey.withValues(alpha: 0.5),
          size: 16,
        );
    }
  }

  Widget _buildEmptyDetailsPane(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 48,
            color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.5) : AppColors.textSecondaryLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Request Selected',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select a request from the list to view its response details.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPane(RunnerItemState item, bool isDark) {
    final response = item.response;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header info of selected request
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getMethodColor(item.request.method).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.request.method.value,
                      style: TextStyle(
                        color: _getMethodColor(item.request.method),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.request.name.isNotEmpty ? item.request.name : 'Untitled Request',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText(
                item.request.url.isNotEmpty ? item.request.url : 'No URL',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: AppTheme.codeStyle().fontFamily,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),

        // Body content or status
        Expanded(
          child: _buildDetailsBody(item, response, isDark),
        ),
      ],
    );
  }

  Widget _buildDetailsBody(RunnerItemState item, HttpResponse? response, bool isDark) {
    if (item.status == 'pending') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_bottom_rounded,
              size: 40,
              color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.5) : AppColors.textSecondaryLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Pending Execution',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    if (item.status == 'running') {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Executing request...',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Success or failure
    if (response != null) {
      return ResponseViewer(response: response);
    }

    // If there was an error with no HTTP response (e.g. DNS failure, invalid URL)
    if (item.errorMessage != null) {
      final errorColor = AppColors.statusError;
      return Container(
        padding: const EdgeInsets.all(24.0),
        color: isDark ? AppColors.backgroundDark : Colors.red.shade50,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline_rounded, color: errorColor),
                const SizedBox(width: 10),
                Text(
                  'Execution Error',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : errorColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  border: Border.all(color: errorColor.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    item.errorMessage!,
                    style: TextStyle(
                      fontFamily: AppTheme.codeStyle().fontFamily,
                      fontSize: 12,
                      color: isDark ? Colors.red.shade300 : Colors.red.shade900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Text(
        'No execution log data available.',
        style: TextStyle(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
