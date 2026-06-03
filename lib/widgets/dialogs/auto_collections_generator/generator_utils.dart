import 'package:flutter/material.dart';
import 'package:fletch/theme/app_colors.dart';

Color hexToColor(String hex) {
  var cleanHex = hex.replaceAll('#', '');
  if (cleanHex.length == 6) {
    cleanHex = 'FF$cleanHex';
  }
  return Color(int.parse(cleanHex, radix: 16));
}

Color getMethodColor(String method) {
  switch (method.toUpperCase()) {
    case 'GET':
      return AppColors.methodGet;
    case 'POST':
      return AppColors.methodPost;
    case 'PUT':
      return AppColors.methodPut;
    case 'DELETE':
      return AppColors.methodDelete;
    case 'PATCH':
      return AppColors.methodPatch;
    default:
      return AppColors.methodGet;
  }
}
