import 'package:uuid/uuid.dart';
import 'package:fletch/models/collection_model.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/models/http_request.dart';
import 'package:fletch/widgets/body_editor.dart';

class PostmanConverter {
  static List<RequestCollection> importCollection(Map<String, dynamic> postmanJson, String workspaceId) {
    final List<RequestCollection> collections = [];
    final info = postmanJson['info'] as Map<String, dynamic>?;
    final rootName = info?['name'] as String? ?? 'Imported Postman Collection';
    final rootDescription = info?['description'] as String?;

    // The root of a Postman Collection is itself a folder.
    final rootCollection = RequestCollection(
      name: rootName,
      description: rootDescription,
      workspaceId: workspaceId,
      parentId: null,
    );
    collections.add(rootCollection);

    final items = postmanJson['item'] as List?;
    if (items != null) {
      _importItems(items, rootCollection.id, workspaceId, collections);
    }

    return collections;
  }

  static void _importItems(
    List<dynamic> items,
    String parentCollectionId,
    String workspaceId,
    List<RequestCollection> collections,
  ) {
    for (var item in items) {
      if (item is! Map<String, dynamic>) continue;

      final name = item['name'] as String? ?? 'Unnamed Item';
      final description = item['description'] as String?;

      if (item.containsKey('item')) {
        // This is a sub-folder/sub-collection
        final subCollection = RequestCollection(
          name: name,
          description: description,
          workspaceId: workspaceId,
          parentId: parentCollectionId,
        );
        collections.add(subCollection);

        final subItems = item['item'] as List?;
        if (subItems != null) {
          _importItems(subItems, subCollection.id, workspaceId, collections);
        }
      } else if (item.containsKey('request')) {
        // This is a request
        final requestData = item['request'];
        final httpRequest = _parsePostmanRequest(name, requestData);

        // Add this request to the parent collection
        final parentIdx = collections.indexWhere((c) => c.id == parentCollectionId);
        if (parentIdx != -1) {
          collections[parentIdx].requests.add(httpRequest);
        }
      }
    }
  }

