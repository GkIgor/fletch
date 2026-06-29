import 'dart:io';

final replacementMap = {
  'package:fletch/backend/scripting/models/collection_model.dart': 'package:fletch/backend/collections/models/collection.dart',
  'package:fletch/backend/scripting/models/workspace_models.dart': 'package:fletch/backend/workspace/models/workspace.dart',
  'package:fletch/backend/scripting/models/http_request.dart': 'package:fletch/backend/requests/models/http_request.dart',
  'package:fletch/backend/scripting/models/http_response.dart': 'package:fletch/backend/requests/models/http_response.dart',
  'package:fletch/backend/scripting/models/http_method.dart': 'package:fletch/backend/requests/models/http_method.dart',
  'package:fletch/backend/scripting/models/http_auth.dart': 'package:fletch/backend/requests/models/http_auth.dart',
  'package:fletch/backend/scripting/models/runner_item_state.dart': 'package:fletch/backend/runner/models/runner_item_state.dart',
  
  'package:fletch/backend/scripting/services/http_service.dart': 'package:fletch/backend/requests/services/http_service.dart',
  'package:fletch/backend/scripting/execution/script_compiler.dart': 'package:fletch/backend/scripting/compiler/script_compiler.dart',
  'package:fletch/backend/scripting/execution/auth_resolver.dart': 'package:fletch/backend/requests/auth/auth_resolver.dart',
  'package:fletch/backend/scripting/compiler/script_execution_context.dart': 'package:fletch/backend/scripting/execution/script_execution_context.dart',
  'package:fletch/backend/scripting/compiler/script_executor.dart': 'package:fletch/backend/scripting/execution/script_executor.dart',
  'package:fletch/backend/scripting/backend/scripting/compiler/step_compiler_registry.dart': 'package:fletch/backend/scripting/compiler/step_compiler_registry.dart',
  'package:fletch/backend/scripting/execution/workspace_models.dart': 'package:fletch/backend/workspace/models/workspace.dart',
  'package:fletch/backend/scripting/execution/collection_model.dart': 'package:fletch/backend/collections/models/collection.dart',
  'package:fletch/backend/scripting/execution/http_auth.dart': 'package:fletch/backend/requests/models/http_auth.dart',
};

void main() {
  final libDir = Directory('lib');
  final testDir = Directory('test');

  processDirectory(libDir);
  processDirectory(testDir);
  print('Path fixes complete!');
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
  String content = file.readAsStringSync();
  bool changed = false;

  for (final entry in replacementMap.entries) {
    if (content.contains(entry.key)) {
      content = content.replaceAll(entry.key, entry.value);
      changed = true;
    }
  }

  if (changed) {
    file.writeAsStringSync(content);
    print('Fixed paths in: ${file.path}');
  }
}
