import 'package:flutter/material.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:fletch/theme/app_theme.dart';

class MethodBadge extends StatelessWidget {
  final HttpMethod method;
  final bool small;

  const MethodBadge({super.key, required this.method, this.small = false});

  Color get _color {
    switch (method) {
      case HttpMethod.get:
        return AppColors.methodGet;
      case HttpMethod.post:
        return AppColors.methodPost;
      case HttpMethod.put:
        return AppColors.methodPut;
      case HttpMethod.delete:
        return AppColors.methodDelete;
      case HttpMethod.patch:
        return AppColors.methodPatch;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 0 : 8,
        vertical: small ? 0 : 2,
      ),
      width: small ? 35 : null,
      alignment: small ? Alignment.centerLeft : Alignment.center,
      decoration: small
          ? null
          : BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _color.withValues(alpha: 0.2)),
            ),
      child: Text(
        method.value,
        style: AppTheme.codeStyle(
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.bold,
          color: _color,
        ),
      ),
    );
  }
}
