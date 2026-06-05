import 'package:fletch/models/collection_model.dart';
import 'package:fletch/models/http_auth.dart';
import 'package:fletch/models/http_request.dart';

class AuthResolver {
  /// Resolves the auth configuration for a request.
  /// Follows the inheritance chain recursively:
  /// HttpRequest -> RequestCollection -> Parent Collection -> Workspace
  static HttpAuth resolveAuth({
    required HttpRequest request,
    required List<RequestCollection> collections,
    required HttpAuth workspaceAuth,
  }) {
    if (request.auth.type != AuthType.inherit) {
      return request.auth;
    }

    // Find the request's parent collection
    RequestCollection? parentCol;
    for (var col in collections) {
      if (col.requests.any((r) => r.id == request.id)) {
        parentCol = col;
        break;
      }
    }

    if (parentCol == null) {
      return workspaceAuth;
    }

    return resolveCollectionAuth(
      collection: parentCol,
      collections: collections,
      workspaceAuth: workspaceAuth,
    );
  }

  /// Resolves the auth configuration for a collection.
  /// Follows the inheritance chain recursively:
  /// RequestCollection -> Parent Collection -> Workspace
  static HttpAuth resolveCollectionAuth({
    required RequestCollection collection,
    required List<RequestCollection> collections,
    required HttpAuth workspaceAuth,
  }) {
    if (collection.auth.type != AuthType.inherit) {
      return collection.auth;
    }

    if (collection.parentId == null) {
      return workspaceAuth;
    }

    // Find parent collection
    RequestCollection? parentCol;
    try {
      parentCol = collections.firstWhere((c) => c.id == collection.parentId);
    } catch (_) {}

    if (parentCol == null) {
      return workspaceAuth;
    }

    // Recursive call
    return resolveCollectionAuth(
      collection: parentCol,
      collections: collections,
      workspaceAuth: workspaceAuth,
    );
  }

  /// Resolves where the authentication is inherited from, returning a user-friendly name.
  static String getInheritedSourceName({
    required HttpRequest request,
    required List<RequestCollection> collections,
  }) {
    if (request.auth.type != AuthType.inherit) {
      return 'Request';
    }

    RequestCollection? parentCol;
    for (var col in collections) {
      if (col.requests.any((r) => r.id == request.id)) {
        parentCol = col;
        break;
      }
    }

    if (parentCol == null) {
      return 'Workspace';
    }

    return _getCollectionInheritedSourceName(
      collection: parentCol,
      collections: collections,
    );
  }

  static String _getCollectionInheritedSourceName({
    required RequestCollection collection,
    required List<RequestCollection> collections,
  }) {
    if (collection.auth.type != AuthType.inherit) {
      return 'Collection "${collection.name}"';
    }

    if (collection.parentId == null) {
      return 'Workspace';
    }

    RequestCollection? parentCol;
    try {
      parentCol = collections.firstWhere((c) => c.id == collection.parentId);
    } catch (_) {}

    if (parentCol == null) {
      return 'Workspace';
    }

    return _getCollectionInheritedSourceName(
      collection: parentCol,
      collections: collections,
    );
  }
}
