import 'package:flutter/material.dart';
import 'package:gk_http_client/models/workspace_models.dart';
import 'package:gk_http_client/providers/workspace_provider.dart';
import 'package:gk_http_client/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class EnvironmentsManagementView extends StatefulWidget {
  const EnvironmentsManagementView({super.key});

  @override
  State<EnvironmentsManagementView> createState() => _EnvironmentsManagementViewState();
}

class _EnvironmentsManagementViewState extends State<EnvironmentsManagementView> {
  bool _isGridView = true;
  String? _selectedEnvId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    final wsProvider = Provider.of<WorkspaceProvider>(context);
    final workspace = wsProvider.currentWorkspace;

    if (workspace == null) {
      return const Center(
        child: Text('Nenhum workspace ativo.'),
      );
    }

    final List<EnvironmentModel> environments = workspace.environments;
    final filteredEnvironments = environments.where((env) {
      return env.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // If selectedEnvId is not set, set it to the active environment or the first one
    if (_selectedEnvId == null && environments.isNotEmpty) {
      _selectedEnvId = workspace.selectedEnvironmentId ?? environments.first.id;
    }

    final selectedEnv = environments.firstWhere(
      (e) => e.id == _selectedEnvId,
      orElse: () => environments.isNotEmpty ? environments.first : EnvironmentModel(name: 'Default'),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _isGridView
            ? _buildGridView(context, wsProvider, workspace, filteredEnvironments)
            : _buildSplitView(context, wsProvider, workspace, selectedEnv),
      ),
    );
  }

