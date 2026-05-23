import 'package:fletch/models/collection_model.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/models/http_request.dart';
import 'package:fletch/widgets/body_editor.dart';

class InsomniaConverter {
  static List<RequestCollection> importCollection(Map<String, dynamic> insomniaJson, String workspaceId) {
    if (insomniaJson.containsKey('collection') && insomniaJson['collection'] is List) {
      return _importTreeCollection(insomniaJson['collection'] as List, workspaceId);
    }

    final resources = insomniaJson['resources'] as List?;
    if (resources == null) return [];

    final Map<String, RequestCollection> collectionsMap = {};
    final List<Map<String, dynamic>> requestsData = [];

    // First, identify all folders (request_group)
    for (var res in resources) {
      if (res is! Map<String, dynamic>) continue;
      final type = res['_type'] as String?;
      final id = res['_id'] as String?;
      final name = res['name'] as String? ?? 'Folder';
      final description = res['description'] as String?;

      if (type == 'request_group' && id != null) {
        collectionsMap[id] = RequestCollection(
          id: id,
          name: name,
          description: description,
          workspaceId: workspaceId,
        );
      } else if (type == 'request') {
        requestsData.add(res);
      }
    }

    // Second pass: resolve parentId for folders
    for (var res in resources) {
      if (res is! Map<String, dynamic>) continue;
      if (res['_type'] == 'request_group') {
        final id = res['_id'] as String;
        final parentId = res['parentId'] as String?;
        if (parentId != null && collectionsMap.containsKey(parentId)) {
          collectionsMap[id]!.parentId = parentId;
        }
      }
    }

    // Third pass: parse requests and assign them to folders
    RequestCollection? defaultRootCollection;

    for (var res in requestsData) {
      final name = res['name'] as String? ?? 'Request';
      final parentId = res['parentId'] as String?;
      final httpRequest = _parseInsomniaRequest(name, res);

      if (parentId != null && collectionsMap.containsKey(parentId)) {
        collectionsMap[parentId]!.requests.add(httpRequest);
      } else {
        defaultRootCollection ??= RequestCollection(
          name: 'Imported Insomnia Requests',
          workspaceId: workspaceId,
        );
        defaultRootCollection.requests.add(httpRequest);
      }
    }

    final List<RequestCollection> result = collectionsMap.values.toList();
    if (defaultRootCollection != null) {
      result.add(defaultRootCollection);
    }
    return result;
  }

  static HttpRequest _parseInsomniaRequest(String name, Map<String, dynamic> res) {
    final methodStr = res['method'] as String? ?? 'GET';
    final urlStr = res['url'] as String? ?? '';
    final Map<String, String> headers = {};
    final Map<String, String> queryParams = {};
    String? bodyContent;
    BodyType bodyType = BodyType.none;
    final List<FormDataEntry> formData = [];

    // Parse headers
    final headersList = res['headers'] as List?;
    if (headersList != null) {
      for (var h in headersList) {
        if (h is Map<String, dynamic>) {
          final hName = h['name'] as String?;
          final hValue = h['value'] as String?;
          if (hName != null && hValue != null) {
            headers[hName] = hValue;
          }
        }
      }
    }

    // Parse query params (parameters)
    final paramsList = res['parameters'] as List?;
    if (paramsList != null) {
      for (var p in paramsList) {
        if (p is Map<String, dynamic>) {
          final pName = p['name'] as String?;
          final pValue = p['value'] as String?;
          if (pName != null && pValue != null) {
            queryParams[pName] = pValue;
          }
        }
      }
    }

    // Parse body
    final bodyData = res['body'] as Map<String, dynamic>?;
    if (bodyData != null) {
      bodyContent = bodyData['text'] as String?;
      final mimeType = bodyData['mimeType'] as String?;
      if (mimeType != null && mimeType.contains('application/json')) {
        bodyType = BodyType.json;
      } else if (mimeType != null && mimeType.contains('multipart/form-data')) {
        bodyType = BodyType.formData;
        final params = bodyData['params'] as List?;
        if (params != null) {
          for (var p in params) {
            if (p is Map<String, dynamic>) {
              final isFile = p['type'] == 'file';
              formData.add(FormDataEntry(
                key: p['name'] as String? ?? '',
                value: isFile ? (p['fileName'] as String? ?? '') : (p['value'] as String? ?? ''),
                isFile: isFile,
              ));
            }
          }
        }
      } else if (bodyContent != null && bodyContent.isNotEmpty) {
        bodyType = BodyType.json;
      }
    }

    final method = HttpMethod.values.firstWhere(
      (m) => m.value.toUpperCase() == methodStr.toUpperCase(),
      orElse: () => HttpMethod.get,
    );

    return HttpRequest(
      id: res['_id'] as String?,
      name: name,
      method: method,
      url: urlStr,
      headers: headers,
      queryParams: queryParams,
      body: bodyContent,
      bodyType: bodyType,
      formData: formData,
    );
  }

