import 'package:flutter/material.dart';

import '../screens/cart_screen.dart';
import '../screens/wishlist_screen.dart';
import '../theme/app_theme.dart';

Widget actionCircleIcon({
  required IconData icon,
  VoidCallback? onTap,
  Color? backgroundColor,
  required BuildContext context,
}) {
  return InkWell(
    onTap: () async {
      if (icon == Icons.favorite_border) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WishlistScreen()),
        );
      } else if (icon == Icons.shopping_bag_outlined) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
      }
      if (onTap != null) {
        onTap();
      }
    },
    borderRadius: BorderRadius.circular(50),
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.textColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}
