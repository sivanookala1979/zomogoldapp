import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:zomogoldapp/models/wish_list_model.dart';
import 'package:zomogoldapp/screens/product_card.dart';
import 'package:zomogoldapp/screens/toast_helper.dart';

import '../dao/product_dao.dart';
import '../dao/wish_list_dao.dart';
import '../models/price_calculator.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import 'full_screen_image.dart';

const Color primaryPurple = Color(0xFF7F55B5);

class ProductDetailsViewPage extends StatefulWidget {
  final String productId;

  const ProductDetailsViewPage({super.key, required this.productId});

  @override
  State<ProductDetailsViewPage> createState() => _ProductDetailsViewPageState();
}

class _ProductDetailsViewPageState extends State<ProductDetailsViewPage> {
  final ProductDao _productDao = ProductDao();
  ProductModel? product;
  double metalRate = 0;
  double mrp = 0;
  double sellingPrice = 0;
  int _currentPage = 0;
  bool loading = true;
  final Map<String, double> _rateCache = {};
  List<Map<String, String>> _categoryList = [];
  bool _isInWishlist = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _checkWishlist();
    incrementProductView();
  }

  Future<void> _checkWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final wishlistDao = WishlistDao();
    final exists = await wishlistDao.isProductInWishlist(
      user.uid,
      widget.productId,
    );

    setState(() {
      _isInWishlist = exists;
    });
  }

  Future<void> incrementProductView() async {
    try {
      await _productDao.recordView(widget.productId);
    } catch (e) {
      print("Error updating view count: $e");
    }
  }

  String _getCategoryName(String categoryId) {
    if (_categoryList.isEmpty || categoryId.isEmpty) return "Jewellery";
    try {
      final category = _categoryList.firstWhere(
        (cat) => cat['id'] == categoryId,
        orElse: () => {'name': 'Jewellery'},
      );
      return category['name']!;
    } catch (e) {
      return "Jewellery";
    }
  }

  Future<double> _getRate(String metal) async {
    if (metal == "Select" || metal.isEmpty) return 0.0;
    String key = metal.trim().toUpperCase();

    if (_rateCache.containsKey(key)) return _rateCache[key]!;

    final rate = await _productDao.getLatestRateByType(key);

    _rateCache[key] = rate;
    return rate;
  }

  Future<void> _loadProduct() async {
    try {
      final fetchedProduct = await _productDao.getProductById(widget.productId);
      final rate = await _productDao.getLatestRateByType(
        fetchedProduct.metalName,
      );

      final calculatedMrp = PriceCalculator.calculateProductMRP(
        metalName: fetchedProduct.metalName,
        carats: fetchedProduct.carats,
        metalGrams: fetchedProduct.metalGrams,
        metalRate: rate,
        stoneWeight: fetchedProduct.stoneWeight,
        stoneCost: fetchedProduct.stoneCost,
        makingChargeValue: fetchedProduct.makingCharges,
        makingChargeType: "Flat",
      );

      final calculatedSellingPrice = PriceCalculator.calculateSellingPrice(
        mrp: calculatedMrp,
        discountPercent: fetchedProduct.discount,
      );

      setState(() {
        product = fetchedProduct;
        metalRate = rate;
        mrp = calculatedMrp;
        sellingPrice = calculatedSellingPrice;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error loading product: $e");
      setState(() => loading = false);
    }
  }

  QuillController _quillControllerFromJson(String json) {
    final delta = Delta.fromJson(jsonDecode(json));
    return QuillController(
      document: Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (product == null)
      return const Scaffold(body: Center(child: Text("Product not found")));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 300,
                  child: PageView.builder(
                    itemCount: product!.images.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImagePage(
                              images: product!.images,
                              initialIndex: i,
                              heroTagPrefix:
                                  "productImage_${product!.productId}",
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: "productImage_${product!.productId}_$i",
                        child: Image.network(
                          product!.images[i],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                product!.images.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? primaryPurple
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product!.metalName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
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

                                final currentUserId = user.uid;
                                final wishlistDao = WishlistDao();
                                if (_isInWishlist) {
                                  await wishlistDao.removeProduct(
                                    currentUserId,
                                    product!.productId,
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
                                    productId: product!.productId,
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
                              child: Icon(
                                _isInWishlist ? Icons.favorite : Icons.favorite_border,
                                color: _isInWishlist ? Color(0xFF9C27B0) : Colors.black54,
                              )
                            ),
                          ),
                          const SizedBox(width: 16),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Share clicked"),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.share_outlined,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "₹ ${mrp.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "₹ ${sellingPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const Text(
                    "MRP Incl. of all taxes",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      _infoChip("${product!.carats} karat"),
                      const SizedBox(width: 12),
                      _infoChip("${product!.makingCharges}% Making charges"),
                    ],
                  ),

                  const SizedBox(height: 30),

                  _expandableSection(
                    "Product details",
                    product!.productInformation,
                  ),
                  const SizedBox(height: 12),
                  _expandableSection("Specifications", product!.specifications),

                  const SizedBox(height: 30),

                  const Text(
                    "You May Also Like",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 280,
                    child: StreamBuilder<List<ProductModel>>(
                      stream: _productDao.getProductsByMetal(
                        product!.metalName,
                        widget.productId,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text("No related products"),
                          );
                        }

                        final relatedProducts = snapshot.data!;

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: relatedProducts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final item = relatedProducts[index];

                            return SizedBox(
                              width: 200,
                              child: FutureBuilder<double>(
                                future: _getRate(item.metalName),
                                builder: (context, rateSnapshot) {
                                  return MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProductDetailsViewPage(
                                                  productId: item.productId,
                                                ),
                                          ),
                                        );
                                      },
                                      child: ProductCard(
                                        product: item,
                                        ratePerGram: rateSnapshot.data ?? 0.0,
                                        categoryName:
                                            (item.productName.isNotEmpty)
                                            ? item.productName
                                            : _getCategoryName(item.categoryId),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF37BC69),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
                onPressed: () {
                  // TODO: Add WhatsApp logic
                },
                icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text(
                  "Order on Whatsapp",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
                onPressed: () {
                  // TODO: Add call logic
                },
                icon: const Icon(Icons.phone, color: Colors.white),
                label: const Text(
                  "Call to Order",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 10,
            backgroundColor: Color(0xFFFFD700),
            child: Icon(Icons.circle, size: 12, color: Colors.orange),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _expandableSection(String title, String quillJson) {
    if (quillJson.isEmpty) return const SizedBox();

    final controller = _quillControllerFromJson(quillJson);

    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        QuillEditor(
          controller: controller,
          scrollController: ScrollController(),
          focusNode: FocusNode(),
        ),
      ],
    );
  }
}
