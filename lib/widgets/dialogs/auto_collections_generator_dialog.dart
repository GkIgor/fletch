import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fletch/core/app_config.dart';
import 'package:fletch/models/collection_model.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/models/http_request.dart';
import 'package:fletch/providers/request_provider.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:provider/provider.dart';

class AutoCollectionsGeneratorDialog extends StatefulWidget {
  final bool isDark;

  const AutoCollectionsGeneratorDialog({
    super.key,
    required this.isDark,
  });

  @override
  State<AutoCollectionsGeneratorDialog> createState() => _AutoCollectionsGeneratorDialogState();
}

class _AutoCollectionsGeneratorDialogState extends State<AutoCollectionsGeneratorDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final TextEditingController _outlineController;
  final ScrollController _editorScrollController = ScrollController();
  final FocusNode _editorFocusNode = FocusNode();
  int _currentLine = 0;

  // Visual Builder State
  final List<_CollectionConfig> _collections = [];

  // Live parsed outline for Tab 1 preview
  List<_PreviewNode> _previewTree = [];

  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _isInitializing = true;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _outlineController = _OutlineTextEditingController(isDark: true);
    _outlineController.addListener(_onOutlineChanged);
    _editorScrollController.addListener(_onScroll);
    _editorFocusNode.addListener(_onFocusChanged);

    _editorFocusNode.onKeyEvent = (FocusNode node, KeyEvent event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
        final selection = _outlineController.selection;
        if (!selection.isValid) return KeyEventResult.ignored;

        final text = _outlineController.text;
        final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

        if (isShiftPressed) {
          // Shift+Tab: De-indent current line
          final lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
          final lineEndIndex = text.indexOf('\n', selection.start);
          final actualLineEnd = lineEndIndex == -1 ? text.length : lineEndIndex;
          final lineText = text.substring(lineStart, actualLineEnd);

          if (lineText.startsWith('  ')) {
            final newText = text.replaceRange(lineStart, lineStart + 2, '');
            final newSelectionStart = (selection.start - 2).clamp(lineStart, newText.length);
            final newSelectionEnd = (selection.end - 2).clamp(lineStart, newText.length);

            _outlineController.value = TextEditingValue(
              text: newText,
              selection: TextSelection(
                baseOffset: newSelectionStart,
                extentOffset: newSelectionEnd,
              ),
            );
          } else if (lineText.startsWith(' ')) {
            final newText = text.replaceRange(lineStart, lineStart + 1, '');
            final newSelectionStart = (selection.start - 1).clamp(lineStart, newText.length);
            final newSelectionEnd = (selection.end - 1).clamp(lineStart, newText.length);

            _outlineController.value = TextEditingValue(
              text: newText,
              selection: TextSelection(
                baseOffset: newSelectionStart,
                extentOffset: newSelectionEnd,
              ),
            );
          }
          return KeyEventResult.handled;
        } else {
          // Tab: Insert 2 spaces
          final newText = text.replaceRange(selection.start, selection.end, '  ');
          final newSelection = TextSelection.collapsed(offset: selection.start + 2);

          _outlineController.value = TextEditingValue(
            text: newText,
            selection: newSelection,
          );
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    // Start with a default empty collection in the visual builder
    _addCollection(name: 'Auth API');

    // Load draft if exists, else start with default
    _loadDraft();

    _isInitializing = false;
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _outlineController.removeListener(_onOutlineChanged);
    _editorScrollController.removeListener(_onScroll);
    _editorFocusNode.removeListener(_onFocusChanged);
    _outlineController.dispose();
    _editorScrollController.dispose();
    _editorFocusNode.dispose();
    for (var col in _collections) {
      col.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    setState(() {});
  }

  void _onFocusChanged() {
    setState(() {});
  }

  void _onOutlineChanged() {
    _parseOutlineForPreview();

    final selection = _outlineController.selection;
    if (selection.isValid) {
      final textBeforeCursor = _outlineController.text.substring(0, selection.baseOffset);
      final currentLine = '\n'.allMatches(textBeforeCursor).length;
      if (currentLine != _currentLine) {
        setState(() {
          _currentLine = currentLine;
        });
      }
    } else {
      setState(() {});
    }
    _saveDraft();
  }

  // --- State Actions ---

  void _addCollection({String name = ''}) {
    setState(() {
      final col = _CollectionConfig(
        name: name,
        color: _getNextColor(),
        requests: [],
      );
      _collections.add(col);

      // Auto focus the name of the new collection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        col.nameFocusNode.requestFocus();
      });
    });
    _saveDraft();
  }

  void _removeCollection(int index) {
    setState(() {
      _collections[index].dispose();
      _collections.removeAt(index);
    });
    _saveDraft();
  }

  void _addRequest(int colIndex, HttpMethod method, {String name = ''}) {
    setState(() {
      final req = _RequestConfig(
        method: method,
        name: name,
      );
      _collections[colIndex].requests.add(req);
      _collections[colIndex].isExpanded = true;

      // Auto focus the new request name/path input
      WidgetsBinding.instance.addPostFrameCallback((_) {
        req.focusNode.requestFocus();
      });
    });
    _saveDraft();
  }

  void _removeRequest(int colIndex, int reqIndex) {
    setState(() {
      _collections[colIndex].requests[reqIndex].focusNode.dispose();
      _collections[colIndex].requests.removeAt(reqIndex);
    });
    _saveDraft();
  }

  String _getNextColor() {
    final colors = RequestProvider.colors.keys.toList();
    if (colors.isEmpty) return '#8b5cf6';
    return colors[_collections.length % colors.length];
  }

  // --- Parsing Lógica ---

  void _parseOutlineForPreview() {
    final text = _outlineController.text;
    final List<_PreviewNode> rootNodes = [];
    final List<MapEntry<int, _PreviewNode>> stack = [];

    final lines = const LineSplitter().convert(text);
    for (var line in lines) {
      final trimmed = line.trimLeft();
      if (trimmed.isEmpty) continue;

      final indent = line.length - trimmed.length;

      // Pop from stack until the parent indentation is strictly less than the current indentation
      while (stack.isNotEmpty && stack.last.key >= indent) {
        stack.removeLast();
      }

      if (trimmed.startsWith('+') || trimmed.toLowerCase().startsWith('collection:')) {
        String name = trimmed.startsWith('+')
            ? trimmed.substring(1).trim()
            : trimmed.substring(11).trim();
        if (name.isEmpty) name = 'Unnamed Collection';

        final node = _PreviewNode(
          name: name,
          isCollection: true,
          children: [],
        );

        if (stack.isEmpty) {
          rootNodes.add(node);
        } else {
          stack.last.value.children.add(node);
        }
        stack.add(MapEntry(indent, node));
      } else if (trimmed.startsWith('-') || trimmed.toLowerCase().startsWith('request:')) {
        final content = trimmed.startsWith('-')
            ? trimmed.substring(1).trim()
            : trimmed.substring(8).trim();
        if (content.isEmpty) continue;

        final parts = content.split(RegExp(r'\s+'));
        HttpMethod method = HttpMethod.get;
        String name = content;

        if (parts.isNotEmpty) {
          final firstWord = parts[0].toUpperCase();
          final matchingMethod = HttpMethod.values.firstWhere(
            (m) => m.value.toUpperCase() == firstWord,
            orElse: () => HttpMethod.get,
          );
          if (parts.length > 1 && matchingMethod.value.toUpperCase() == firstWord) {
            method = matchingMethod;
            name = parts.sublist(1).join(' ').trim();
          }
        }

        final node = _PreviewNode(
          name: name,
          isCollection: false,
          children: [],
          method: method,
        );

        if (stack.isEmpty) {
          final fallbackNode = _PreviewNode(name: 'Default API', isCollection: true, children: []);
          rootNodes.add(fallbackNode);
          stack.add(MapEntry(0, fallbackNode));
          fallbackNode.children.add(node);
        } else {
          stack.last.value.children.add(node);
        }
      } else {
        // Fallback guess based on method name prefix
        final parts = trimmed.split(RegExp(r'\s+'));
        final firstWord = parts[0].toUpperCase();
        final matchingMethod = HttpMethod.values.where((m) => m.value.toUpperCase() == firstWord);

        if (matchingMethod.isNotEmpty) {
          final method = matchingMethod.first;
          final name = parts.sublist(1).join(' ').trim();
          final node = _PreviewNode(name: name, isCollection: false, children: [], method: method);

          if (stack.isEmpty) {
            final fallbackNode = _PreviewNode(name: 'Default API', isCollection: true, children: []);
            rootNodes.add(fallbackNode);
            stack.add(MapEntry(0, fallbackNode));
            fallbackNode.children.add(node);
          } else {
            stack.last.value.children.add(node);
          }
        } else {
          final node = _PreviewNode(
            name: trimmed,
            isCollection: true,
            children: [],
          );
          if (stack.isEmpty) {
            rootNodes.add(node);
          } else {
            stack.last.value.children.add(node);
          }
          stack.add(MapEntry(indent, node));
        }
      }
    }

    setState(() {
      _previewTree = rootNodes;
    });
  }

  void _populateVisualBuilderFromOutline() {
    _doPopulateVisualBuilderFromOutline();
    _tabController.animateTo(1);
  }

  void _doPopulateVisualBuilderFromOutline() {
    if (_previewTree.isEmpty) return;

    setState(() {
      // Clean current Visual state
      for (var col in _collections) {
        col.dispose();
      }
      _collections.clear();

      void addNodeRecursively(_PreviewNode pNode, String? parentId) {
        if (!pNode.isCollection) return;

        final requests = pNode.children.where((c) => !c.isCollection).map((rNode) {
          return _RequestConfig(
            method: rNode.method ?? HttpMethod.get,
            name: rNode.name,
          );
        }).toList();

        final col = _CollectionConfig(
          name: pNode.name,
          color: _getNextColor(),
          parentId: parentId,
          requests: requests,
        );
        _collections.add(col);

        // Recursively add child collections
        for (var child in pNode.children) {
          if (child.isCollection) {
            addNodeRecursively(child, col.id);
          }
        }
      }

      for (var pNode in _previewTree) {
        addNodeRecursively(pNode, null);
      }
    });

    _saveDraft();
  }

  bool _isGenerateEnabled() {
    if (_tabController.index == 0) {
      return _outlineController.text.trim().isNotEmpty;
    } else {
      return _collections.any((c) => c.name.trim().isNotEmpty);
    }
  }

  Future<void> _handleGenerate() async {
    if (_tabController.index == 0) {
      _parseOutlineForPreview();
      _doPopulateVisualBuilderFromOutline();
    }

    final provider = Provider.of<RequestProvider>(context, listen: false);
    final List<RequestCollection> newCollections = [];

    int collectionCount = 0;
    int requestCount = 0;
    final Map<String, String> idMapping = {};

    for (var colConfig in _collections) {
      if (colConfig.name.trim().isEmpty) continue;

      final requests = colConfig.requests.map((reqConfig) {
        requestCount++;
        return HttpRequest(
          name: reqConfig.name.trim().isEmpty ? '${reqConfig.method.value} Request' : reqConfig.name.trim(),
          method: reqConfig.method,
          url: reqConfig.name.startsWith('/') ? reqConfig.name : '',
        );
      }).toList();

      final col = RequestCollection(
        name: colConfig.name.trim(),
        icon: colConfig.icon,
        color: colConfig.color,
        isExpanded: true,
        requests: requests,
        workspaceId: '', // Populated by request_provider
        sortOrder: provider.collections.length + collectionCount,
      );

      idMapping[colConfig.id] = col.id;
      newCollections.add(col);
      collectionCount++;
    }

    // Resolve parentIds using the generated UUID mapping
    for (int i = 0; i < _collections.length; i++) {
      final colConfig = _collections[i];
      if (colConfig.parentId != null) {
        newCollections[i].parentId = idMapping[colConfig.parentId];
      }
    }

    if (newCollections.isNotEmpty) {
      final wsId = provider.collections.isEmpty ? '' : provider.collections.first.workspaceId;
      try {
        await provider.importLoadedCollections(newCollections, wsId);
        _clearDraft();
      } catch (e) {
        // Silently ignore or handle import error
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated $collectionCount collections and $requestCount requests!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
    _saveDraft();
  }

  void _saveDraft() {
    if (_isInitializing) return;
    try {
      final file = File('${AppConfig.collectionsDir}/../generator_draft.json');
      final data = {
        'outline': _outlineController.text,
        'activeTab': _tabController.index,
        'collections': _collections.map((col) {
          return {
            'id': col.id,
            'name': col.name,
            'icon': col.icon,
            'color': col.color,
            'parentId': col.parentId,
            'requests': col.requests.map((req) {
              return {
                'method': req.method.value,
                'name': req.name,
              };
            }).toList(),
          };
        }).toList(),
      };
      file.writeAsStringSync(jsonEncode(data));
    } catch (e) {
      // Silently ignore saving errors
    }
  }

  void _loadDraft() {
    try {
      final file = File('${AppConfig.collectionsDir}/../generator_draft.json');
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final data = jsonDecode(content);

        final outlineText = data['outline'] as String? ?? '';
        final collectionsJson = data['collections'] as List? ?? [];
        final activeTab = data['activeTab'] as int? ?? 0;

        final List<_CollectionConfig> loadedCollections = [];
        for (var colJson in collectionsJson) {
          final reqListJson = colJson['requests'] as List? ?? [];
          final requests = reqListJson.map((rJson) {
            return _RequestConfig(
              method: HttpMethod.values.firstWhere(
                (m) => m.value == rJson['method'],
                orElse: () => HttpMethod.get,
              ),
              name: rJson['name'] as String? ?? '',
            );
          }).toList();

          loadedCollections.add(
            _CollectionConfig(
              id: colJson['id'] as String?,
              name: colJson['name'] as String? ?? '',
              icon: colJson['icon'] as String? ?? 'folder',
              color: colJson['color'] as String? ?? '#8b5cf6',
              parentId: colJson['parentId'] as String?,
              requests: requests,
            ),
          );
        }

        _outlineController.text = outlineText;
        _collections.clear();
        if (loadedCollections.isNotEmpty) {
          _collections.addAll(loadedCollections);
        } else {
          _addCollection(name: 'Auth API');
        }

        // Re-parse outline for preview tree
        _parseOutlineForPreview();

        // Set tab controller index
        _tabController.index = activeTab;
        return;
      }
    } catch (e) {
      // If error occurs, do nothing since default is already set
    }
  }

  void _clearDraft() {
    try {
      final file = File('${AppConfig.collectionsDir}/../generator_draft.json');
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      // Ignore
    }
  }

  // --- UI Helpers ---

  int _getCollectionDepth(_CollectionConfig col) {
    int depth = 0;
    String? pId = col.parentId;
    while (pId != null) {
      final parentIdx = _collections.indexWhere((c) => c.id == pId);
      if (parentIdx != -1) {
        depth++;
        pId = _collections[parentIdx].parentId;
      } else {
        break;
      }
    }
    return depth;
  }

  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      height: 550,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF0B1120) : Colors.white, // Darker background for contrast
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Auto Collections Generator',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: widget.isDark ? AppColors.borderDark : AppColors.borderLight),

          // Tab bar
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.slate500,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            tabs: const [
              Tab(text: 'Quick Outline Parser'),
              Tab(text: 'Visual Tree Outline Builder'),
            ],
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuickOutlineTab(),
                _buildVisualBuilderTab(),
              ],
            ),
          ),

          Divider(height: 1, color: widget.isDark ? AppColors.borderDark : AppColors.borderLight),
          // Actions footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: widget.isDark ? AppColors.textDark : AppColors.textLight,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: widget.isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isGenerateEnabled() ? _handleGenerate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Generate Collections & Requests'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 1 UI ---

  Widget _buildEditorField() {
    final lines = _outlineController.text.split('\n');
    final totalLines = lines.isEmpty ? 1 : lines.length;

    return Column(
      children: [
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias, // Keep canvas gutter/drawings within the rounded corners
            decoration: BoxDecoration(
              color: AppColors.slate800.withValues(alpha: 0.5), // Match background of line numbers column (gutter)
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: CustomPaint(
              painter: CodeEditorPainter(
                totalLines: totalLines,
                currentLine: _currentLine,
                scrollOffset: _editorScrollController.hasClients ? _editorScrollController.offset : 0.0,
                fontSize: 13.0, // Match 13.0px font size of BodyEditor
                lineHeightMultiplier: 1.5,
                isDark: true, // Always true to match dark body editor gutter style
                text: _outlineController.text,
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 40.0, top: 16.0, bottom: 16.0),
                child: TextField(
                  controller: _outlineController,
                  scrollController: _editorScrollController,
                  focusNode: _editorFocusNode,
                  maxLines: null,
                  minLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top, // Snap cursor to line 1
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13, // Match 13.0px font size of BodyEditor
                    height: 1.5,
                    color: Colors.white, // Match white code text color
                  ),
                  cursorColor: AppColors.primary,
                  inputFormatters: [
                    OutlineInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    isDense: true,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16), // Padding margin between editor card and button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _outlineController.text.trim().isNotEmpty ? _populateVisualBuilderFromOutline : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Populate Visual Builder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickOutlineTab() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left side: Outliner field
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PASTE OUTLINE TEXT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: widget.isDark ? AppColors.textDark.withValues(alpha: 0.6) : AppColors.textLight.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.isDark ? const Color(0xFF0F172A) : AppColors.slate50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: _buildEditorField(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right side: Live Preview
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIVE TREE PREVIEW',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: widget.isDark ? AppColors.textDark.withValues(alpha: 0.6) : AppColors.textLight.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.isDark ? const Color(0xFF0F172A) : AppColors.slate50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: _previewTree.isEmpty
                        ? Center(
                            child: Text(
                              'Tree preview will appear here...',
                              style: TextStyle(fontSize: 12, color: AppColors.slate500),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _previewTree.length,
                            itemBuilder: (context, idx) {
                              final node = _previewTree[idx];
                              return _buildPreviewNodeWidget(node);
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewNodeWidget(_PreviewNode node, {double depth = 0}) {
    if (node.isCollection) {
      return Padding(
        padding: EdgeInsets.only(bottom: 12.0, top: 4.0, left: depth > 0 ? 16.0 : 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  node.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
              ],
            ),
            if (node.children.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(node.children.length, (idx) {
                    final child = node.children[idx];
                    final isLast = idx == node.children.length - 1;
                    if (child.isCollection) {
                      return _buildPreviewNodeWidget(child, depth: depth + 1);
                    } else {
                      return _buildRequestRowWidget(child, isLast, depth: depth + 1);
                    }
                  }),
                ),
              ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMethodBadge(node.method ?? HttpMethod.get),
            const SizedBox(width: 8),
            Text(
              node.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: widget.isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRequestRowWidget(_PreviewNode req, bool isLast, {double depth = 0}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: depth * 8.0), // Indent based on depth
          TreeBranchConnector(isLast: isLast, isDark: widget.isDark),
          const SizedBox(width: 4),
          _buildMethodBadge(req.method ?? HttpMethod.get),
          const SizedBox(width: 8),
          Text(
            req.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: widget.isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodBadge(HttpMethod method) {
    final color = _getMethodColor(method.value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Text(
        method.value,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // --- Tab 2 UI ---

  Widget _buildVisualBuilderTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // List of collections
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _collections.length,
            itemBuilder: (context, index) {
              final col = _collections[index];
              final depth = _getCollectionDepth(col);
              return Container(
                margin: EdgeInsets.only(bottom: 16, left: depth * 16.0),
                decoration: BoxDecoration(
                  color: widget.isDark ? AppColors.slate900.withValues(alpha: 0.3) : AppColors.slate50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    // Collection Header Row
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      title: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              col.isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                              size: 20,
                            ),
                            onPressed: () => setState(() => col.isExpanded = !col.isExpanded),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 6),
                          // Collection name
                          SizedBox(
                            width: 300,
                            child: TextFormField(
                              initialValue: col.name,
                              focusNode: col.nameFocusNode,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                hintText: 'Collection Name (e.g. Payments)',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 6),
                              ),
                              onChanged: (val) {
                                col.name = val;
                                _saveDraft();
                              },
                            ),
                          ),
                          const Spacer(),

                          // Icon selector
                          const SizedBox(width: 12),
                          _buildCollectionIconSelector(col),

                          // Color Selector
                          const SizedBox(width: 12),
                          _buildCollectionColorSelector(col),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () => _removeCollection(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),

                    if (col.isExpanded) ...[
                      Divider(height: 1, color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),

                      // Requests List
                      if (col.requests.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 24.0, right: 12.0, top: 10.0, bottom: 6.0),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(left: BorderSide(color: _hexToColor(col.color).withValues(alpha: 0.5), width: 2.0)),
                            ),
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Column(
                              children: List.generate(col.requests.length, (reqIdx) {
                                final req = col.requests[reqIdx];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Row(
                                    children: [
                                      // Method indicator
                                      SizedBox(
                                        width: 55,
                                        child: Text(
                                          req.method.value,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _getMethodColor(req.method.value),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Path / Name
                                      SizedBox(
                                        width: 350,
                                        child: TextFormField(
                                          initialValue: req.name,
                                          focusNode: req.focusNode,
                                          style: const TextStyle(fontSize: 12),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            hintText: 'e.g. /users/profile or Get User Profile',
                                            hintStyle: TextStyle(fontSize: 12, color: AppColors.slate500.withValues(alpha: 0.5)),
                                            border: InputBorder.none,
                                            focusedBorder: const UnderlineInputBorder(
                                              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(vertical: 6),
                                          ),
                                          onChanged: (val) {
                                            req.name = val;
                                            _saveDraft();
                                          },
                                          onFieldSubmitted: (_) {
                                            // Press Enter to spawn next request of same method
                                            _addRequest(index, req.method);
                                          },
                                        ),
                                      ),
                                      const Spacer(),
                                      // Delete button
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                                        onPressed: () => _removeRequest(index, reqIdx),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),

                      // Quick Method Add Buttons Row
                      Padding(
                        padding: const EdgeInsets.only(left: 36.0, right: 12.0, bottom: 8.0, top: 4.0),
                        child: Row(
                          children: [
                            _buildQuickMethodButton(index, HttpMethod.get),
                            const SizedBox(width: 6),
                            _buildQuickMethodButton(index, HttpMethod.post),
                            const SizedBox(width: 6),
                            _buildQuickMethodButton(index, HttpMethod.put),
                            const SizedBox(width: 6),
                            _buildQuickMethodButton(index, HttpMethod.delete),
                            const SizedBox(width: 6),
                            _buildQuickMethodButton(index, HttpMethod.patch),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom button to add collection
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _addCollection(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Collection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionColorSelector(_CollectionConfig col) {
    final colors = RequestProvider.colors;
    final activeColor = _hexToColor(col.color);

    return PopupMenuButton<String>(
      tooltip: 'Folder Color',
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: activeColor,
          shape: BoxShape.circle,
          border: Border.all(color: widget.isDark ? Colors.white24 : Colors.black12),
        ),
      ),
      onSelected: (colorHex) {
        setState(() {
          col.color = colorHex;
        });
        _saveDraft();
      },
      itemBuilder: (context) {
        return colors.entries.map((entry) {
          return PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: entry.value,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.key == '#8b5cf6' ? 'Purple' : 'Color',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildCollectionIconSelector(_CollectionConfig col) {
    final icons = RequestProvider.icons;
    final activeIcon = icons[col.icon] ?? Icons.folder_rounded;

    return PopupMenuButton<String>(
      tooltip: 'Folder Icon',
      child: Icon(
        activeIcon,
        size: 18,
        color: _hexToColor(col.color).withValues(alpha: 0.8),
      ),
      onSelected: (iconName) {
        setState(() {
          col.icon = iconName;
        });
        _saveDraft();
      },
      itemBuilder: (context) {
        return icons.entries.map((entry) {
          return PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                Icon(entry.value, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  entry.key,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildQuickMethodButton(int colIndex, HttpMethod method) {
    final color = _getMethodColor(method.value);
    return InkWell(
      onTap: () => _addRequest(colIndex, method),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 10, color: color),
            const SizedBox(width: 2),
            Text(
              method.value,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'GET':
        return AppColors.methodGet;
      case 'POST':
        return AppColors.methodPost;
      case 'PUT':
        return AppColors.methodPut;
      case 'DELETE':
        return AppColors.methodDelete;
      case 'PATCH':
        return AppColors.methodPatch;
      default:
        return AppColors.methodGet;
    }
  }
}

// Data models for dialog state management

class _CollectionConfig {
  final String id;
  String name;
  String icon;
  String color;
  bool isExpanded = true;
  final List<_RequestConfig> requests;
  final FocusNode nameFocusNode;
  String? parentId;

  _CollectionConfig({
    String? id,
    required this.name,
    this.icon = 'folder',
    this.color = '#8b5cf6',
    required this.requests,
    FocusNode? nameFocusNode,
    this.parentId,
  })  : id = id ?? UniqueKey().toString(),
        nameFocusNode = nameFocusNode ?? FocusNode();

  void dispose() {
    nameFocusNode.dispose();
    for (var r in requests) {
      r.focusNode.dispose();
    }
  }
}

class _RequestConfig {
  HttpMethod method;
  String name;
  final FocusNode focusNode;

  _RequestConfig({
    required this.method,
    required this.name,
    FocusNode? focusNode,
  }) : focusNode = focusNode ?? FocusNode();
}

class _PreviewNode {
  final String name;
  final bool isCollection;
  final List<_PreviewNode> children;
  final HttpMethod? method;

  _PreviewNode({
    required this.name,
    required this.isCollection,
    required this.children,
    this.method,
  });
}

class CodeEditorPainter extends CustomPainter {
  final int totalLines;
  final int currentLine;
  final double scrollOffset;
  final double fontSize;
  final double lineHeightMultiplier;
  final bool isDark;
  final String text;

  CodeEditorPainter({
    required this.totalLines,
    required this.currentLine,
    required this.scrollOffset,
    required this.fontSize,
    required this.lineHeightMultiplier,
    required this.isDark,
    required this.text,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double lineHeight = fontSize * lineHeightMultiplier;

    // Draw gutter background (matching BodyEditor)
    final gutterPaint = Paint()
      ..color = AppColors.slate800.withValues(alpha: 0.5);
    canvas.drawRect(
      Rect.fromLTWH(0.0, 0.0, 40.0, size.height),
      gutterPaint,
    );

    // 1. Draw current line highlight background
    final activePaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03);

    final double activeTop = currentLine * lineHeight - scrollOffset + 17.5;
    if (activeTop + lineHeight >= 0 && activeTop <= size.height) {
      canvas.drawRect(
        Rect.fromLTWH(40.0, activeTop, size.width - 40.0, lineHeight),
        activePaint,
      );
    }

    // Calculate character width of JetBrains Mono at this fontSize
    final charPainter = TextPainter(
      text: TextSpan(text: ' ', style: GoogleFonts.jetBrainsMono(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    final double charWidth = charPainter.width;

    // Draw vertical guide lines in the editor
    final textLines = text.split('\n');
    int lastCollectionLine = -1;
    int lastRequestLine = -1;
    double lastIndent = 0.0;

    for (int i = 0; i < textLines.length; i++) {
      final line = textLines[i];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('+')) {
        if (lastCollectionLine != -1 && lastRequestLine > lastCollectionLine) {
          _drawEditorGuideLine(canvas, lastCollectionLine, lastRequestLine, lastIndent, charWidth, lineHeight, size.height);
        }
        lastCollectionLine = i;
        lastRequestLine = -1;
        lastIndent = 0.0;
      } else if (trimmed.startsWith('-') && lastCollectionLine != -1) {
        lastRequestLine = i;
        // Count leading spaces to find the indentation column
        final leadingSpaces = line.length - trimmed.length;
        lastIndent = leadingSpaces.toDouble();
      }
    }
    if (lastCollectionLine != -1 && lastRequestLine > lastCollectionLine) {
      _drawEditorGuideLine(canvas, lastCollectionLine, lastRequestLine, lastIndent, charWidth, lineHeight, size.height);
    }

    // 3. Draw line numbers
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < totalLines; i++) {
      final double top = i * lineHeight - scrollOffset + 17.5;
      if (top + lineHeight < 0 || top > size.height) continue;

      final isActive = i == currentLine;
      textPainter.text = TextSpan(
        text: '${i + 1}',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 13, // Match text font size
          height: lineHeightMultiplier,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive
              ? AppColors.primary
              : (isDark ? AppColors.slate500 : AppColors.slate400),
        ),
      );
      textPainter.layout();

      final double x = (40.0 - textPainter.width) / 2; // Center horizontally in the gutter
      final double y = top; // Align vertically with code text

      textPainter.paint(canvas, Offset(x, y));
    }
  }

  void _drawEditorGuideLine(Canvas canvas, int startLine, int endLine, double indent, double charWidth, double lineHeight, double viewHeight) {
    final double col = indent > 0 ? (indent - 0.5) : 0.5;
    final double x = 40.0 + 12.0 + charWidth * col;
    final double startY = (startLine + 1) * lineHeight - scrollOffset + 21.0;
    final double endY = endLine * lineHeight - scrollOffset + 21.0 + (lineHeight / 2.0);

    if (endY < 0 || startY > viewHeight) return;

    final guidePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4) // Brighter and clearer primary color for guide line
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(x, startY),
      Offset(x, endY),
      guidePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CodeEditorPainter oldDelegate) {
    return oldDelegate.totalLines != totalLines ||
        oldDelegate.currentLine != currentLine ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.text != text ||
        oldDelegate.isDark != isDark;
  }
}

class _OutlineTextEditingController extends TextEditingController {
  final bool isDark;

  _OutlineTextEditingController({required this.isDark});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    final lines = text.split('\n');
    final children = <TextSpan>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineChildren = <TextSpan>[];

      final trimmed = line.trimLeft();
      final leadingWhitespace = line.substring(0, line.length - trimmed.length);

      if (leadingWhitespace.isNotEmpty) {
        lineChildren.add(TextSpan(text: leadingWhitespace));
      }

      if (trimmed.startsWith('+')) {
        lineChildren.add(TextSpan(
          text: '+',
          style: TextStyle(
            color: isDark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED),
            fontWeight: FontWeight.bold,
          ),
        ));
        lineChildren.add(TextSpan(text: trimmed.substring(1)));
      } else if (trimmed.startsWith('-')) {
        lineChildren.add(const TextSpan(
          text: '-',
          style: TextStyle(
            color: AppColors.slate500,
            fontWeight: FontWeight.bold,
          ),
        ));

        final restOfLine = trimmed.substring(1);
        final RegExp verbRegExp = RegExp(r'\b(GET|POST|PUT|DELETE|PATCH)\b', caseSensitive: false);
        final matches = verbRegExp.allMatches(restOfLine);

        if (matches.isEmpty) {
          lineChildren.add(TextSpan(text: restOfLine));
        } else {
          int lastIndex = 0;
          for (final match in matches) {
            if (match.start > lastIndex) {
              lineChildren.add(TextSpan(text: restOfLine.substring(lastIndex, match.start)));
            }
            final verb = match.group(0)!;
            lineChildren.add(TextSpan(
              text: verb,
              style: TextStyle(
                color: _getMethodColor(verb.toUpperCase()),
                fontWeight: FontWeight.bold,
              ),
            ));
            lastIndex = match.end;
          }
          if (lastIndex < restOfLine.length) {
            lineChildren.add(TextSpan(text: restOfLine.substring(lastIndex)));
          }
        }
      } else {
        final RegExp verbRegExp = RegExp(r'\b(GET|POST|PUT|DELETE|PATCH)\b', caseSensitive: false);
        final matches = verbRegExp.allMatches(trimmed);

        if (matches.isEmpty) {
          lineChildren.add(TextSpan(text: trimmed));
        } else {
          int lastIndex = 0;
          for (final match in matches) {
            if (match.start > lastIndex) {
              lineChildren.add(TextSpan(text: trimmed.substring(lastIndex, match.start)));
            }
            final verb = match.group(0)!;
            lineChildren.add(TextSpan(
              text: verb,
              style: TextStyle(
                color: _getMethodColor(verb.toUpperCase()),
                fontWeight: FontWeight.bold,
              ),
            ));
            lastIndex = match.end;
          }
          if (lastIndex < trimmed.length) {
            lineChildren.add(TextSpan(text: trimmed.substring(lastIndex)));
          }
        }
      }

      if (i < lines.length - 1) {
        lineChildren.add(const TextSpan(text: '\n'));
      }

      children.addAll(lineChildren);
    }

    return TextSpan(children: children, style: baseStyle);
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'GET':
        return AppColors.methodGet;
      case 'POST':
        return AppColors.methodPost;
      case 'PUT':
        return AppColors.methodPut;
      case 'DELETE':
        return AppColors.methodDelete;
      case 'PATCH':
        return AppColors.methodPatch;
      default:
        return AppColors.methodGet;
    }
  }
}

class TreeBranchConnector extends StatelessWidget {
  final bool isLast;
  final bool isDark;

  const TreeBranchConnector({
    super.key,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 20),
      painter: _BranchPainter(isLast: isLast, isDark: isDark),
    );
  }
}

class _BranchPainter extends CustomPainter {
  final bool isLast;
  final bool isDark;

  _BranchPainter({required this.isLast, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.15)
          : Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double halfX = size.width / 2;
    final double halfY = size.height / 2;

    // Draw vertical line
    if (isLast) {
      canvas.drawLine(Offset(halfX, 0), Offset(halfX, halfY), paint);
    } else {
      canvas.drawLine(Offset(halfX, 0), Offset(halfX, size.height), paint);
    }

    // Draw horizontal line to the right
    canvas.drawLine(Offset(halfX, halfY), Offset(size.width, halfY), paint);
  }

  @override
  bool shouldRepaint(covariant _BranchPainter oldDelegate) {
    return oldDelegate.isLast != isLast || oldDelegate.isDark != isDark;
  }
}

class OutlineInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    // Detect if a single newline character '\n' was added
    if (newText.length > oldText.length) {
      final oldStart = oldValue.selection.start;
      final addedText = newText.substring(oldStart, newValue.selection.end);

      if (addedText == '\n') {
        // Find the beginning of the line where Enter was pressed
        final lastNewline = oldText.lastIndexOf('\n', oldStart - 1);
        final lineStart = lastNewline == -1 ? 0 : lastNewline + 1;
        final lineContent = oldText.substring(lineStart, oldStart);

        // Extract the leading indentation spaces/tabs from the current line
        String indent = '';
        for (int i = 0; i < lineContent.length; i++) {
          if (lineContent[i] == ' ' || lineContent[i] == '\t') {
            indent += lineContent[i];
          } else {
            break;
          }
        }

        final prefix = oldText.substring(0, oldStart);
        final suffix = oldText.substring(oldStart);
        final updatedText = '$prefix\n$indent$suffix';
        return TextEditingValue(
          text: updatedText,
          selection: TextSelection.collapsed(offset: oldStart + 1 + indent.length),
        );
      }
    }
    return newValue;
  }
}
