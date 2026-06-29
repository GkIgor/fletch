import 'package:fletch/backend/scripting/models/visual_script.dart';
import 'package:fletch/backend/scripting/compiler/script_compiler.dart';

/// JIT Compilation Cache containing compiled scripts.
class JitCache {
  static final Map<String, CompiledScript> _cache = {};
  static final Map<String, DateTime> _timestamps = {};

  static CompiledScript getOrCreate(
    VisualScript script, {
    List<WorkspaceRequestRef>? availableRequests,
  }) {
    final cached = _cache[script.id];
    final lastModified = _timestamps[script.id];

    // Cache hit: only valid when no request refs are provided (pre-request scripts
    // with no workspace-request steps) OR when the timestamp has not changed.
    if (availableRequests == null &&
        cached != null &&
        lastModified != null &&
        !lastModified.isBefore(script.updatedAt)) {
      return cached;
    }

    // Compile and cache only when there are no dynamic request refs.
    final compiled = ScriptCompiler.compile(script, availableRequests: availableRequests);
    if (availableRequests == null) {
      _cache[script.id] = compiled;
      _timestamps[script.id] = script.updatedAt;
    }
    return compiled;
  }

  static void invalidate(String scriptId) {
    _cache.remove(scriptId);
    _timestamps.remove(scriptId);
  }

  static void clear() {
    _cache.clear();
    _timestamps.clear();
  }
}
