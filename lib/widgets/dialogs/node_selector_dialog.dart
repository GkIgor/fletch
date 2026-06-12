import 'package:flutter/material.dart';
import '../../models/visual_script.dart';
import '../../theme/app_colors.dart';

class NodeSelectorItem {
  final VisualStepType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const NodeSelectorItem({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class NodeSelectorDialog extends StatefulWidget {
  const NodeSelectorDialog({super.key});

  @override
  State<NodeSelectorDialog> createState() => _NodeSelectorDialogState();
}

class _NodeSelectorDialogState extends State<NodeSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'HTTP & Logic',
      'items': [
        NodeSelectorItem(
          type: VisualStepType.sendRequest,
          title: 'HTTP Request',
          description: 'Send HTTP requests (GET, POST, PUT, DELETE) with custom headers & body.',
          icon: Icons.http_outlined,
          color: Colors.blue,
        ),
        NodeSelectorItem(
          type: VisualStepType.ifStep,
          title: 'IF Condition',
          description: 'Branch the execution flow based on boolean expressions.',
          icon: Icons.help_outline_rounded,
          color: Colors.red.shade400,
        ),
        NodeSelectorItem(
          type: VisualStepType.switchStep,
          title: 'Switch Branch',
          description: 'Route the flow into multiple branches based on a variable value.',
          icon: Icons.call_split_rounded,
          color: Colors.indigo,
        ),
        NodeSelectorItem(
          type: VisualStepType.end,
          title: 'End',
          description: 'Successfully terminate the flowchart execution flow.',
          icon: Icons.stop_circle_outlined,
          color: Colors.green.shade600,
        ),
        NodeSelectorItem(
          type: VisualStepType.fail,
          title: 'Fail',
          description: 'Explicitly fail the script execution with error.',
          icon: Icons.cancel_outlined,
          color: Colors.red.shade600,
        ),
      ],
    },
    {
      'name': 'Variables & Data',
      'items': [
        NodeSelectorItem(
          type: VisualStepType.setVariable,
          title: 'Set/Edit Fields',
          description: 'Set static values or assign variables during execution.',
          icon: Icons.account_tree_outlined,
          color: AppColors.primary,
        ),
        NodeSelectorItem(
          type: VisualStepType.merge,
          title: 'Merge Variables',
          description: 'Merge multiple data maps/sources into a single variable.',
          icon: Icons.merge_type_rounded,
          color: Colors.amber.shade700,
        ),
        NodeSelectorItem(
          type: VisualStepType.jsonPathStep,
          title: 'JSON Path',
          description: 'Query and extract specific fields from JSON responses.',
          icon: Icons.troubleshoot_rounded,
          color: Colors.purple.shade700,
        ),
        NodeSelectorItem(
          type: VisualStepType.headerBuilder,
          title: 'Header Builder',
          description: 'Construct complex request header structures.',
          icon: Icons.badge_outlined,
          color: Colors.pink.shade700,
        ),
      ],
    },
    {
      'name': 'Lists & Collections',
      'items': [
        NodeSelectorItem(
          type: VisualStepType.splitOut,
          title: 'Split Out (Loop)',
          description: 'Iterate over list arrays to run sub-steps in sequence/parallel.',
          icon: Icons.repeat_rounded,
          color: Colors.purple,
        ),
        NodeSelectorItem(
          type: VisualStepType.aggregate,
          title: 'Aggregate List',
          description: 'Accumulate individual items back into a single array.',
          icon: Icons.widgets_outlined,
          color: Colors.cyan,
        ),
        NodeSelectorItem(
          type: VisualStepType.sort,
          title: 'Sort List',
          description: 'Sort list elements using dynamic keys.',
          icon: Icons.sort_rounded,
          color: Colors.blueGrey,
        ),
        NodeSelectorItem(
          type: VisualStepType.limit,
          title: 'Limit List',
          description: 'Truncate lists using limit and offset boundary parameters.',
          icon: Icons.filter_list_rounded,
          color: Colors.brown,
        ),
        NodeSelectorItem(
          type: VisualStepType.removeDuplicates,
          title: 'Remove Duplicates',
          description: 'Filter unique elements in list collections.',
          icon: Icons.copy_all_outlined,
          color: Colors.deepOrange,
        ),
      ],
    },
    {
      'name': 'Data Conversion',
      'items': [
        NodeSelectorItem(
          type: VisualStepType.jsonConvert,
          title: 'JSON Convert',
          description: 'Serialize maps to JSON strings or deserialize them back.',
          icon: Icons.settings_ethernet_rounded,
          color: Colors.green.shade700,
        ),
        NodeSelectorItem(
          type: VisualStepType.xmlConvert,
          title: 'XML Convert',
          description: 'Convert XML payloads into readable JSON objects.',
          icon: Icons.code_rounded,
          color: Colors.orange.shade800,
        ),
        NodeSelectorItem(
          type: VisualStepType.htmlConvert,
          title: 'HTML Extract',
          description: 'Extract elements or text from HTML using CSS selectors.',
          icon: Icons.html_rounded,
          color: Colors.teal.shade800,
        ),
        NodeSelectorItem(
          type: VisualStepType.markdownConvert,
          title: 'Markdown Convert',
          description: 'Compile markdown notation directly into HTML content.',
          icon: Icons.text_snippet_outlined,
          color: Colors.indigo.shade800,
        ),
      ],
    },
    {
      'name': 'Utilities',
      'items': [
        NodeSelectorItem(
          type: VisualStepType.assertValue,
          title: 'Assert Value',
          description: 'Perform unit-test assertions or validate runtime values.',
          icon: Icons.fact_check_outlined,
          color: Colors.orange,
        ),
        NodeSelectorItem(
          type: VisualStepType.delay,
          title: 'Delay Timer',
          description: 'Pause execution pipeline for a specified time interval.',
          icon: Icons.hourglass_top_outlined,
          color: Colors.teal,
        ),
        NodeSelectorItem(
          type: VisualStepType.dateTime,
          title: 'Date & Time',
          description: 'Format dates or output current timestamps in multiple formats.',
          icon: Icons.date_range_outlined,
          color: Colors.pink,
        ),
        NodeSelectorItem(
          type: VisualStepType.crypto,
          title: 'Crypto Hash',
          description: 'Encrypt payloads using SHA-256 or MD5 checksums.',
          icon: Icons.lock_outline_rounded,
          color: Colors.lime.shade800,
        ),
      ],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredCategories() {
    if (_searchQuery.trim().isEmpty) return _categories;
    final List<Map<String, dynamic>> result = [];

    for (var cat in _categories) {
      final items = cat['items'] as List<NodeSelectorItem>;
      final filteredItems = items.where((item) {
        return item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();

      if (filteredItems.isNotEmpty) {
        result.add({
          'name': cat['name'],
          'items': filteredItems,
        });
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _getFilteredCategories();

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 550,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.widgets_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Node Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose a node to insert into your script flow',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.slate400 : AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search Input
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search node types...',
                hintStyle: TextStyle(color: isDark ? AppColors.slate500 : AppColors.slate400),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
            const SizedBox(height: 16),
            // Categories & Items list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 36, color: isDark ? AppColors.slate500 : AppColors.slate400),
                          const SizedBox(height: 8),
                          const Text(
                            'No node types match your search.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, catIdx) {
                        final category = filtered[catIdx];
                        final catItems = category['items'] as List<NodeSelectorItem>;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                              child: Text(
                                category['name'].toString().toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: AppColors.primary.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                            ...catItems.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: InkWell(
                                  onTap: () => Navigator.pop(context, item.type),
                                  borderRadius: BorderRadius.circular(8),
                                  hoverColor: isDark
                                      ? const Color(0xFF334155).withValues(alpha: 0.4)
                                      : const Color(0xFFF1F5F9),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF334155).withValues(alpha: 0.3)
                                            : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: item.color.withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(item.icon, size: 18, color: item.color),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.description,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                          ],
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
