import 'package:flutter/material.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/models/http_request.dart';
import 'package:fletch/providers/request_provider.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:fletch/widgets/body_editor.dart';
import 'package:provider/provider.dart';


class PayloadBulkImporterDialog extends StatefulWidget {
  final List<MapEntry<String, String>> filesData;
  final bool isDark;

  const PayloadBulkImporterDialog({
    super.key,
    required this.filesData,
    required this.isDark,
  });

  @override
  State<PayloadBulkImporterDialog> createState() => _PayloadBulkImporterDialogState();
}

class _PayloadBulkImporterDialogState extends State<PayloadBulkImporterDialog> {
  // Store row configs
  late List<_ImportRowConfig> _configs;
  bool _selectAll = true;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<RequestProvider>(context, listen: false);
    final collections = provider.collections;
    final List<HttpRequest> allRequests = [];
    for (var col in collections) {
      allRequests.addAll(col.requests);
    }
    final defaultCollectionId = collections.isNotEmpty ? collections.first.id : null;
    final defaultTargetRequestId = allRequests.isNotEmpty ? allRequests.first.id : null;

    _configs = widget.filesData.map((fileData) {
      // Remove extension for default name
      final defaultName = fileData.key.replaceAll(RegExp(r'\.json$', caseSensitive: false), '');
      return _ImportRowConfig(
        fileName: fileData.key,
        content: fileData.value,
        requestName: defaultName,
        selected: true,
        action: ImportAction.createRequest,
        method: HttpMethod.post,
        collectionId: defaultCollectionId,
        targetRequestId: defaultTargetRequestId,
      );
    }).toList();
  }

  void _toggleSelectAll(bool? val) {
    if (val == null) return;
    setState(() {
      _selectAll = val;
      for (var config in _configs) {
        config.selected = val;
      }
    });
  }

  Future<void> _handleImport() async {
    final provider = Provider.of<RequestProvider>(context, listen: false);
    final List<MapEntry<String, HttpRequest>> newRequests = [];
    final List<HttpRequest> updatedRequests = [];

    // Gather allRequests for fallback matching
    final List<HttpRequest> allRequests = [];
    for (var col in provider.collections) {
      allRequests.addAll(col.requests);
    }

    int count = 0;
    for (var config in _configs) {
      if (!config.selected) continue;

      if (config.action == ImportAction.createRequest) {
        final collectionId = config.collectionId ?? (provider.collections.isNotEmpty ? provider.collections.first.id : null);
        if (collectionId == null) continue;
        
        final req = HttpRequest(
          name: config.requestName.trim().isEmpty ? config.fileName : config.requestName.trim(),
          method: config.method,
          url: '',
          bodyType: BodyType.json,
          body: config.content,
        );
        newRequests.add(MapEntry(collectionId, req));
        count++;
      } else {
        final targetRequestId = config.targetRequestId ?? (allRequests.isNotEmpty ? allRequests.first.id : null);
        if (targetRequestId == null) continue;

        // Find existing request to clone it with updated body
        HttpRequest? existing;
        for (var col in provider.collections) {
          final found = col.requests.where((r) => r.id == targetRequestId);
          if (found.isNotEmpty) {
            existing = found.first;
            break;
          }
        }

        if (existing != null) {
          final updated = existing.copyWith(
            body: config.content,
            bodyType: BodyType.json,
          );
          updatedRequests.add(updated);
          count++;
        }
      }
    }

    if (count > 0) {
      await provider.bulkImportPayloads(
        newRequestsWithCollectionId: newRequests,
        updatedRequests: updatedRequests,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count payloads imported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RequestProvider>(context);
    final collections = provider.collections;
    
    // Flatten requests for selection
    final List<HttpRequest> allRequests = [];
    final Map<String, String> requestCollectionNames = {};
    for (var col in collections) {
      for (var req in col.requests) {
        allRequests.add(req);
        requestCollectionNames[req.id] = col.name;
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth * 0.85).clamp(800.0, 1100.0);
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = (screenHeight * 0.8).clamp(520.0, 750.0);

    return Container(
      width: dialogWidth,
      height: dialogHeight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.system_update_alt_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Payload Bulk Importer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: widget.isDark ? AppColors.borderDark : AppColors.borderLight),
          const SizedBox(height: 8),
          
          // Select All Checkbox
          Row(
            children: [
              Checkbox(
                value: _selectAll,
                activeColor: AppColors.primary,
                onChanged: _toggleSelectAll,
              ),
              const Text(
                'Select All Files',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Files list
          Expanded(
            child: ListView.builder(
              itemCount: _configs.length,
              itemBuilder: (context, index) {
                final config = _configs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.isDark ? AppColors.slate900.withValues(alpha: 0.3) : AppColors.slate50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Active Checkbox
                      Checkbox(
                        value: config.selected,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              config.selected = val;
                              _selectAll = _configs.every((c) => c.selected);
                            });
                          }
                        },
                      ),
                      
                      // File Details
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              config.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Size: ${(config.content.length / 1024).toStringAsFixed(2)} KB',
                              style: TextStyle(fontSize: 11, color: AppColors.slate500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Action selector
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<ImportAction>(
                          key: ValueKey('action_dropdown_$index'),
                          isExpanded: true,
                          initialValue: config.action,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          items: const [
                            DropdownMenuItem(value: ImportAction.createRequest, child: Text('Create Request', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: ImportAction.replaceBody, child: Text('Replace Body', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => config.action = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Contextual inputs
                      Expanded(
                        flex: 8,
                        child: config.action == ImportAction.createRequest
                            ? Row(
                                children: [
                                  // Collection Dropdown
                                  Expanded(
                                    flex: 3,
                                    child: DropdownButtonFormField<String>(
                                      key: ValueKey('collection_dropdown_$index'),
                                      isExpanded: true,
                                      initialValue: config.collectionId,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      items: collections.isEmpty
                                          ? const [
                                              DropdownMenuItem(
                                                value: null,
                                                child: Text('No collections', style: TextStyle(fontSize: 12)),
                                              )
                                            ]
                                          : collections.map((col) {
                                              return DropdownMenuItem(
                                                value: col.id,
                                                child: Text(col.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                              );
                                            }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          config.collectionId = val;
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Method Dropdown
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<HttpMethod>(
                                      key: ValueKey('method_dropdown_$index'),
                                      isExpanded: true,
                                      initialValue: config.method,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      items: HttpMethod.values.map((method) {
                                        return DropdownMenuItem(
                                          value: method,
                                          child: Text(
                                            method.value,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _getMethodColor(method),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          config.method = val;
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Request Name
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      key: ValueKey('request_name_field_$index'),
                                      initialValue: config.requestName,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        hintText: 'Request Name',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      onChanged: (val) => config.requestName = val,
                                    ),
                                  ),
                                ],
                              )
                            : DropdownButtonFormField<String>(
                                key: ValueKey('target_request_dropdown_$index'),
                                isExpanded: true,
                                initialValue: config.targetRequestId,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                items: allRequests.isEmpty
                                    ? const [DropdownMenuItem(value: null, child: Text('No requests found', style: TextStyle(fontSize: 12)))]
                                    : allRequests.map((req) {
                                        final collName = requestCollectionNames[req.id] ?? '';
                                        return DropdownMenuItem(
                                          value: req.id,
                                          child: Text('$collName > ${req.name}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                        );
                                      }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    config.targetRequestId = val;
                                  }
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          Divider(color: widget.isDark ? AppColors.borderDark : AppColors.borderLight),
          const SizedBox(height: 8),
          
          // Dialog Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: widget.isDark ? AppColors.textDark : AppColors.textLight,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: widget.isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _configs.any((c) => c.selected) ? _handleImport : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Import Selected Payloads'),
              ),
            ],
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
}

enum ImportAction {
  createRequest,
  replaceBody;
}

class _ImportRowConfig {
  final String fileName;
  final String content;
  bool selected;
  ImportAction action;
  HttpMethod method;
  String requestName;
  String? collectionId;
  String? targetRequestId;

  _ImportRowConfig({
    required this.fileName,
    required this.content,
    required this.selected,
    required this.action,
    required this.method,
    required this.requestName,
    this.collectionId,
    this.targetRequestId,
  });
}
