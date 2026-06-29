import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fletch/backend/requests/models/http_response.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:fletch/theme/app_theme.dart';
import 'package:fletch/widgets/code_highlight_controller.dart';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:path/path.dart' as p;

class ResponseViewer extends StatefulWidget {
  final HttpResponse response;

  const ResponseViewer({super.key, required this.response});

  @override
  State<ResponseViewer> createState() => _ResponseViewerState();
}

class _ResponseViewerState extends State<ResponseViewer> {
  late String _selectedTab;
  late CodeHighlightController _textController;
  late ScrollController _textScrollController;
  late ScrollController _lineNumbersScrollController;

  bool _isFormatting = false;
  bool _isLargePayload = false;
  String _htmlBody = '';

  bool _isOffloaded = false;
  bool _isLoadingOffloaded = false;
  dynamic _loadedBody;

  static const int kMaxRenderSize = 2 * 1024 * 1024; // 2MB
  static const int kTruncateSize = 100 * 1024; // 100KB

  @override
  void initState() {
    super.initState();
    _isOffloaded = widget.response.bodyFilePath != null;
    _detectContentType();
    _initControllers();
    _updateBodyText();
  }

  @override
  void didUpdateWidget(ResponseViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.response != widget.response) {
      _isOffloaded = widget.response.bodyFilePath != null;
      _loadedBody = null;
      _detectContentType();
      _textController.language = _getLanguageFromTab(_selectedTab);
      _updateBodyText();
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
      _selectedTab = 'JSON';
    } else if (contentType.toLowerCase().contains('html')) {
      _selectedTab = 'HTML';
    } else if (contentType.toLowerCase().contains('xml')) {
      _selectedTab = 'XML';
    } else if (contentType.toLowerCase().contains('octet-stream') || contentType.toLowerCase().contains('binary')) {
      _selectedTab = 'Binary';
    } else {
      _selectedTab = 'JSON'; // Default fallback
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
      text: '',
      language: _getLanguageFromTab(_selectedTab),
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

  String _getLanguageFromTab(String tab) {
    if (tab == 'JSON') return 'json';
    if (tab == 'XML' || tab == 'HTML') return 'xml'; // HTML highlighting is compatible with xml
    return 'none';
  }

  Future<void> _updateBodyText() async {
    final body = _isOffloaded ? _loadedBody : widget.response.body;
    if (body == null) {
      _textController.text = '';
      _htmlBody = '';
      _isLargePayload = false;
      if (mounted) setState(() {});
      return;
    }

    final rawSize = widget.response.contentLength > 0 
        ? widget.response.contentLength 
        : body.toString().length;

    if (rawSize > kMaxRenderSize) {
      _isLargePayload = true;
      _textController.language = 'none';

      final rawStr = body.toString();
      final truncatedStr = rawStr.length > kTruncateSize 
          ? rawStr.substring(0, kTruncateSize) 
          : rawStr;

      _textController.text = '$truncatedStr\n\n... [TRUNCATED FOR PERFORMANCE]';
      _htmlBody = '<html><body><h3>HTML Truncated</h3><p>Response is too large (>2MB). Formatting disabled for performance.</p></body></html>';
      if (mounted) setState(() {});
      return;
    }

    _isLargePayload = false;

    if (_selectedTab == 'JSON') {
      if (mounted) {
        setState(() {
          _isFormatting = true;
        });
      }

      try {
        final formatted = await compute(_formatJsonIsolate, body);
        _textController.text = formatted;
      } catch (_) {
        _textController.text = body.toString();
      } finally {
        if (mounted) {
          setState(() {
            _isFormatting = false;
          });
        }
      }
    } else if (_selectedTab == 'HTML') {
      _htmlBody = body.toString();
      if (mounted) setState(() {});
    } else {
      _textController.text = body.toString();
      if (mounted) setState(() {});
    }
  }

  Future<String> _getFullBodyText() async {
    final body = _isOffloaded ? _loadedBody : widget.response.body;
    if (body == null) return '';

    final rawSize = widget.response.contentLength > 0 
        ? widget.response.contentLength 
        : body.toString().length;

    if (rawSize > kMaxRenderSize) {
      return body.toString();
    }

    if (_selectedTab == 'JSON') {
      try {
        return await compute(_formatJsonIsolate, body);
      } catch (_) {}
    }
    return body.toString();
  }

  Future<void> _loadOffloadedBody() async {
    if (widget.response.bodyFilePath == null) return;
    setState(() {
      _isLoadingOffloaded = true;
    });

    try {
      final file = File(widget.response.bodyFilePath!);
      if (await file.exists()) {
        final content = await file.readAsString();
        dynamic decoded;
        try {
          decoded = jsonDecode(content);
        } catch (_) {
          decoded = content;
        }
        setState(() {
          _loadedBody = decoded;
          _isOffloaded = false;
          _isLoadingOffloaded = false;
        });
        await _updateBodyText();
      } else {
        throw Exception('Cache file not found');
      }
    } catch (e) {
      setState(() {
        _isLoadingOffloaded = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load response body: $e')),
        );
      }
    }
  }

  void _copyToClipboard() async {
    final text = await _getFullBodyText();
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied response body to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _saveResponseToFile() async {
    try {
      final text = await _getFullBodyText();
      final extension = _selectedTab == 'JSON' ? 'json' : (_selectedTab == 'XML' ? 'xml' : (_selectedTab == 'HTML' ? 'html' : 'txt'));
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

    final lineCount = _textController.text.split('\n').length;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      ),
      child: Column(
        children: [
          // Large Payload Warning Banner
          if (_isLargePayload) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                border: Border(
                  bottom: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Response is too large (${widget.response.formattedSize}). Formatting and syntax coloring are disabled to preserve performance. Please Save File to view the full content.',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 1. Info Header (Matched to Editor background color)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
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

          // 2. Tab selector (None, JSON, XML, HTML, Binary)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                _buildTab('None'),
                _buildTab('JSON'),
                _buildTab('XML'),
                _buildTab('HTML'),
                _buildTab('Binary'),
              ],
            ),
          ),

          // 3. Tab Divider with horizontal margins (indent and endIndent)
          Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: borderColor),

          // 4. Response Content Area (Editor styled with line numbers inside identical BodyEditor box style)
          Expanded(
            child: _buildContentArea(lineCount, borderColor, isDark),
          ),

          const Divider(height: 1, thickness: 1),

          // 5. Footer
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

  Widget _buildTab(String label) {
    final isActive = _selectedTab == label;
    return InkWell(
      onTap: () {
        if (_selectedTab != label) {
          setState(() {
            _selectedTab = label;
          });
          _textController.language = _getLanguageFromTab(label);
          _updateBodyText();
        }
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
    if (_isOffloaded && _loadedBody == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_download_outlined,
              size: 48,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Large Response Saved to Disk',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Size: ${widget.response.formattedSize}',
              style: const TextStyle(fontSize: 12, color: AppColors.slate500),
            ),
            const SizedBox(height: 16),
            if (_isLoadingOffloaded)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _loadOffloadedBody,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Load Response Body'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }

    if (_isFormatting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Formatting JSON response...',
              style: TextStyle(fontSize: 13, color: AppColors.slate500),
            ),
          ],
        ),
      );
    }

    if (_selectedTab == 'None') {
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

    if (_selectedTab == 'Binary') {
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

    if (_selectedTab == 'HTML') {
      return LightweightHtmlViewer(html: _htmlBody);
    }

    // JSON or XML: Styled inside the exact same rounded outer container as BodyEditor
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Line Numbers
              Container(
                width: 40,
                padding: const EdgeInsets.only(top: 16),
                color: isDark ? AppColors.slate800.withValues(alpha: 0.5) : AppColors.slate100,
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
                          fontSize: 13,
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

              // Text Area
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
          ),
        ),
      ),
    );
  }
}

