import 'package:flutter/material.dart';
import 'package:zomogoldapp/theme/app_theme.dart';

class ToastHelper {
  static void showWishlistToast(
      BuildContext context, {
        String message = "Item saved in your wishlist",
        bool isAdded = true,
      }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.background,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}