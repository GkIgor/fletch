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

import 'package:fletch/widgets/dialogs/auto_collections_generator/generator_models.dart';
import 'package:fletch/widgets/dialogs/auto_collections_generator/generator_utils.dart';
import 'package:fletch/widgets/dialogs/auto_collections_generator/code_editor_painter.dart';
import 'package:fletch/widgets/dialogs/auto_collections_generator/tree_branch_connector.dart';
import 'package:fletch/widgets/dialogs/auto_collections_generator/outline_text_editing_controller.dart';
import 'package:fletch/widgets/dialogs/auto_collections_generator/outline_input_formatter.dart';
import 'package:fletch/widgets/dialogs/auto_collections_generator/visual_collection_card.dart';

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
  final List<CollectionConfig> _collections = [];

  // Live parsed outline for Tab 1 preview
  List<PreviewNode> _previewTree = [];

  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _isInitializing = true;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _outlineController = OutlineTextEditingController(isDark: true);
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
      final col = CollectionConfig(
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
      final req = RequestConfig(
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
    final List<PreviewNode> rootNodes = [];
    final List<MapEntry<int, PreviewNode>> stack = [];

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

        final node = PreviewNode(
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

        final node = PreviewNode(
          name: name,
          isCollection: false,
          children: [],
          method: method,
        );

        if (stack.isEmpty) {
          final fallbackNode = PreviewNode(name: 'Default API', isCollection: true, children: []);
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
          final node = PreviewNode(name: name, isCollection: false, children: [], method: method);

          if (stack.isEmpty) {
            final fallbackNode = PreviewNode(name: 'Default API', isCollection: true, children: []);
            rootNodes.add(fallbackNode);
            stack.add(MapEntry(0, fallbackNode));
            fallbackNode.children.add(node);
          } else {
            stack.last.value.children.add(node);
          }
        } else {
          final node = PreviewNode(
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

      void addNodeRecursively(PreviewNode pNode, String? parentId) {
        if (!pNode.isCollection) return;

        final requests = pNode.children.where((c) => !c.isCollection).map((rNode) {
          return RequestConfig(
            method: rNode.method ?? HttpMethod.get,
            name: rNode.name,
          );
        }).toList();

        final col = CollectionConfig(
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

        final List<CollectionConfig> loadedCollections = [];
        for (var colJson in collectionsJson) {
          final reqListJson = colJson['requests'] as List? ?? [];
          final requests = reqListJson.map((rJson) {
            return RequestConfig(
              method: HttpMethod.values.firstWhere(
                (m) => m.value == rJson['method'],
                orElse: () => HttpMethod.get,
              ),
              name: rJson['name'] as String? ?? '',
            );
          }).toList();

          loadedCollections.add(
            CollectionConfig(
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

  int _getCollectionDepth(CollectionConfig col) {
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

  Widget _buildPreviewNodeWidget(PreviewNode node, {double depth = 0}) {
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

  Widget _buildRequestRowWidget(PreviewNode req, bool isLast, {double depth = 0}) {
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
    final color = getMethodColor(method.value);
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
              return VisualCollectionCard(
                collection: col,
                index: index,
                isDark: widget.isDark,
                depth: depth,
                onToggleExpand: () => setState(() => col.isExpanded = !col.isExpanded),
                onNameChanged: (val) {
                  col.name = val;
                  _saveDraft();
                },
                onRemove: () => _removeCollection(index),
                onAddRequest: (method) => _addRequest(index, method),
                onRemoveRequest: (reqIdx) => _removeRequest(index, reqIdx),
                onRequestNameChanged: (reqIdx, val) {
                  col.requests[reqIdx].name = val;
                  _saveDraft();
                },
                onAddRequestAfter: (reqIdx, method) => _addRequest(index, method),
                onIconSelected: (iconName) {
                  setState(() {
                    col.icon = iconName;
                  });
                  _saveDraft();
                },
                onColorSelected: (colorHex) {
                  setState(() {
                    col.color = colorHex;
                  });
                  _saveDraft();
                },
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
}