String _formatJsonIsolate(dynamic body) {
  try {
    if (body is Map || body is List) {
      return const JsonEncoder.withIndent('  ').convert(body);
    } else if (body is String) {
      final decoded = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    }
  } catch (_) {}
  return body?.toString() ?? '';
}

class LightweightHtmlViewer extends StatelessWidget {
  final String html;

  const LightweightHtmlViewer({super.key, required this.html});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Extract title
    final titleMatch = RegExp(r'<title>(.*?)</title>', caseSensitive: false, dotAll: true).firstMatch(html);
    final title = titleMatch?.group(1)?.trim() ?? '';

    // Extract h1
    final h1Match = RegExp(r'<h1>(.*?)</h1>', caseSensitive: false, dotAll: true).firstMatch(html);
    final h1 = h1Match?.group(1)?.trim() ?? '';

    // Extract clean body text
    String cleanBody = html;
    cleanBody = cleanBody.replaceAll(RegExp(r'<head>[^]*?</head>', caseSensitive: false), '');
    cleanBody = cleanBody.replaceAll(RegExp(r'<script[^>]*?>[^]*?</script>', caseSensitive: false), '');
    cleanBody = cleanBody.replaceAll(RegExp(r'<style[^>]*?>[^]*?</style>', caseSensitive: false), '');
    cleanBody = cleanBody.replaceAll(RegExp(r'</?(p|div|tr|h1|h2|h3|h4|h5|h6|br|hr)[^>]*?>', caseSensitive: false), '\n');
    cleanBody = cleanBody.replaceAll(RegExp(r'<[^>]*?>'), '');
    cleanBody = cleanBody
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    cleanBody = cleanBody.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).join('\n\n');

    if (cleanBody.length > 2000) {
      cleanBody = '${cleanBody.substring(0, 2000)}...';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.web_rounded,
                size: 44,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              if (h1.isNotEmpty) ...[
                Text(
                  h1,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              if (title.isNotEmpty && title != h1) ...[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              if (cleanBody.isNotEmpty && cleanBody != h1 && cleanBody != title) ...[
                const Divider(height: 32, indent: 24, endIndent: 24),
                Text(
                  cleanBody,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
