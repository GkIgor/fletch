import 'package:flutter/material.dart';
import 'package:gk_http_client/providers/user_provider.dart';
import 'package:gk_http_client/providers/workspace_provider.dart';
import 'package:provider/provider.dart';
import 'package:gk_http_client/core/app_config.dart';
import 'package:gk_http_client/screens/home_screen.dart';
import 'package:gk_http_client/screens/workspace_screen.dart';
import 'package:gk_http_client/services/navigation_service.dart';
import 'package:gk_http_client/providers/theme_provider.dart';
import 'package:gk_http_client/providers/request_provider.dart';
import 'package:gk_http_client/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig appConfig = AppConfig();
  appConfig.initializeInfrastructure();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => RequestProvider(),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
        ChangeNotifierProvider(
          create: (_) => WorkspaceProvider()..loadWorkspaces(),
        ),
      ],
      child: const Application(),
    ),
  );
}

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final Map<AppRoute, Widget Function(BuildContext)> routes = {
      AppRoute.home: (context) => const HomeScreen(),
      AppRoute.workspace: (context) {
        return WorkspaceScreen();
      },
    };

    return MaterialApp(
      title: 'GK HTTP Client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.themeMode,
      home: ValueListenableBuilder(
        valueListenable: NavigationService.currentRoute,
        builder: (context, route, _) {
          final builder = routes[route];
          return builder != null ? builder(context) : const SizedBox();
        },
      ),
    );
  }
}
