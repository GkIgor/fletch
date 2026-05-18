import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gk_http_client/models/http_response.dart';
import 'package:gk_http_client/theme/app_colors.dart';
import 'package:gk_http_client/theme/app_theme.dart';

class ResponseViewer extends StatefulWidget {
  final HttpResponse response;

  const ResponseViewer({super.key, required this.response});

  @override
  State<ResponseViewer> createState() => _ResponseViewerState();
}

class _ResponseViewerState extends State<ResponseViewer> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Info Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                _buildStatusBadge(),
                const SizedBox(width: 24),
                _buildInfoItem('Time', widget.response.formattedTime),
                const SizedBox(width: 24),
                _buildInfoItem('Size', widget.response.formattedSize),
              ],
            ),
          ),

          // Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.slate500,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Response Body'),
                Tab(text: 'Headers'),
              ],
            ),
          ),

          const Divider(),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBodyContent(isDark),
                _buildHeadersContent(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color = AppColors.statusInfo;
    if (widget.response.isSuccess) color = AppColors.statusSuccess;
    if (widget.response.isClientError || widget.response.isServerError) color = AppColors.statusError;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.response.statusCode} ${widget.response.statusMessage}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppColors.slate500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBodyContent(bool isDark) {
    String formattedBody = '';
    try {
      if (widget.response.body is Map || widget.response.body is List) {
        formattedBody = const JsonEncoder.withIndent('  ').convert(widget.response.body);
      } else {
        formattedBody = widget.response.body.toString();
      }
    } catch (e) {
      formattedBody = widget.response.body.toString();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: SingleChildScrollView(
        child: SelectableText(
          formattedBody,
          style: AppTheme.codeStyle(
            fontSize: 13,
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ),
      ),
    );
  }

  Widget _buildHeadersContent(bool isDark) {
    final headers = widget.response.headers;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: headers.length,
      itemBuilder: (context, index) {
        final key = headers.keys.elementAt(index);
        final value = headers[key];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 180,
                child: Text(
                  key,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              Expanded(
                child: SelectableText(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
