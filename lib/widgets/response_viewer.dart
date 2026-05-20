import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gk_http_client/models/http_response.dart';
import 'package:gk_http_client/theme/app_colors.dart';
import 'package:gk_http_client/theme/app_theme.dart';
import 'package:gk_http_client/widgets/code_highlight_controller.dart';
import 'package:gk_http_client/widgets/body_editor.dart'; // Para reutilizar o BodyType enum
import 'package:file_picker/file_picker.dart' as picker;
import 'package:path/path.dart' as p;

class ResponseViewer extends StatefulWidget {
  final HttpResponse response;

  const ResponseViewer({super.key, required this.response});

  @override
  State<ResponseViewer> createState() => _ResponseViewerState();
}

class _ResponseViewerState extends State<ResponseViewer> {
  late BodyType _selectedFormat;
  late CodeHighlightController _textController;
  late ScrollController _textScrollController;
  late ScrollController _lineNumbersScrollController;

  @override
  void initState() {
    super.initState();
    _detectContentType();
    _initControllers();
  }

  @override
  void didUpdateWidget(ResponseViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.response != widget.response) {
      _detectContentType();
      _textController.language = _getLanguageFromType(_selectedFormat);
      _textController.text = _getFormattedBody(_selectedFormat);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _textScrollController.dispose();
    _lineNumbersScrollController.dispose();
    super.dispose();
  }

  void _detectContentType() {
    final contentType = _getHeaderValue('content-type') ?? _getHeaderValue('Content-Type') ?? '';
    if (contentType.toLowerCase().contains('json')) {
      _selectedFormat = BodyType.json;
    } else if (contentType.toLowerCase().contains('xml')) {
      _selectedFormat = BodyType.xml;
    } else if (contentType.toLowerCase().contains('octet-stream') || contentType.toLowerCase().contains('binary')) {
      _selectedFormat = BodyType.binary;
    } else {
      _selectedFormat = BodyType.json; // Default
    }
  }

  String? _getHeaderValue(String name) {
    final val = widget.response.headers[name] ?? widget.response.headers[name.toLowerCase()];
    if (val is List) {
      return val.isEmpty ? null : val.first.toString();
    }
    return val?.toString();
  }

  void _initControllers() {
    _textController = CodeHighlightController(
      text: _getFormattedBody(_selectedFormat),
      language: _getLanguageFromType(_selectedFormat),
      isDark: true,
    );
    _textScrollController = ScrollController();
    _lineNumbersScrollController = ScrollController();

    _textScrollController.addListener(() {
      if (_lineNumbersScrollController.hasClients) {
        _lineNumbersScrollController.jumpTo(_textScrollController.offset);
      }
    });
  }

  String _getLanguageFromType(BodyType type) {
    if (type == BodyType.json) return 'json';
    if (type == BodyType.xml) return 'xml';
    return 'none';
  }

  String _getFormattedBody(BodyType format) {
    if (widget.response.body == null) return '';
    if (format == BodyType.json) {
      try {
        if (widget.response.body is Map || widget.response.body is List) {
          return const JsonEncoder.withIndent('  ').convert(widget.response.body);
        } else if (widget.response.body is String) {
          final decoded = jsonDecode(widget.response.body);
          return const JsonEncoder.withIndent('  ').convert(decoded);
        }
      } catch (_) {}
    }
    return widget.response.body.toString();
  }

