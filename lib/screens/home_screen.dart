import 'package:flutter/material.dart';
import 'package:gk_http_client/models/workspace_models.dart';
import 'package:gk_http_client/providers/theme_provider.dart';
import 'package:gk_http_client/providers/workspace_provider.dart';
import 'package:gk_http_client/services/navigation_service.dart';
import 'package:gk_http_client/widgets/dialogs/create_workspace_dialog.dart';
import 'package:gk_http_client/widgets/dialogs/edit_workspace_dialog.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final WorkspaceProvider wsProvider = Provider.of<WorkspaceProvider>(context);

    // Color definitions based on theme
    final scaffoldBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final topBarBgColor = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.white;
    final sidebarBgColor = isDark ? const Color(0xFF111827).withValues(alpha: 0.4) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);
    final textPrimaryColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final labelColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    // Filter workspaces based on search query
    final filteredWorkspaces = wsProvider.workspaces.where((ws) {
      final nameMatches = ws.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final descMatches = ws.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || descMatches;
    }).toList();

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: Column(
        children: [
          // 1. TOP BAR (Window controls & Title)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: topBarBgColor,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Mock window dots
                    _buildWindowDot(const Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    _buildWindowDot(const Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    _buildWindowDot(const Color(0xFF10B981)),
                    const SizedBox(width: 20),
                    Text(
                      'HTTP Client - GK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: labelColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Theme Switcher Button
                    IconButton(
                      onPressed: () => themeProvider.toggleTheme(),
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: textSecondaryColor,
                        size: 18,
                      ),
                      splashRadius: 18,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 16,
                      color: borderColor,
                    ),
                    const SizedBox(width: 16),
                    // Cloud Sync Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x2010B981) : const Color(0x1010B981),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Cloud Sync Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. EXPANDED WORKSPACE CONTENT WITH SIDEBAR
          Expanded(
            child: Row(
              children: [
                // Navigation/Sidebar
                Container(
                  width: 64,
                  decoration: BoxDecoration(
                    color: sidebarBgColor,
                    border: Border(right: BorderSide(color: borderColor)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      // Active Workspaces button
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.grid_view_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Folder Overview Navigation
                      Tooltip(
                        message: 'Global Folders',
                        child: GestureDetector(
                          onTap: () => NavigationService.navigateTo(AppRoute.folders),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.folder_open_rounded,
                                  color: labelColor.withValues(alpha: 0.6),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Mock Environment Navigation
                      _buildSidebarNavButton(Icons.language_rounded, labelColor),
                      const Spacer(),
                      // Settings button
                      _buildSidebarNavButton(Icons.settings_rounded, labelColor),
                      const SizedBox(height: 20),
                      // User Avatar
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'GK',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main workspace list
                Expanded(
                  child: ListenableBuilder(
                    listenable: wsProvider,
                    builder: (context, child) {
                      if (wsProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header & Search
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Seus Workspaces',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Manage and organize your API projects.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                // Search bar
                                SizedBox(
                                  width: 280,
                                  height: 38,
                                  child: TextField(
                                    controller: _searchController,
                                    style: TextStyle(fontSize: 13, color: textPrimaryColor),
                                    decoration: InputDecoration(
                                      hintText: 'Search workspaces...',
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: labelColor.withValues(alpha: 0.7),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: labelColor.withValues(alpha: 0.7),
                                        size: 18,
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? const Color(0xFF1E293B).withValues(alpha: 0.3)
                                          : const Color(0xFFF1F5F9),
                                      contentPadding: EdgeInsets.zero,
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF6366F1)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Grid view
                            Expanded(
                              child: wsProvider.workspaces.isEmpty
                                  ? _buildEmptyState(context, wsProvider)
                                  : (filteredWorkspaces.isEmpty && _searchQuery.isNotEmpty)
                                      ? _buildNoResultsState(textPrimaryColor, textSecondaryColor)
                                      : GridView.builder(
                                          gridDelegate:
                                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                            maxCrossAxisExtent: 320,
                                            crossAxisSpacing: 24,
                                            mainAxisSpacing: 24,
                                            childAspectRatio: 1.3,
                                          ),
                                          itemCount: filteredWorkspaces.length + 1,
                                          itemBuilder: (context, index) {
                                            if (index == 0) {
                                              return _AddWorkspaceCard(
                                                onTap: () => _showCreateWorkspaceDialog(
                                                  context,
                                                  wsProvider,
                                                ),
                                              );
                                            }

                                            final ws = filteredWorkspaces[index - 1];

                                            return _WorkspaceCard(
                                              workspace: ws,
                                              onTap: () {
                                                wsProvider.openWorkspace(ws.id);
                                                NavigationService.navigateTo(AppRoute.workspace);
                                              },
                                              onEdit: () => _showEditWorkspaceDialog(
                                                context,
                                                wsProvider,
                                                ws,
                                              ),
                                              onDelete: () => wsProvider.removeWorkspace(ws.id),
                                              onIconTap: (position, size) => _openIconSelector(
                                                context,
                                                position,
                                                size,
                                                ws.id,
                                              ),
                                            );
                                          },
                                        ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 3. STATUS FOOTER
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: topBarBgColor,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CONNECTED: GLOBAL-CLOUD-V2',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 12,
                      color: borderColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'SYNC: 1.2S AGO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: labelColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'DOCUMENTATION',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'SUPPORT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 12,
                      color: borderColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'V2.4.12-STABLE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: labelColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSidebarNavButton(IconData icon, Color color) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            icon,
            color: color.withValues(alpha: 0.6),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState(Color textPrimaryColor, Color textSecondaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: textSecondaryColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No matching workspaces found',
            style: TextStyle(color: textPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try typing a different name or description query.',
            style: TextStyle(color: textSecondaryColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WorkspaceProvider workspaceProvider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: textSecondaryColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No workspaces found',
            style: TextStyle(
              color: textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first workspace to start making API requests.',
            style: TextStyle(color: textSecondaryColor, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateWorkspaceDialog(context, workspaceProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Create First Workspace',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
    showDialog(
      context: context,
      builder: (context) => EditWorkspaceDialog(
        workspaceProvider: workspaceProvider,
        workspace: workspace,
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
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: 'Icon Selector',
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder:
          (
            BuildContext dialogContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            final Size screenSize = MediaQuery.of(dialogContext).size;
            final double overlayWidth = screenSize.width;
            final double overlayHeight = screenSize.height;

            const double selectorWidth = 260;
            const double selectorHeight = 250;

            double left = buttonPosition.dx;
            double top = buttonPosition.dy + buttonSize.height + 4;

            if (left + selectorWidth > overlayWidth) {
              left = overlayWidth - selectorWidth - 16;
            }

            if (top + selectorHeight > overlayHeight) {
              top = buttonPosition.dy - selectorHeight - 4;
            }

            final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
            final popupBgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
            final borderColor = isDark ? const Color(0xFF1E293B) : Colors.black.withValues(alpha: 0.08);

            return Stack(
              children: <Widget>[
                Positioned(
                  left: left,
                  top: top,
                  child: Material(
                    color: popupBgColor,
                    elevation: 12.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      side: BorderSide(color: borderColor),
                    ),
                    child: Container(
                      width: selectorWidth,
                      height: selectorHeight,
                      padding: const EdgeInsets.all(16),
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
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
                child: child,
              ),
            );
          },
    );
  }
}

class _WorkspaceCard extends StatefulWidget {
  final WorkspaceModel workspace;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(Offset, Size) onIconTap;

  const _WorkspaceCard({
    required this.workspace,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onIconTap,
  });

  @override
  State<_WorkspaceCard> createState() => _WorkspaceCardState();
}

class _WorkspaceCardState extends State<_WorkspaceCard> {
  bool _isHovered = false;
  bool _isIconHovered = false;
  final GlobalKey _iconKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    final iconKey = WorkspaceProvider.icons[widget.workspace.icon] ?? Icons.folder_open_rounded;
    final iconColor = WorkspaceProvider.iconColors[widget.workspace.icon] ?? const Color(0xFF94A3B8);

    final int requestCount = widget.workspace.requestCount;
    final String timeStr = _getRelativeTimeString(widget.workspace.createdAt);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: _isHovered 
              ? Matrix4.translationValues(0, -4, 0) 
              : Matrix4.identity(),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? const Color(0xFF6366F1).withValues(alpha: 0.5) : borderColor,
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.15 : 0.02),
                blurRadius: _isHovered ? 16 : 4,
                offset: _isHovered ? const Offset(0, 8) : const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon & Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MouseRegion(
                    onEnter: (_) => setState(() => _isIconHovered = true),
                    onExit: (_) => setState(() => _isIconHovered = false),
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        final RenderBox renderBox = _iconKey.currentContext!.findRenderObject() as RenderBox;
                        final position = renderBox.localToGlobal(Offset.zero);
                        widget.onIconTap(position, renderBox.size);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        key: _iconKey,
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isIconHovered ? iconColor : Colors.transparent,
                            width: _isIconHovered ? 2.0 : 1.0,
                          ),
                        ),
                        child: Icon(
                          iconKey,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: labelColor.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    splashRadius: 20,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: borderColor),
                    ),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    onSelected: (value) {
                      if (value == 'edit') {
                        widget.onEdit();
                      } else if (value == 'delete') {
                        widget.onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16, color: labelColor),
                            const SizedBox(width: 10),
                            Text('Edit', style: TextStyle(fontSize: 14, color: textColor)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                            const SizedBox(width: 10),
                            Text('Delete', style: TextStyle(fontSize: 14, color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Workspace Name
              Text(
                widget.workspace.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Workspace Description
              Expanded(
                child: Text(
                  widget.workspace.description.isNotEmpty
                      ? widget.workspace.description
                      : 'No description provided.',
                  style: TextStyle(
                    fontSize: 12,
                    color: labelColor.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              // Bottom Row (Metrics)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: labelColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: labelColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 13,
                        color: labelColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$requestCount Requests',
                        style: TextStyle(
                          fontSize: 11,
                          color: labelColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddWorkspaceCard extends StatefulWidget {
  final VoidCallback onTap;

  const _AddWorkspaceCard({required this.onTap});

  @override
  State<_AddWorkspaceCard> createState() => _AddWorkspaceCardState();
}

class _AddWorkspaceCardState extends State<_AddWorkspaceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);
    final cardBgColor = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.2) : const Color(0xFFF1F5F9).withValues(alpha: 0.3);
    final primaryColor = const Color(0xFF6366F1);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered ? cardBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? primaryColor.withValues(alpha: 0.5) : borderColor,
              width: 2.0,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isHovered ? primaryColor : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: _isHovered ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Create New Workspace',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isHovered ? primaryColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconSelector extends StatelessWidget {
  const _IconSelector({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context);
    final ws = workspaceProvider.workspaces.firstWhere(
      (w) => w.id == workspaceId,
      orElse: () => workspaceProvider.workspaces.first,
    );
    final currentIcon = ws.icon;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);

    // Mockup's 15 specific icons
    final List<String> mockupIcons = [
      'bolt', 'api', 'shield', 'package', 'bar_chart',
      'search_activity', 'code', 'cloud', 'database', 'hub',
      'terminal', 'dns', 'deployed_code', 'security', 'lock'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            'CHOOSE ICON',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: titleColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.count(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final iconKey in mockupIcons) ...[
                Builder(
                  builder: (context) {
                    final iconData = WorkspaceProvider.icons[iconKey] ?? Icons.folder_rounded;
                    final isSelected = currentIcon == iconKey;
                    
                    return InkWell(
                      onTap: () {
                        workspaceProvider.updateWorkspaceIcon(workspaceId, iconKey);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF6366F1)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            iconData,
                            color: isSelected
                                ? const Color(0xFF6366F1)
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                            size: 18,
                          ),
                        ),
                      ),
                    );
                  }
                )
              ]
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          color: borderColor,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Close',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}

String _getRelativeTimeString(DateTime dt) {
  final now = DateTime.now();
  final difference = now.difference(dt);

  if (difference.inSeconds < 60) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;
    return '${minutes}m ago';
  } else if (difference.inHours < 24) {
    final hours = difference.inHours;
    return '${hours}h ago';
  } else if (difference.inDays < 7) {
    final days = difference.inDays;
    return days == 1 ? 'Yesterday' : '$days days ago';
  } else {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
