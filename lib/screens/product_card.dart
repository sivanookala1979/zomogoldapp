import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zomogoldapp/screens/product_view_page.dart';
import '../models/price_calculator.dart';
import '../models/product_model.dart';
import '../dao/wish_list_dao.dart';
import '../models/wish_list_model.dart';
import '../screens/toast_helper.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final double ratePerGram;
  final String categoryName;

  const ProductCard({
    super.key,
    required this.product,
    required this.ratePerGram,
    required this.categoryName,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isInWishlist = false;

  @override
  void initState() {
    super.initState();
    _checkWishlist();
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
                              : Colors
                                    .grey[600],
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
          ],
        ),
      ),
    );
  }
}
