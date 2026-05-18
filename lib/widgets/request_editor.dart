import 'package:flutter/material.dart';
import 'package:gk_http_client/models/http_method.dart';
import 'package:gk_http_client/models/http_request.dart';
import 'package:gk_http_client/providers/request_provider.dart';
import 'package:gk_http_client/theme/app_colors.dart';
import 'package:gk_http_client/theme/app_theme.dart';
import 'package:provider/provider.dart';

class RequestEditor extends StatefulWidget {
  final HttpRequest request;

  const RequestEditor({super.key, required this.request});

  @override
  State<RequestEditor> createState() => _RequestEditorState();
}

class _RequestEditorState extends State<RequestEditor>
    with SingleTickerProviderStateMixin {
  late TextEditingController _urlController;
  late TabController _tabController;
  late HttpMethod _method;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.request.url);
    _method = widget.request.method;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didUpdateWidget(RequestEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.id != widget.request.id) {
      _urlController.text = widget.request.url;
      _method = widget.request.method;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSave() {
    final updatedRequest = widget.request.copyWith(
      url: _urlController.text,
      method: _method,
    );
    Provider.of<RequestProvider>(
      context,
      listen: false,
    ).updateSelectedRequest(updatedRequest);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Action Bar: [URL BAR] [SEND] [SAVE]
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Row(
              children: [
                // URL Bar (Expanded)
                Expanded(
                  child: Container(
                    height: 46, // Increased to match professional desktop feel
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Method Selector (Purely transparent)
                        Container(
                          width: 90,
                          padding: const EdgeInsets.only(left: 12),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<HttpMethod>(
                              value: _method,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                              dropdownColor: isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surfaceLight,
                              items: HttpMethod.values.map((method) {
                                return DropdownMenuItem(
                                  value: method,
                                  child: Text(
                                    method.value,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _getMethodColor(method),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _method = value);
                                  _onSave();
                                }
                              },
                            ),
                          ),
                        ),

                        VerticalDivider(
                          width: 24,
                          thickness: 1,
                          indent: 12,
                          endIndent: 12,
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),

                        // URL Input
                        Expanded(
                          child: TextField(
                            controller: _urlController,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textDark
                                  : AppColors.textLight,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'https://api.example.com/v1/resource',
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                            ),
                            onChanged: (_) => _onSave(),
                          ),
                        ),

                        // Favorite Icon
                        IconButton(
                          onPressed: () {
                            setState(() => _isFavorite = !_isFavorite);
                          },
                          icon: Icon(
                            _isFavorite
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 20,
                            color: _isFavorite
                                ? Colors.amber
                                : AppColors.slate400,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Send Button [send >]
                ElevatedButton(
                  onPressed: () {
                    // TODO: Execute request
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    minimumSize: const Size(0, 54), // Height matched to URL bar
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Send',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.send_rounded, size: 16),
                    ],
                  ),
                ),

                const SizedBox(width: 4),

                // Save Button (TRANSPARENT, NO BORDER)
                IconButton(
                  onPressed: _onSave,
                  icon: Icon(
                    Icons.save_outlined,
                    size: 26,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  tooltip: 'Save',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(46, 46), // Size matched to others
                  ),
                ),
              ],
            ),
          ),

          // Configuration Tabs (Offset to align with Method text)
          Container(
            padding: const EdgeInsets.only(left: 12),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.slate500,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: const [
                Tab(text: 'Query'), // Params
                Tab(text: 'Headers'),
                Tab(text: 'Auth'),
                Tab(text: 'Body'),
              ],
            ),
          ),

          const Divider(height: 1),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildParamsTab(),
                _buildHeadersTab(),
                _buildAuthTab(),
                _buildBodyTab(),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildParamsTab() {
    return const Center(child: Text('Query Parameters Editor'));
  }

  Widget _buildHeadersTab() {
    return const Center(child: Text('Headers Editor'));
  }

  Widget _buildBodyTab() {
    return const Center(child: Text('Body Editor (JSON, Text, etc.)'));
  }

  Widget _buildAuthTab() {
    return const Center(
      child: Text('Authentication Editor (Basic, Bearer, etc.)'),
    );
  }
}
