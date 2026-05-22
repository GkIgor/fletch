import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gk_http_client/core/app_config.dart';
import 'package:gk_http_client/models/workspace_models.dart';
import 'package:gk_http_client/providers/workspace_provider.dart';

void main() {
  late Directory tempDir;
  late String originalWorkspaceDir;

  setUp(() async {
    originalWorkspaceDir = AppConfig.workspaceDir;
    tempDir = await Directory.systemTemp.createTemp('workspace_provider_test_');
    AppConfig.workspaceDir = tempDir.path;
  });

  tearDown(() async {
    AppConfig.workspaceDir = originalWorkspaceDir;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('WorkspaceProvider environment management flow', () async {
    final provider = WorkspaceProvider();
    
    // 1. Initial State
    expect(provider.isManagingEnvironments, isFalse);
    expect(provider.currentWorkspace, isNull);

    // 2. Add Workspace
    final workspace = WorkspaceModel(name: 'Test Workspace');
    await provider.addWorkspace(workspace);
    provider.openWorkspace(workspace.id);

    expect(provider.currentWorkspace, isNotNull);
    expect(provider.currentWorkspace!.id, equals(workspace.id));
    expect(provider.isManagingEnvironments, isFalse);

    // 3. Managing environment setter
    provider.isManagingEnvironments = true;
    expect(provider.isManagingEnvironments, isTrue);

    // 4. Add Environment with Name and Description
    await provider.addEnvironmentWithNameAndDescription('Prod', 'Production Environment', 'shield');
    expect(provider.currentWorkspace!.environments.length, equals(2)); // Default + Prod
    
    final prodEnv = provider.currentWorkspace!.environments.firstWhere((e) => e.name == 'Prod');
    expect(prodEnv.description, equals('Production Environment'));
    expect(prodEnv.icon, equals('shield'));

    // 5. Update Environment Details
    await provider.updateEnvironmentDetails(prodEnv.id, 'Production', 'Updated Description', 'lock');
    expect(prodEnv.name, equals('Production'));
    expect(prodEnv.description, equals('Updated Description'));
    expect(prodEnv.icon, equals('lock'));

    // 6. Add or Update Variables (Text and Secret)
    final secretKeyText = WorkspaceSecretKey(value: 'https://api.prod.com', isSecret: false);
    final secretKeySecret = WorkspaceSecretKey(value: 'super-secret-token', isSecret: true);

    await provider.addOrUpdateVariable(prodEnv.id, 'API_URL', 'API_URL', secretKeyText);
    await provider.addOrUpdateVariable(prodEnv.id, 'API_KEY', 'API_KEY', secretKeySecret);

    expect(prodEnv.variables.containsKey('API_URL'), isTrue);
    expect(prodEnv.variables['API_URL']!.value, equals('https://api.prod.com'));
    expect(prodEnv.variables['API_URL']!.isSecret, isFalse);

    expect(prodEnv.variables.containsKey('API_KEY'), isTrue);
    expect(prodEnv.variables['API_KEY']!.value, equals('super-secret-token'));
    expect(prodEnv.variables['API_KEY']!.isSecret, isTrue);

    // 7. Update existing variable key/value
    final updatedSecretKey = WorkspaceSecretKey(value: 'new-token', isSecret: true);
    await provider.addOrUpdateVariable(prodEnv.id, 'API_KEY', 'API_TOKEN', updatedSecretKey);

    expect(prodEnv.variables.containsKey('API_KEY'), isFalse);
    expect(prodEnv.variables.containsKey('API_TOKEN'), isTrue);
    expect(prodEnv.variables['API_TOKEN']!.value, equals('new-token'));

    // 8. Remove Variable
    await provider.removeVariable(prodEnv.id, 'API_TOKEN');
    expect(prodEnv.variables.containsKey('API_TOKEN'), isFalse);
    expect(prodEnv.variables.containsKey('API_URL'), isTrue);

    // 9. Open Workspace resets managing environments mode
    provider.isManagingEnvironments = true;
    provider.openWorkspace(workspace.id);
    expect(provider.isManagingEnvironments, isFalse);
  });
}