  static HttpRequest _parsePostmanRequest(String name, dynamic requestData) {
    String methodStr = 'GET';
    String urlStr = '';
    final Map<String, String> headers = {};
    final Map<String, String> queryParams = {};
    String? bodyContent;
    BodyType bodyType = BodyType.none;
    final List<FormDataEntry> formData = [];

    if (requestData is String) {
      urlStr = requestData;
    } else if (requestData is Map<String, dynamic>) {
      methodStr = requestData['method'] as String? ?? 'GET';
      
      // Parse URL
      final urlData = requestData['url'];
      if (urlData is String) {
        urlStr = urlData;
      } else if (urlData is Map<String, dynamic>) {
        urlStr = urlData['raw'] as String? ?? '';
        final queryList = urlData['query'] as List?;
        if (queryList != null) {
          for (var q in queryList) {
            if (q is Map<String, dynamic>) {
              final key = q['key'] as String?;
              final val = q['value'] as String?;
              if (key != null && val != null) {
                queryParams[key] = val;
              }
            }
          }
        }
      }

      // Parse Headers
      final headerList = requestData['header'] as List?;
      if (headerList != null) {
        for (var h in headerList) {
          if (h is Map<String, dynamic>) {
            final key = h['key'] as String?;
            final val = h['value'] as String?;
            if (key != null && val != null) {
              headers[key] = val;
            }
          }
        }
      }

      // Parse Body
      final bodyData = requestData['body'] as Map<String, dynamic>?;
      if (bodyData != null) {
        final mode = bodyData['mode'] as String?;
        if (mode == 'raw') {
          bodyContent = bodyData['raw'] as String?;
          bodyType = BodyType.json;
          
          // Detect if it is JSON or XML
          final rawOptions = bodyData['options'] as Map<String, dynamic>?;
          final rawType = rawOptions?['raw'] as Map<String, dynamic>?;
          final language = rawType?['language'] as String?;
          if (language == 'xml' || language == 'html') {
            bodyType = BodyType.xml;
          }
        } else if (mode == 'urlencoded') {
          bodyType = BodyType.formData;
          final urlencodeList = bodyData['urlencoded'] as List?;
          if (urlencodeList != null) {
            for (var entry in urlencodeList) {
              if (entry is Map<String, dynamic>) {
                formData.add(FormDataEntry(
                  key: entry['key'] as String? ?? '',
                  value: entry['value'] as String? ?? '',
                  isFile: false,
                ));
              }
            }
          }
        } else if (mode == 'formdata') {
          bodyType = BodyType.formData;
          final formdataList = bodyData['formdata'] as List?;
          if (formdataList != null) {
            for (var entry in formdataList) {
              if (entry is Map<String, dynamic>) {
                final isFile = entry['type'] == 'file';
                formData.add(FormDataEntry(
                  key: entry['key'] as String? ?? '',
                  value: isFile ? (entry['src'] as String? ?? '') : (entry['value'] as String? ?? ''),
                  isFile: isFile,
                ));
              }
            }
          }
        }
      }
    }

    final method = HttpMethod.values.firstWhere(
      (m) => m.value.toUpperCase() == methodStr.toUpperCase(),
      orElse: () => HttpMethod.get,
    );

    return HttpRequest(
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
    String workspaceName,
  ) {
    final Map<String, dynamic> postmanJson = {
      "info": {
        "_postman_id": const Uuid().v4(),
        "name": "Workspace - $workspaceName",
        "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
      },
      "item": []
    };

    final rootCollections = collections.where((c) => c.parentId == null).toList();
    rootCollections.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (var rootColl in rootCollections) {
      postmanJson['item'].add(_exportCollectionFolder(rootColl, collections));
    }

    return postmanJson;
  }

  static Map<String, dynamic> _exportCollectionFolder(
    RequestCollection collection,
    List<RequestCollection> allCollections,
  ) {
    final Map<String, dynamic> folderJson = {
      "name": collection.name,
      "item": []
    };

    if (collection.description != null && collection.description!.isNotEmpty) {
      folderJson["description"] = collection.description;
    }

    // Export sub-folders
    final subFolders = allCollections.where((c) => c.parentId == collection.id).toList();
    subFolders.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (var sub in subFolders) {
      folderJson["item"].add(_exportCollectionFolder(sub, allCollections));
    }

    // Export requests
    for (var req in collection.requests) {
      folderJson["item"].add(_exportRequest(req));
    }

    return folderJson;
  }

  static Map<String, dynamic> _exportRequest(HttpRequest req) {
    final List<Map<String, String>> headers = [];
    req.headers.forEach((k, v) {
      headers.add({"key": k, "value": v});
    });

    final Map<String, dynamic> requestJson = {
      "name": req.name,
      "request": {
        "method": req.method.value,
        "header": headers,
        "url": {
          "raw": req.url,
        }
      }
    };

    if (req.bodyType != BodyType.none) {
      final Map<String, dynamic> bodyJson = {};
      if (req.bodyType == BodyType.json) {
        bodyJson["mode"] = "raw";
        bodyJson["raw"] = req.body ?? "";
        bodyJson["options"] = {
          "raw": {
            "language": "json"
          }
        };
      } else if (req.bodyType == BodyType.xml) {
        bodyJson["mode"] = "raw";
        bodyJson["raw"] = req.body ?? "";
        bodyJson["options"] = {
          "raw": {
            "language": "xml"
          }
        };
      } else if (req.bodyType == BodyType.formData) {
        bodyJson["mode"] = "formdata";
        bodyJson["formdata"] = req.formData.map((entry) {
          return {
            "key": entry.key,
            "value": entry.value,
            "type": entry.isFile ? "file" : "text",
            "enabled": entry.enabled
          };
        }).toList();
      }
      requestJson["request"]["body"] = bodyJson;
    }

    return requestJson;
  }
}
