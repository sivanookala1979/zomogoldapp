import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zomogoldapp/screens/product_view_page.dart';

import '../dao/wish_list_dao.dart';
import '../models/price_calculator.dart';
import '../models/product_model.dart';
import '../models/wish_list_model.dart';
import '../screens/toast_helper.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final double ratePerGram;
  final String categoryName;
  final bool isFromWishlist;
  final VoidCallback? onRemove;

  const ProductCard({
    super.key,
    required this.product,
    required this.ratePerGram,
    required this.categoryName,
    this.isFromWishlist = false,
    this.onRemove,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isInWishlist = false;

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.productId != widget.product.productId) {
      _checkWishlist();
    } else {
      _checkWishlist();
    }
  }

  Future<void> _checkWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final wishlistDao = WishlistDao();
    final exists = await wishlistDao.isProductInWishlist(
      user.uid,
      widget.product.productId,
    );
    setState(() => _isInWishlist = exists);
  }

  @override
  Widget build(BuildContext context) {
    final mrp = PriceCalculator.calculateProductMRP(
      metalName: widget.product.metalName,
      carats: widget.product.carats,
      metalGrams: widget.product.metalGrams,
      metalRate: widget.ratePerGram,
      stoneWeight: widget.product.stoneWeight,
      stoneCost: widget.product.stoneCost,
      makingChargeValue: widget.product.makingCharges,
      makingChargeType: "Flat",
    );

    final sellingPrice = PriceCalculator.calculateSellingPrice(
      mrp: mrp,
      discountPercent: widget.product.discount,
    );
    void _showDeleteConfirmation(BuildContext context) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Remove from wishlist?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Are you sure to delete this product from wishlist?",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);

                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            await WishlistDao().removeProduct(
                              user.uid,
                              widget.product.productId,
                            );
                            if (!mounted) return;
                            if (widget.onRemove != null) {
                              widget.onRemove!();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Remove",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ProductDetailsViewPage(productId: widget.product.productId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    child: widget.product.images.isNotEmpty
                        ? Image.network(
                            widget.product.images.first,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 40,
                            ),
                          ),
                  ),
                  if (!widget.isFromWishlist)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please log in first"),
                              ),
                            );
                            return;
                          }

                          final wishlistDao = WishlistDao();
                          final currentUserId = user.uid;

                          if (_isInWishlist) {
                            await wishlistDao.removeProduct(
                              currentUserId,
                              widget.product.productId,
                            );
                            setState(() => _isInWishlist = false);
                            ToastHelper.showWishlistToast(
                              context,
                              message: "Removed from wishlist",
                              isAdded: false,
                            );
                          } else {
                            final wishlistId = await wishlistDao
                                .generateNextWishlistId();
                            final wishlistItem = WishlistModel(
                              wishlistId: wishlistId.toString(),
                              userId: currentUserId,
                              productId: widget.product.productId,
                              createdAt: DateTime.now(),
                            );
                            await wishlistDao.addProduct(wishlistItem);
                            setState(() => _isInWishlist = true);
                            ToastHelper.showWishlistToast(
                              context,
                              message: "Added to wishlist",
                              isAdded: true,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isInWishlist
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isInWishlist
                                ? Color(0xFF9C27B0)
                                : Colors.grey[600],
                            size: 23,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFFFF), Color(0x806750A4)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹ ${sellingPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹ ${mrp.toStringAsFixed(0)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isFromWishlist)
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
                child: Row(
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.black54,
                        size: 24,
                      ),
                      onPressed: () => _showDeleteConfirmation(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Add to Bag",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
