import 'package:flutter/material.dart';
import 'package:fletch/theme/app_colors.dart';

class CustomScrollbar extends StatelessWidget {
  final Widget child;
  final ScrollController controller;

  const CustomScrollbar({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
      controller: controller,
      thumbColor: AppColors.slate600,
      radius: const Radius.circular(10),
      thickness: 6,
      trackVisibility: false,
      thumbVisibility: true,
      interactive: true,
      child: child,
    );
  }
}
