import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zomogoldapp/dao/product_dao.dart';
import 'package:zomogoldapp/dao/wish_list_dao.dart';
import 'package:zomogoldapp/screens/product_card.dart';

import '../models/product_model.dart';
import 'category_service.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final ProductDao _productDao = ProductDao();
  final Map<String, double> _rateCache = {};

  Future<List<ProductModel>> fetchWishlistProducts() async {
    final firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    final wishlistDao = WishlistDao();

    final wishlistItems = await wishlistDao.getWishlistForUser(user!.uid).first;

    final productIds = wishlistItems.map((item) => item.productId).toList();

    if (productIds.isEmpty) return [];

    final productSnapshot = await firestore
        .collection('Products')
        .where('productId', whereIn: productIds)
        .get();

    return productSnapshot.docs
        .map((doc) => ProductModel.fromSnapshot(doc))
        .toList();
  }

  Future<double> _getRate(String metal) async {
    if (metal == "Select" || metal.isEmpty) return 0.0;

    String key = metal.trim().toUpperCase();

    if (_rateCache.containsKey(key)) return _rateCache[key]!;

    final rate = await _productDao.getLatestRateByType(key);

    _rateCache[key] = rate;
    return rate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                height: 38,
                width: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFA594D0),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<ProductModel>>(
        future: fetchWishlistProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Your saved or favorite items will appear here.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final products = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = MediaQuery.of(context).size.width;
              bool isMobile = screenWidth < 600;

              return GridView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 24,
                  vertical: 10,
                ),
                itemCount: products.length,
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: isMobile ? screenWidth / 2 : 280,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isMobile ? 0.68 : 0.80,
                ),
                itemBuilder: (context, index) {
                  final product = products[index];

                  return FutureBuilder<double>(
                    future: _getRate(product.metalName),
                    builder: (context, rateSnapshot) {
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: ProductCard(
                          product: product,
                          ratePerGram: rateSnapshot.data ?? 0.0,
                          categoryName: (product.productName.isNotEmpty)
                              ? product.productName
                              : CategoryService().getCategoryName(
                                  product.categoryId,
                                ),
                          isFromWishlist: true,
                          onRemove: () {
                            setState(() {});
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
