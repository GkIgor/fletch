import 'dart:io';
import 'package:path/path.dart' as p;

final packageMap = {
  'package:fletch/models/collection_model.dart': 'package:fletch/backend/collections/models/collection.dart',
  'package:fletch/models/workspace_models.dart': 'package:fletch/backend/workspace/models/workspace.dart',
  'package:fletch/models/http_request.dart': 'package:fletch/backend/requests/models/http_request.dart',
  'package:fletch/models/http_response.dart': 'package:fletch/backend/requests/models/http_response.dart',
  'package:fletch/models/http_method.dart': 'package:fletch/backend/requests/models/http_method.dart',
  'package:fletch/models/http_auth.dart': 'package:fletch/backend/requests/models/http_auth.dart',
  'package:fletch/models/runner_item_state.dart': 'package:fletch/backend/runner/models/runner_item_state.dart',
  'package:fletch/models/visual_script.dart': 'package:fletch/backend/scripting/models/visual_script.dart',
  
  'package:fletch/repository/collection_repository.dart': 'package:fletch/backend/collections/repository/collection_repository.dart',
  'package:fletch/repository/workspace_repository.dart': 'package:fletch/backend/workspace/repository/workspace_repository.dart',
  
  'package:fletch/services/workspace_service.dart': 'package:fletch/backend/workspace/services/workspace_service.dart',
  'package:fletch/services/http_service.dart': 'package:fletch/backend/requests/services/http_service.dart',
  
  'package:fletch/utils/auth_resolver.dart': 'package:fletch/backend/requests/auth/auth_resolver.dart',
  'package:fletch/utils/oauth1_helper.dart': 'package:fletch/backend/requests/auth/oauth1_helper.dart',
  'package:fletch/utils/script_compiler.dart': 'package:fletch/backend/scripting/compiler/script_compiler.dart',
  'package:fletch/utils/compiled_script.dart': 'package:fletch/backend/scripting/compiler/compiled_script.dart',
  'package:fletch/utils/jit_cache.dart': 'package:fletch/backend/scripting/compiler/jit_cache.dart',
  'package:fletch/utils/graph_validator.dart': 'package:fletch/backend/scripting/compiler/graph_validator.dart',
  'package:fletch/utils/script_executor.dart': 'package:fletch/backend/scripting/execution/script_executor.dart',
  'package:fletch/utils/script_execution_context.dart': 'package:fletch/backend/scripting/execution/script_execution_context.dart',
  'package:fletch/utils/utils.dart': 'package:fletch/core/utils/security_utils.dart',
};

void main() {
  final libDir = Directory('lib');
  final testDir = Directory('test');

  processDirectory(libDir);
  processDirectory(testDir);
  print('Import update complete!');
}

void processDirectory(Directory dir) {
  if (!dir.existsSync()) return;

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      processFile(entity);
    }
  }
}

void processFile(File file) {
  final content = file.readAsStringSync();
  final lines = content.split('\n');
  bool changed = false;

  final filePath = file.path;
  final fileDir = p.dirname(filePath);

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final importMatch = RegExp(r'^(import|export)\s+[\x27\x22]([^\x27\x22]+)[\x27\x22](.*)$').firstMatch(line);
    if (importMatch != null) {
      final keyword = importMatch.group(1)!;
      var target = importMatch.group(2)!;
      final rest = importMatch.group(3)!;

      // Skip dart: or package: imports of other packages
      if (target.startsWith('dart:') || (target.startsWith('package:') && !target.startsWith('package:fletch/'))) {
        continue;
      }

      // Convert relative imports to package:fletch imports
      if (!target.startsWith('package:')) {
        // Resolve absolute path from fileDir
        final absPath = p.normalize(p.join(fileDir, target));
        if (absPath.startsWith('lib/')) {
          final relativeToLib = absPath.substring(4);
          target = 'package:fletch/$relativeToLib';
        } else if (absPath.startsWith('test/')) {
          // Keep test relative imports as relative, or resolve to package? 
          // Usually test-to-test relative imports can stay, but if it imports lib, it should be package.
          // Let's resolve anyway if it's pointing to lib.
          final relativeToProject = p.normalize(p.join(fileDir, target));
          if (relativeToProject.startsWith('lib/')) {
            target = 'package:fletch/${relativeToProject.substring(4)}';
          }
        }
      }

      // Apply mapping for exact matches
      var newTarget = target;
      if (packageMap.containsKey(target)) {
        newTarget = packageMap[target]!;
      } else if (target.startsWith('package:fletch/models/visual_steps/')) {
        newTarget = target.replaceFirst('package:fletch/models/visual_steps/', 'package:fletch/backend/scripting/models/visual_steps/');
      } else if (target.startsWith('package:fletch/utils/compiled_steps/')) {
        newTarget = target.replaceFirst('package:fletch/utils/compiled_steps/', 'package:fletch/backend/scripting/compiler/compiled_steps/');
      } else if (target.startsWith('package:fletch/utils/converters/')) {
        newTarget = target.replaceFirst('package:fletch/utils/converters/', 'package:fletch/backend/collections/converters/');
      }

      if (newTarget != importMatch.group(2)!) {
        lines[i] = "$keyword '$newTarget'$rest";
        changed = true;
      }
    }
  }

  if (changed) {
    file.writeAsStringSync(lines.join('\n'));
    print('Updated imports in: ${file.path}');
  }
}
