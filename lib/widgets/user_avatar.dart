import 'package:flutter/material.dart';
import 'package:fletch/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.slate300,
      child: Text(
        _getInitials(name),
        style: TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length > 1) {
      return '${words.first[0]}${words.last[0]}';
    }
    return name[0];
  }
}