  void _copyToClipboard() {
    final text = _getFormattedBody(_selectedFormat);
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied response body to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveResponseToFile() async {
    try {
      final text = _getFormattedBody(_selectedFormat);
      final extension = _selectedFormat == BodyType.json ? 'json' : (_selectedFormat == BodyType.xml ? 'xml' : 'txt');
      final result = await picker.FilePicker.platform.saveFile(
        dialogTitle: 'Save Response',
        fileName: 'response.$extension',
        type: picker.FileType.custom,
        allowedExtensions: [extension, 'txt'],
      );
      if (result != null) {
        final file = File(result);
        await file.writeAsString(text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Response saved to ${p.basename(result)}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save file: $e')),
        );
      }
    }
  }

  List<Map<String, String>> _parseCookies() {
    final cookieVal = widget.response.headers['set-cookie'] ?? widget.response.headers['Set-Cookie'];
    final List<String> rawCookies = [];
    if (cookieVal is List) {
      rawCookies.addAll(cookieVal.map((e) => e.toString()));
    } else if (cookieVal is String) {
      rawCookies.add(cookieVal);
    }

    final List<Map<String, String>> cookies = [];
    for (final raw in rawCookies) {
      final parts = raw.split(';');
      if (parts.isEmpty) continue;
      final mainPart = parts.first.trim();
      final eqIdx = mainPart.indexOf('=');
      if (eqIdx == -1) continue;
      final name = mainPart.substring(0, eqIdx);
      final value = mainPart.substring(eqIdx + 1);

      final Map<String, String> cookie = {
        'name': name,
        'value': value,
      };

      for (var i = 1; i < parts.length; i++) {
        final p = parts[i].trim();
        final eq = p.indexOf('=');
        if (eq == -1) {
          cookie[p.toLowerCase()] = 'true';
        } else {
          final k = p.substring(0, eq).toLowerCase().trim();
          final v = p.substring(eq + 1).trim();
          cookie[k] = v;
        }
      }
      cookies.add(cookie);
    }
    return cookies;
  }

  void _showHeadersDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: Text(
          'Response Headers',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 550,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.response.headers.length,
              itemBuilder: (context, index) {
                final key = widget.response.headers.keys.elementAt(index);
                final value = widget.response.headers[key];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: SelectableText(
                          key,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: SelectableText(
                          value.toString(),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCookiesDialog(BuildContext context) {
    final cookies = _parseCookies();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: Text(
          'Response Cookies',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: cookies.isEmpty
            ? SizedBox(
                width: 300,
                height: 100,
                child: Center(
                  child: Text(
                    'No cookies found in response.',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              )
            : SizedBox(
                width: 500,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: cookies.length,
                    itemBuilder: (context, index) {
                      final c = cookies[index];
                      return Card(
                        color: isDark ? AppColors.backgroundDark : AppColors.slate100,
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    c['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const Text(' = '),
                                  Expanded(
                                    child: SelectableText(
                                      c['value'] ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (c.containsKey('domain')) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Domain: ${c['domain']}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                                ),
                              ],
                              if (c.containsKey('path')) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Path: ${c['path']}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                                ),
                              ],
                              if (c.containsKey('expires')) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Expires: ${c['expires']}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _textController.isDark = isDark;
    _textController.language = _getLanguageFromType(_selectedFormat);

    final lineCount = _textController.text.split('\n').length;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      ),
      child: Column(
        children: [
          // 1. Info Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                _buildStatusBadge(),
                const SizedBox(width: 16),
                Text(
                  widget.response.formattedTime,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  widget.response.formattedSize,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copy Body',
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                IconButton(
                  onPressed: _saveResponseToFile,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  tooltip: 'Save Response Body',
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // 2. Tab selector (None, JSON, Form Data, XML, Binary)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                _buildTab('None', BodyType.none),
                _buildTab('JSON', BodyType.json),
                _buildTab('Form Data', BodyType.formData),
                _buildTab('XML', BodyType.xml),
                _buildTab('Binary', BodyType.binary),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // 3. Response Content Area (Editor styled with line numbers)
          Expanded(
            child: _buildContentArea(lineCount, borderColor, isDark),
          ),

          const Divider(height: 1, thickness: 1),

          // 4. Footer
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.3) : AppColors.slate50,
            child: Row(
              children: [
                // Content Type on left
                Text(
                  _getHeaderValue('content-type') ?? _getHeaderValue('Content-Type') ?? 'text/plain',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const Spacer(),
                // Headers & Cookies links on right
                TextButton(
                  onPressed: () => _showHeadersDialog(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Headers',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => _showCookiesDialog(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Cookies',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '${widget.response.statusCode} ${widget.response.statusMessage}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTab(String label, BodyType format) {
    final isActive = _selectedFormat == format;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFormat = format;
          _textController.language = _getLanguageFromType(format);
          _textController.text = _getFormattedBody(format);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? AppColors.primary : AppColors.slate500,
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(int lineCount, Color borderColor, bool isDark) {
    if (_selectedFormat == BodyType.none) {
      return Center(
        child: Text(
          'No Response Body',
          style: TextStyle(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            fontSize: 13,
          ),
        ),
      );
    }

    if (_selectedFormat == BodyType.binary) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file_rounded,
              size: 48,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Binary Response File',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.response.formattedSize,
              style: const TextStyle(fontSize: 12, color: AppColors.slate500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saveResponseToFile,
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Save File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // JSON, XML, or Form Data (displayed as Text with syntax highlight and line numbers)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Line Numbers
        Container(
          width: 40,
          padding: const EdgeInsets.only(top: 16),
          color: isDark ? AppColors.slate900 : AppColors.slate100,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: ListView.builder(
              controller: _lineNumbersScrollController,
              itemCount: lineCount,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => Container(
                height: 18,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(vertical: 0.7),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Separator border
        Container(
          width: 1,
          color: borderColor,
        ),

        // Text area
        Expanded(
          child: TextField(
            controller: _textController,
            scrollController: _textScrollController,
            maxLines: null,
            expands: true,
            readOnly: true,
            textAlignVertical: TextAlignVertical.top,
            style: AppTheme.codeStyle(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
        ),
      ],
    );
  }
}
