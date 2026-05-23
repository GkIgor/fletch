import 'package:flutter/material.dart';
import 'package:fletch/providers/theme_provider.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
        size: 20,
      ),
      onPressed: () => themeProvider.toggleTheme(),
      tooltip: 'Toggle Theme',
    );
  }
}
