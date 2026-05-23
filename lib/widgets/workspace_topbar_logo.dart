import 'package:flutter/material.dart';
import 'package:fletch/services/navigation_service.dart';
import 'package:fletch/theme/app_colors.dart';

class WorkspaceTopBarLogo extends StatelessWidget {
  const WorkspaceTopBarLogo({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => NavigationService.goBack(),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text(
                'F',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HTTP Client',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                name,
                style: TextStyle(fontSize: 10, color: AppColors.slate500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
