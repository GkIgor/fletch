import 'package:flutter/material.dart';

enum AppRoute { home, workspace, folders }

class NavigationService {
  static final ValueNotifier<AppRoute> currentRoute = ValueNotifier(
    AppRoute.home,
  );

  static void navigateTo(AppRoute route) {
    switch (route) {
      case AppRoute.home:
        goBack();
        break;
      case AppRoute.workspace:
        currentRoute.value = route;
        break;
      case AppRoute.folders:
        currentRoute.value = route;
        break;
    }
  }

  static void goBack() {
    currentRoute.value = AppRoute.home;
  }
}
