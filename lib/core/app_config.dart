import 'dart:io';

class AppConfig {
  static const String flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  static String? home = Platform.environment['HOME'];

  static String get _applicationName {
    switch (flavor) {
      case 'prod':
        return 'fletch';
      case 'staging':
        return 'fletch_staging';
      case 'dev':
      default:
        return 'fletch_dev';
    }
  }

  static String get appDisplayName {
    switch (flavor) {
      case 'prod':
        return 'Fletch';
      case 'staging':
        return 'Fletch Staging';
      case 'dev':
      default:
        return 'Fletch Dev';
    }
  }

  static String? _workspaceDir;
  static String? _collectionsDir;

  static String get workspaceDir => _workspaceDir ?? '$home/.$_applicationName/workspaces';
  static set workspaceDir(String? value) => _workspaceDir = value;

  static String get collectionsDir => _collectionsDir ?? '$home/.$_applicationName/collections';
  static set collectionsDir(String? value) => _collectionsDir = value;

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
