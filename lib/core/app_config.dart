import 'dart:io';

class AppConfig {
  static const String _applicationName = 'fletch';
  static String? home = Platform.environment['HOME'];
  static String workspaceDir = '$home/.$_applicationName/workspaces';
  static String collectionsDir = '$home/.$_applicationName/collections';

  Future<void> initializeInfrastructure() async {
    if (home == null) {
      throw Exception('HOME environment variable is not set');
    }

    final workspaceDirectory = Directory(workspaceDir);
    await workspaceDirectory.create(recursive: true);

    final collectionsDirectory = Directory(collectionsDir);
    await collectionsDirectory.create(recursive: true);
  }
}
