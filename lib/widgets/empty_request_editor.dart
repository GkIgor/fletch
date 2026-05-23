import 'package:flutter/material.dart';
import 'package:fletch/theme/app_colors.dart';

class EmptyRequestEditor extends StatelessWidget {
  const EmptyRequestEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt_rounded, size: 64, color: AppColors.slate300),
            const SizedBox(height: 16),
            Text(
              'Select a request to start',
              style: TextStyle(
                color: AppColors.slate400,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
