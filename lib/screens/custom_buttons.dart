import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

Widget actionCircleIcon({
  required IconData icon,
  required VoidCallback onTap,
  Color? backgroundColor,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(50),
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.textColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    ),
  );
}