import 'package:flutter/material.dart';
import 'package:gk_http_client/providers/folder_overview_provider.dart';
import 'package:gk_http_client/providers/request_provider.dart';
import 'package:gk_http_client/providers/theme_provider.dart';
import 'package:gk_http_client/providers/workspace_provider.dart';
import 'package:gk_http_client/services/navigation_service.dart';
import 'package:provider/provider.dart';

class FolderOverviewScreen extends StatefulWidget {
  const FolderOverviewScreen({super.key});

  @override
  State<FolderOverviewScreen> createState() => _FolderOverviewScreenState();
}

class _FolderOverviewScreenState extends State<FolderOverviewScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsProvider = Provider.of<WorkspaceProvider>(context, listen: false);
      final folderProvider =
          Provider.of<FolderOverviewProvider>(context, listen: false);
      folderProvider.load(wsProvider.workspaces);
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
    final folderProvider = Provider.of<FolderOverviewProvider>(context);

    final scaffoldBg =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final topBarBg = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.5)
        : Colors.white;
    final sidebarBg = isDark
        ? const Color(0xFF111827).withValues(alpha: 0.4)
        : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final labelColor =
        isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Column(
        children: [
          // ── TOP BAR ─────────────────────────────────────────────────────
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: topBarBg,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _WindowDot(color: const Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    _WindowDot(color: const Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    _WindowDot(color: const Color(0xFF10B981)),
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
                    IconButton(
                      tooltip: isDark ? 'Modo claro' : 'Modo escuro',
                      onPressed: () => themeProvider.toggleTheme(),
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: textSecondary,
                        size: 18,
                      ),
                      splashRadius: 18,
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 16, color: borderColor),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0x2010B981)
                            : const Color(0x1010B981),
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

          // ── BODY ────────────────────────────────────────────────────────
          Expanded(
            child: Row(
              children: [
                // Navigation sidebar (64 px icon strip)
                Container(
                  width: 64,
                  decoration: BoxDecoration(
                    color: sidebarBg,
                    border: Border(right: BorderSide(color: borderColor)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      // Back to workspaces
                      Tooltip(
                        message: 'Workspaces',
                        child: _SidebarIconButton(
                          icon: Icons.grid_view_rounded,
                          isActive: false,
                          labelColor: labelColor,
                          onTap: () =>
                              NavigationService.navigateTo(AppRoute.home),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Active: global folders
                      Tooltip(
                        message: 'Global Folders',
                        child: _SidebarIconButton(
                          icon: Icons.folder_open_rounded,
                          isActive: true,
                          labelColor: labelColor,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(height: 16),
                      Tooltip(
                        message: 'Environments',
                        child: _SidebarIconButton(
                          icon: Icons.language_rounded,
                          isActive: false,
                          labelColor: labelColor,
                          onTap: () {},
                        ),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: 'Settings',
                        child: _SidebarIconButton(
                          icon: Icons.settings_rounded,
                          isActive: false,
                          labelColor: labelColor,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(height: 20),
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

                // Main content
                Expanded(
                  child: Column(
                    children: [
                      // Content header
                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B).withValues(alpha: 0.3)
                              : Colors.white,
                          border:
                              Border(bottom: BorderSide(color: borderColor)),
                        ),
                        child: Row(
                          children: [
                            // Breadcrumb
                            GestureDetector(
                              onTap: () => NavigationService.navigateTo(
                                  AppRoute.home),
                              child: Text(
                                'Workspaces',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: textSecondary,
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('/',
                                  style: TextStyle(color: textSecondary)),
                            ),
                            Text(
                              'Global Folders',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const Spacer(),
                            // Search bar
                            SizedBox(
                              width: 240,
                              height: 34,
                              child: TextField(
                                controller: _searchController,
                                onChanged: folderProvider.setSearchQuery,
                                style: TextStyle(
                                    fontSize: 13, color: textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Search folders...',
                                  hintStyle: TextStyle(
                                      color: textSecondary, fontSize: 12),
                                  prefixIcon: Icon(Icons.search_rounded,
                                      size: 16, color: textSecondary),
                                  prefixIconConstraints: const BoxConstraints(
                                      minWidth: 36, minHeight: 0),
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.04),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Layout toggle
                            _LayoutToggleButton(
                              isGrid: folderProvider.isGrid,
                              isDark: isDark,
                              borderColor: borderColor,
                              onToggle: folderProvider.toggleLayout,
                            ),
                          ],
                        ),
                      ),

                      // Folder grid / list
                      Expanded(
                        child: folderProvider.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : folderProvider.items.isEmpty
                                ? _EmptyState(
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    hasSearch: folderProvider
                                        .searchQuery.isNotEmpty,
                                  )
                                : folderProvider.isGrid
                                    ? _GridView(
                                        items: folderProvider.items,
                                        isDark: isDark,
                                        borderColor: borderColor,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                      )
                                    : _ListView(
                                        items: folderProvider.items,
                                        isDark: isDark,
                                        borderColor: borderColor,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                      ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── STATUS FOOTER ───────────────────────────────────────────────
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: topBarBg,
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
                          color: labelColor),
                    ),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 12, color: borderColor),
                    const SizedBox(width: 12),
                    Text(
                      'SYNC: 1.2S AGO',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: labelColor),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text('DOCUMENTATION',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: labelColor)),
                    const SizedBox(width: 12),
                    Text('SUPPORT',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: labelColor)),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 12, color: borderColor),
                    const SizedBox(width: 12),
                    Text('V2.4.12-STABLE',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: labelColor)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper: navigate to workspace and expand a folder ────────────────────────
void _openWorkspaceFolder(
  BuildContext context, {
  required String workspaceId,
  required String collectionId,
}) {
  final wsProvider = Provider.of<WorkspaceProvider>(context, listen: false);
  final requestProvider =
      Provider.of<RequestProvider>(context, listen: false);

  wsProvider.openWorkspace(workspaceId);
  NavigationService.navigateTo(AppRoute.workspace);

  // Expand the target collection after collections are loaded.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    requestProvider.loadCollections(workspaceId).then((_) {
      requestProvider.expandCollection(collectionId);
    });
  });
}

// ─── Sidebar icon button ───────────────────────────────────────────────────────
class _SidebarIconButton extends StatefulWidget {
  const _SidebarIconButton({
    required this.icon,
    required this.isActive,
    required this.labelColor,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  State<_SidebarIconButton> createState() => _SidebarIconButtonState();
}

class _SidebarIconButtonState extends State<_SidebarIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: widget.isActive
                ? const Color(0xFF6366F1)
                : _hovered
                    ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: 20,
              color: widget.isActive
                  ? Colors.white
                  : widget.labelColor.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Window dot ───────────────────────────────────────────────────────────────
class _WindowDot extends StatelessWidget {
  const _WindowDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─── Layout toggle ────────────────────────────────────────────────────────────
class _LayoutToggleButton extends StatelessWidget {
  const _LayoutToggleButton({
    required this.isGrid,
    required this.isDark,
    required this.borderColor,
    required this.onToggle,
  });

  final bool isGrid;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleSegment(
            icon: Icons.grid_view_rounded,
            selected: isGrid,
            onTap: onToggle,
            isDark: isDark,
          ),
          _ToggleSegment(
            icon: Icons.view_list_rounded,
            selected: !isGrid,
            onTap: onToggle,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: selected ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6366F1).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 15,
            color: selected
                ? const Color(0xFF6366F1)
                : (isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8)),
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.textPrimary,
    required this.textSecondary,
    required this.hasSearch,
  });

  final Color textPrimary;
  final Color textSecondary;
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch
                ? Icons.search_off_rounded
                : Icons.folder_off_rounded,
            size: 64,
            color: textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'No folders found' : 'No collections yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try a different search term.'
                : 'Create a collection inside a workspace to see it here.',
            style: TextStyle(fontSize: 13, color: textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Grid view ────────────────────────────────────────────────────────────────
class _GridView extends StatelessWidget {
  const _GridView({
    required this.items,
    required this.isDark,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final List<CollectionWithWorkspace> items;
  final bool isDark;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.45,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _FolderCard(
          item: items[index],
          isDark: isDark,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
      ),
    );
  }
}

// ─── List view ────────────────────────────────────────────────────────────────
class _ListView extends StatelessWidget {
  const _ListView({
    required this.items,
    required this.isDark,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final List<CollectionWithWorkspace> items;
  final bool isDark;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(28),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _FolderListTile(
        item: items[index],
        isDark: isDark,
        borderColor: borderColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
      ),
    );
  }
}

// ─── Folder Card (grid) ───────────────────────────────────────────────────────
class _FolderCard extends StatefulWidget {
  const _FolderCard({
    required this.item,
    required this.isDark,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final CollectionWithWorkspace item;
  final bool isDark;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  State<_FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<_FolderCard> {
  bool _hovered = false;

  Color get _accentColor {
    final wsColor = WorkspaceProvider.iconColors[widget.item.workspace.icon];
    return wsColor ?? const Color(0xFF6366F1);
  }

  IconData get _wsIcon {
    return WorkspaceProvider.icons[widget.item.workspace.icon] ??
        Icons.folder_open_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.item.collection;
    final ws = widget.item.workspace;
    final cardBg = widget.isDark
        ? const Color(0xFF1E293B)
        : Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => _openWorkspaceFolder(
          context,
          workspaceId: ws.id,
          collectionId: c.id,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? _accentColor.withValues(alpha: 0.5)
                  : widget.borderColor,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + workspace badge
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.folder_rounded,
                        size: 20,
                        color: _accentColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Workspace badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_wsIcon,
                            size: 10, color: _accentColor),
                        const SizedBox(width: 3),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 72),
                          child: Text(
                            ws.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Folder name
              Text(
                c.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Request count
              Text(
                '${c.requests.length} ${c.requests.length == 1 ? 'request' : 'requests'}',
                style: TextStyle(
                    fontSize: 11, color: widget.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Folder List Tile (list view) ─────────────────────────────────────────────
class _FolderListTile extends StatefulWidget {
  const _FolderListTile({
    required this.item,
    required this.isDark,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final CollectionWithWorkspace item;
  final bool isDark;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  State<_FolderListTile> createState() => _FolderListTileState();
}

class _FolderListTileState extends State<_FolderListTile> {
  bool _hovered = false;

  Color get _accentColor {
    final wsColor = WorkspaceProvider.iconColors[widget.item.workspace.icon];
    return wsColor ?? const Color(0xFF6366F1);
  }

  IconData get _wsIcon {
    return WorkspaceProvider.icons[widget.item.workspace.icon] ??
        Icons.folder_open_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.item.collection;
    final ws = widget.item.workspace;
    final cardBg = widget.isDark ? const Color(0xFF1E293B) : Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => _openWorkspaceFolder(
          context,
          workspaceId: ws.id,
          collectionId: c.id,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? _accentColor.withValues(alpha: 0.5)
                  : widget.borderColor,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Folder icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.folder_rounded,
                    size: 18,
                    color: _accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name & count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${c.requests.length} ${c.requests.length == 1 ? 'request' : 'requests'}',
                      style: TextStyle(
                          fontSize: 11, color: widget.textSecondary),
                    ),
                  ],
                ),
              ),
              // Workspace badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_wsIcon, size: 11, color: _accentColor),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Text(
                        ws.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: widget.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