  // --- GRID VIEW ---
  Widget _buildGridView(
    BuildContext context,
    WorkspaceProvider wsProvider,
    WorkspaceModel workspace,
    List<EnvironmentModel> environments,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardBgColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Padding(
      key: const ValueKey('GridView'),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Environments',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${environments.length} Total',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage keys, secrets, and configurations for different runtime targets.',
                    style: TextStyle(fontSize: 14, color: secondaryTextColor),
                  ),
                ],
              ),
              // View Toggle
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isGridView = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.slate800 : AppColors.slate200,
                  foregroundColor: textColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.list_alt_rounded, size: 18),
                label: const Text('Split View', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search and Actions
          Row(
            children: [
              // Search input
              SizedBox(
                width: 320,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontSize: 13, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Filter environments...',
                    hintStyle: TextStyle(fontSize: 13, color: secondaryTextColor.withValues(alpha: 0.7)),
                    prefixIcon: Icon(Icons.search_rounded, color: secondaryTextColor, size: 18),
                    filled: true,
                    fillColor: isDark ? AppColors.slate800.withValues(alpha: 0.5) : AppColors.slate100,
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateEnvironmentDialog(context, wsProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Environment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cards Grid
          Expanded(
            child: GridView.builder(
              itemCount: environments.length + 1,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.6,
              ),
              itemBuilder: (context, index) {
                if (index == environments.length) {
                  // Add card
                  return _buildAddCard(context, wsProvider, borderColor, secondaryTextColor);
                }

                final env = environments[index];
                return _buildEnvCard(context, wsProvider, workspace, env, cardBgColor, borderColor, textColor, secondaryTextColor);
              },
            ),
          ),
          const SizedBox(height: 24),

          // Bottom variables overview table
          _buildVariablesOverviewTable(context, wsProvider, workspace, textColor, secondaryTextColor, borderColor),
        ],
      ),
    );
  }

  Widget _buildEnvCard(
    BuildContext context,
    WorkspaceProvider wsProvider,
    WorkspaceModel workspace,
    EnvironmentModel env,
    Color cardBgColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final isActive = workspace.selectedEnvironmentId == env.id;
    final varCount = env.variables.length;

    final accentColor = WorkspaceProvider.iconColors[env.icon] ?? AppColors.primary;
    final iconData = WorkspaceProvider.icons[env.icon] ?? Icons.language_rounded;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedEnvId = env.id;
            _isGridView = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? accentColor : borderColor,
              width: isActive ? 2.0 : 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(iconData, color: accentColor, size: 18),
                  ),
                  const Spacer(),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.star_outline_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                      tooltip: 'Set Active',
                      onPressed: () => wsProvider.selectEnvironment(env.id),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                env.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  env.description.isNotEmpty ? env.description : 'No description provided.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$varCount variables',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: secondaryTextColor.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddCard(
    BuildContext context,
    WorkspaceProvider wsProvider,
    Color borderColor,
    Color secondaryTextColor,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showCreateEnvironmentDialog(context, wsProvider),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                size: 28,
                color: secondaryTextColor.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 10),
              Text(
                'New Environment',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVariablesOverviewTable(
    BuildContext context,
    WorkspaceProvider wsProvider,
    WorkspaceModel workspace,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    final environments = workspace.environments;
    final List<Map<String, dynamic>> allVars = [];

    for (var env in environments) {
      env.variables.forEach((key, secretVal) {
        allVars.add({
          'key': key,
          'env': env.name,
          'envId': env.id,
          'value': secretVal.value,
          'isSecret': secretVal.isSecret,
        });
      });
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Variables Overview',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          if (allVars.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No variables defined in any environment.',
                  style: TextStyle(fontSize: 13, color: secondaryTextColor),
                ),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(3),
                3: IntrinsicColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // Header Row
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  children: [
                    _buildTableHeaderCell('Variable Name', secondaryTextColor),
                    _buildTableHeaderCell('Environment', secondaryTextColor),
                    _buildTableHeaderCell('Value', secondaryTextColor),
                    _buildTableHeaderCell('Action', secondaryTextColor),
                  ],
                ),
                // Body Rows
                ...allVars.map((variable) {
                  final String key = variable['key'];
                  final String envName = variable['env'];
                  final String envId = variable['envId'];
                  final String value = variable['value'];
                  final bool isSecret = variable['isSecret'];

                  return TableRow(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.5))),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          key,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                        ),
                      ),
                      Text(
                        envName,
                        style: TextStyle(fontSize: 12, color: secondaryTextColor),
                      ),
                      Text(
                        isSecret ? '••••••••' : value,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'JetBrains Mono',
                          color: isSecret ? secondaryTextColor.withValues(alpha: 0.6) : textColor,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedEnvId = envId;
                              _isGridView = false;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 12),
                          label: const Text('Edit', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // --- SPLIT VIEW ---
  Widget _buildSplitView(
    BuildContext context,
    WorkspaceProvider wsProvider,
    WorkspaceModel workspace,
    EnvironmentModel selectedEnv,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final sidebarBg = isDark ? AppColors.surfaceDark : Colors.white;

    return Row(
      key: const ValueKey('SplitView'),
      children: [
        // Left Side - Environment List
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: sidebarBg,
            border: Border(right: BorderSide(color: borderColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Environments',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                      tooltip: 'Add Environment',
                      onPressed: () => _showCreateEnvironmentDialog(context, wsProvider),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: workspace.environments.length,
                  itemBuilder: (context, index) {
                    final env = workspace.environments[index];
                    final isCurrentSelected = env.id == selectedEnv.id;

                    final iconData = WorkspaceProvider.icons[env.icon] ?? Icons.language_rounded;
                    final envColor = WorkspaceProvider.iconColors[env.icon] ?? AppColors.primary;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedEnvId = env.id;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isCurrentSelected
                                ? const Color(0xFF10B981).withValues(alpha: 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isCurrentSelected
                                ? Border.all(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                iconData,
                                color: isCurrentSelected ? const Color(0xFF10B981) : envColor.withValues(alpha: 0.7),
                                size: 16,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  env.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isCurrentSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isCurrentSelected ? const Color(0xFF10B981) : (isDark ? Colors.white70 : AppColors.textSecondaryLight),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Right Side - Variable Editor
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                WorkspaceProvider.icons[selectedEnv.icon] ?? Icons.language_rounded,
                                color: WorkspaceProvider.iconColors[selectedEnv.icon] ?? AppColors.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                selectedEnv.name,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                splashRadius: 20,
                                tooltip: 'Edit Name/Description',
                                onPressed: () => _showEditEnvironmentDialog(context, wsProvider, selectedEnv),
                              ),
                              const SizedBox(width: 12),
                              if (workspace.selectedEnvironmentId == selectedEnv.id)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              else
                                ElevatedButton(
                                  onPressed: () => wsProvider.selectEnvironment(selectedEnv.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? AppColors.slate800 : AppColors.slate200,
                                    foregroundColor: textColor,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  child: const Text('Set Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedEnv.description.isNotEmpty ? selectedEnv.description : 'No description provided.',
                            style: TextStyle(fontSize: 13, color: secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        // Delete environment (disable if only 1 env left)
                        if (workspace.environments.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                            tooltip: 'Delete Environment',
                            splashRadius: 22,
                            onPressed: () {
                              _confirmDeleteEnvironment(context, wsProvider, selectedEnv);
                            },
                          ),
                        const SizedBox(width: 8),
                        // View Toggle
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isGridView = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.slate800 : AppColors.slate200,
                            foregroundColor: textColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.grid_view_rounded, size: 18),
                          label: const Text('Grid View', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Variable Editor Table
              Expanded(
                child: SingleChildScrollView(
                  child: _VariableListEditor(
                    key: ValueKey(selectedEnv.id),
                    envId: selectedEnv.id,
                    variables: selectedEnv.variables,
                    wsProvider: wsProvider,
                    borderColor: borderColor,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- DIALOGS ---
  void _showCreateEnvironmentDialog(BuildContext context, WorkspaceProvider wsProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08);
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final inputBgColor = isDark ? const Color(0x801E293B) : const Color(0xFFF1F5F9);

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedIcon = 'language';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
            side: BorderSide(color: borderColor),
          ),
          elevation: 24,
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Create Environment',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: labelColor, size: 20),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Environment Name',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      style: TextStyle(fontSize: 14, color: textColor),
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'e.g. Production, Staging, Development...',
                        hintStyle: TextStyle(fontSize: 14, color: labelColor.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: inputBgColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Environment name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Description',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descController,
                      maxLines: 2,
                      style: TextStyle(fontSize: 14, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Briefly describe this environment...',
                        hintStyle: TextStyle(fontSize: 14, color: labelColor.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: inputBgColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Choose Icon',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final key in const [
                          'language', 'bolt', 'api', 'shield', 'package', 'bar_chart',
                          'search_activity', 'code', 'cloud', 'database', 'hub',
                          'terminal', 'dns', 'deployed_code', 'security', 'lock'
                        ])
                          InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedIcon = key;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: selectedIcon == key
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedIcon == key ? AppColors.primary : borderColor,
                                  width: selectedIcon == key ? 2.0 : 1.0,
                                ),
                              ),
                              child: Icon(
                                WorkspaceProvider.icons[key] ?? Icons.language_rounded,
                                color: WorkspaceProvider.iconColors[key] ?? AppColors.primary,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: TextStyle(color: labelColor, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final name = nameController.text.trim();
                              final desc = descController.text.trim();
                              await wsProvider.addEnvironmentWithNameAndDescription(name, desc, selectedIcon);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditEnvironmentDialog(BuildContext context, WorkspaceProvider wsProvider, EnvironmentModel env) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08);
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final inputBgColor = isDark ? const Color(0x801E293B) : const Color(0xFFF1F5F9);

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: env.name);
    final descController = TextEditingController(text: env.description);
    String selectedIcon = env.icon;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
            side: BorderSide(color: borderColor),
          ),
          elevation: 24,
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Environment',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: labelColor, size: 20),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Environment Name',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      style: TextStyle(fontSize: 14, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'e.g. Production, Staging, Development...',
                        hintStyle: TextStyle(fontSize: 14, color: labelColor.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: inputBgColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Environment name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Description',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descController,
                      maxLines: 2,
                      style: TextStyle(fontSize: 14, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Briefly describe this environment...',
                        hintStyle: TextStyle(fontSize: 14, color: labelColor.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: inputBgColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Choose Icon',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final key in const [
                          'language', 'bolt', 'api', 'shield', 'package', 'bar_chart',
                          'search_activity', 'code', 'cloud', 'database', 'hub',
                          'terminal', 'dns', 'deployed_code', 'security', 'lock'
                        ])
                          InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedIcon = key;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: selectedIcon == key
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedIcon == key ? AppColors.primary : borderColor,
                                  width: selectedIcon == key ? 2.0 : 1.0,
                                ),
                              ),
                              child: Icon(
                                WorkspaceProvider.icons[key] ?? Icons.language_rounded,
                                color: WorkspaceProvider.iconColors[key] ?? AppColors.primary,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: TextStyle(color: labelColor, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final name = nameController.text.trim();
                              final desc = descController.text.trim();
                              await wsProvider.updateEnvironmentDetails(env.id, name, desc, selectedIcon);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteEnvironment(BuildContext context, WorkspaceProvider wsProvider, EnvironmentModel env) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF111827) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textLight;
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text('Delete Environment', style: TextStyle(color: textColor)),
        content: Text(
          'Are you sure you want to delete the "${env.name}" environment? This will permanently delete all its variables.',
          style: TextStyle(color: labelColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: labelColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              await wsProvider.removeEnvironment(env.id);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// --- VARIABLE LIST EDITOR ---
class _VariableListEditor extends StatefulWidget {
  final String envId;
  final Map<String, WorkspaceSecretKey> variables;
  final WorkspaceProvider wsProvider;
  final Color borderColor;
  final Color textColor;
  final Color secondaryTextColor;

  const _VariableListEditor({
    super.key,
    required this.envId,
    required this.variables,
    required this.wsProvider,
    required this.borderColor,
    required this.textColor,
    required this.secondaryTextColor,
  });

  @override
  State<_VariableListEditor> createState() => _VariableListEditorState();
}

class _VariableListEditorState extends State<_VariableListEditor> {
  // Keeping track of list indices for keys editing
  List<String> _keysList = [];

  @override
  void initState() {
    super.initState();
    _keysList = widget.variables.keys.toList();
  }

  void _addEmptyVariable() {
    // Generate a unique temporary key name
    int counter = widget.variables.length + 1;
    String newKey = 'VARIABLE_$counter';
    while (widget.variables.containsKey(newKey)) {
      counter++;
      newKey = 'VARIABLE_$counter';
    }

    final newSecret = WorkspaceSecretKey(value: '', isSecret: false);
    widget.wsProvider.addOrUpdateVariable(widget.envId, newKey, newKey, newSecret);
    setState(() {
      _keysList.add(newKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tableBg = isDark
        ? AppColors.slate900.withValues(alpha: 0.3)
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Container(
            decoration: BoxDecoration(
              color: tableBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.slate800.withValues(alpha: 0.3)
                        : AppColors.slate50,
                    border: Border(bottom: BorderSide(color: widget.borderColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'VARIABLE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: widget.secondaryTextColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Text(
                          'VALUE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: widget.secondaryTextColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'TYPE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: widget.secondaryTextColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'ACTIONS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: widget.secondaryTextColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Rows
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: _keysList.length + 1,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: widget.borderColor.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    if (index == _keysList.length) {
                      // Add Variable button row
                      return InkWell(
                        onTap: _addEmptyVariable,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_circle_outline_rounded,
                                size: 18,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add New Variable',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final key = _keysList[index];
                    final secretKey = widget.variables[key];
                    if (secretKey == null) return const SizedBox();

                    return _VariableRowWidget(
                      key: ValueKey('${widget.envId}_row_$key'),
                      envId: widget.envId,
                      varKey: key,
                      secretKey: secretKey,
                      wsProvider: widget.wsProvider,
                      borderColor: widget.borderColor,
                      textColor: widget.textColor,
                      secondaryTextColor: widget.secondaryTextColor,
                      onKeyRenamed: (oldKey, newKey) {
                        setState(() {
                          final idx = _keysList.indexOf(oldKey);
                          if (idx != -1) {
                            _keysList[idx] = newKey;
                          }
                        });
                      },
                      onDeleted: () {
                        widget.wsProvider.removeVariable(widget.envId, key);
                        setState(() {
                          _keysList.remove(key);
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VariableRowWidget extends StatefulWidget {
  final String envId;
  final String varKey;
  final WorkspaceSecretKey secretKey;
  final WorkspaceProvider wsProvider;
  final Color borderColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Function(String oldKey, String newKey) onKeyRenamed;
  final VoidCallback onDeleted;

  const _VariableRowWidget({
    super.key,
    required this.envId,
    required this.varKey,
    required this.secretKey,
    required this.wsProvider,
    required this.borderColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.onKeyRenamed,
    required this.onDeleted,
  });

  @override
  State<_VariableRowWidget> createState() => _VariableRowWidgetState();
}

class _VariableRowWidgetState extends State<_VariableRowWidget> {
  late TextEditingController _keyController;
  late TextEditingController _valueController;
  late FocusNode _keyFocusNode;
  late FocusNode _valueFocusNode;
  late bool _isSecret;
  bool _obscureText = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.varKey);
    _valueController = TextEditingController(text: widget.secretKey.value);
    _keyFocusNode = FocusNode();
    _valueFocusNode = FocusNode();
    _isSecret = widget.secretKey.isSecret;

    _keyFocusNode.addListener(_onFocusLoss);
    _valueFocusNode.addListener(_onFocusLoss);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _keyFocusNode.removeListener(_onFocusLoss);
    _valueFocusNode.removeListener(_onFocusLoss);
    _keyController.dispose();
    _valueController.dispose();
    _keyFocusNode.dispose();
    _valueFocusNode.dispose();
    super.dispose();
  }

  void _onFocusLoss() {
    if (!_keyFocusNode.hasFocus && !_valueFocusNode.hasFocus) {
      _saveChangesImmediately();
    }
  }

  void _onChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _saveChangesImmediately();
    });
  }

  void _saveChangesImmediately() {
    final oldKey = widget.varKey;
    final newKey = _keyController.text.trim();
    final newValue = _valueController.text;

    if (newKey.isEmpty) return; // Don't save empty keys

    final updatedSecret = WorkspaceSecretKey(value: newValue, isSecret: _isSecret);
    widget.wsProvider.addOrUpdateVariable(widget.envId, oldKey, newKey, updatedSecret);

    if (oldKey != newKey) {
      widget.onKeyRenamed(oldKey, newKey);
    }
  }

  Widget _buildTypeBadge(bool isSecret) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isSecret) {
      final orangeColor = isDark ? Colors.orangeAccent : Colors.orange[800]!;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: orangeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: orangeColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 12, color: orangeColor),
            const SizedBox(width: 4),
            Text(
              'Secret',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: orangeColor,
              ),
            ),
          ],
        ),
      );
    } else {
      final grayColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.slate800 : AppColors.slate100).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.text_fields_rounded, size: 12, color: grayColor),
            const SizedBox(width: 4),
            Text(
              'Text',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: grayColor,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Row(
        children: [
          // Key field
          Expanded(
            flex: 4,
            child: TextFormField(
              controller: _keyController,
              focusNode: _keyFocusNode,
              onChanged: (_) => _onChanged(),
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'JetBrains Mono',
                color: Color(0xFF10B981),
              ),
              decoration: InputDecoration(
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                hintText: 'VARIABLE_NAME',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: widget.secondaryTextColor.withValues(alpha: 0.3),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Value field
          Expanded(
            flex: 5,
            child: TextFormField(
              controller: _valueController,
              focusNode: _valueFocusNode,
              obscureText: _isSecret && _obscureText,
              onChanged: (_) => _onChanged(),
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'JetBrains Mono',
                color: widget.textColor,
              ),
              decoration: InputDecoration(
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                hintText: 'value',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: widget.secondaryTextColor.withValues(alpha: 0.3),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                suffixIcon: _isSecret
                    ? IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 16,
                          color: widget.secondaryTextColor.withValues(alpha: 0.6),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                        splashRadius: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Type selector (Text / Secret)
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Theme(
                data: Theme.of(context).copyWith(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                ),
                child: PopupMenuButton<bool>(
                  initialValue: _isSecret,
                  onSelected: (bool newValue) {
                    setState(() {
                      _isSecret = newValue;
                    });
                    _saveChangesImmediately();
                  },
                  tooltip: 'Change Type',
                  offset: const Offset(0, 30),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  itemBuilder: (context) => [
                    const PopupMenuItem<bool>(
                      value: false,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.text_fields_rounded, size: 14, color: AppColors.textSecondaryLight),
                          SizedBox(width: 8),
                          Text('Text', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<bool>(
                      value: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 14, color: Colors.orangeAccent),
                          SizedBox(width: 8),
                          Text('Secret', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: _buildTypeBadge(_isSecret),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Delete button
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: widget.secondaryTextColor),
                onPressed: widget.onDeleted,
                tooltip: 'Delete row',
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