  static Map<String, dynamic> exportCollection(
    List<RequestCollection> collections,
    String workspaceId,
    String workspaceName, {
    int exportFormat = 4,
  }) {
    final List<Map<String, dynamic>> resources = [];

    // 1. Add Workspace resource
    final String insomniaWorkspaceId = "wrk_${workspaceId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}";
    resources.add({
      "_id": insomniaWorkspaceId,
      "parentId": null,
      "modified": DateTime.now().millisecondsSinceEpoch,
      "created": DateTime.now().millisecondsSinceEpoch,
      "name": workspaceName,
      "description": "Exported from Fletch",
      "cornerColor": null,
      "colors": {},
      "_type": "workspace"
    });

    // 2. Add folders (request_group)
    for (var col in collections) {
      final String parentId = col.parentId != null
          ? col.parentId!
          : insomniaWorkspaceId;

      resources.add({
        "_id": col.id,
        "parentId": parentId,
        "modified": DateTime.now().millisecondsSinceEpoch,
        "created": DateTime.now().millisecondsSinceEpoch,
        "name": col.name,
        "description": col.description ?? "",
        "environment": {},
        "environmentPropertyOrder": null,
        "metaSortKey": col.sortOrder,
        "_type": "request_group"
      });

      // 3. Add requests in this folder
      for (var req in col.requests) {
        final List<Map<String, String>> reqHeaders = [];
        req.headers.forEach((k, v) {
          reqHeaders.add({"name": k, "value": v});
        });

        final List<Map<String, String>> reqQueryParams = [];
        req.queryParams.forEach((k, v) {
          reqQueryParams.add({"name": k, "value": v});
        });

        final Map<String, dynamic> bodyJson = {};
        if (req.bodyType == BodyType.json) {
          bodyJson["mimeType"] = "application/json";
          bodyJson["text"] = req.body ?? "";
        } else if (req.bodyType == BodyType.xml) {
          bodyJson["mimeType"] = "application/xml";
          bodyJson["text"] = req.body ?? "";
        } else if (req.bodyType == BodyType.formData) {
          bodyJson["mimeType"] = "multipart/form-data";
          bodyJson["params"] = req.formData.map((entry) {
            return {
              "name": entry.key,
              "value": entry.value,
              "type": entry.isFile ? "file" : "text",
              "disabled": !entry.enabled
            };
          }).toList();
        }

        resources.add({
          "_id": req.id,
          "parentId": col.id,
          "modified": DateTime.now().millisecondsSinceEpoch,
          "created": DateTime.now().millisecondsSinceEpoch,
          "url": req.url,
          "name": req.name,
          "description": "",
          "method": req.method.value,
          "body": bodyJson,
          "parameters": reqQueryParams,
          "headers": reqHeaders,
          "authentication": {},
          "metaSortKey": 0,
          "isPrivate": false,
          "_type": "request"
        });
      }
    }

    return {
      "_type": "export",
      "__export_format": exportFormat,
      "__export_date": DateTime.now().toIso8601String(),
      "__export_source": "fletch:v1.0.0",
      "resources": resources
    };
  }

  static List<RequestCollection> _importTreeCollection(List<dynamic> collectionList, String workspaceId) {
    final List<RequestCollection> folders = [];
    RequestCollection? defaultRootCollection;

    void traverse(dynamic node, String? parentId) {
      if (node is! Map) return;
      final nodeMap = Map<String, dynamic>.from(node);

      final name = nodeMap['name'] as String? ?? 'Item';
      final meta = nodeMap['meta'] as Map? ?? {};
      final id = meta['id'] as String? ?? 'id_${DateTime.now().millisecondsSinceEpoch}_${node.hashCode}';
      final description = meta['description'] as String?;

      final children = nodeMap['children'] as List?;
      final isFolder = id.startsWith('fld_') || children != null;

      if (isFolder) {
        final folder = RequestCollection(
          id: id,
          name: name,
          description: description,
          workspaceId: workspaceId,
          parentId: parentId,
        );
        folders.add(folder);

        if (children != null) {
          for (var child in children) {
            traverse(child, id);
          }
        }
      } else {
        // It's a request
        nodeMap['_id'] = id;
        final request = _parseInsomniaRequest(name, nodeMap);

        if (parentId != null) {
          // Find parent folder in our accumulated folders list
          final parentIndex = folders.indexWhere((f) => f.id == parentId);
          if (parentIndex != -1) {
            folders[parentIndex].requests.add(request);
          } else {
            defaultRootCollection ??= RequestCollection(
              name: 'Imported Insomnia Requests',
              workspaceId: workspaceId,
            );
            defaultRootCollection!.requests.add(request);
          }
        } else {
          defaultRootCollection ??= RequestCollection(
            name: 'Imported Insomnia Requests',
            workspaceId: workspaceId,
          );
          defaultRootCollection!.requests.add(request);
        }
      }
    }

    for (var item in collectionList) {
      traverse(item, null);
    }

    if (defaultRootCollection != null) {
      folders.add(defaultRootCollection!);
    }

    return folders;
  }
}
