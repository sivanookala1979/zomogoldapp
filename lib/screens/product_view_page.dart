import 'dart:convert';

import 'package:barcode/barcode.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zomogoldapp/models/wish_list_model.dart';
import 'package:zomogoldapp/screens/product_card.dart';
import 'package:zomogoldapp/screens/toast_helper.dart';

import '../dao/product_dao.dart';
import '../dao/wish_list_dao.dart';
import '../models/price_calculator.dart';
import '../models/product_model.dart';
import '../services/tsc_printer.dart';
import '../theme/app_theme.dart';
import 'full_screen_image.dart';

const Color primaryPurple = Color(0xFF7F55B5);

class ProductDetailsViewPage extends StatefulWidget {
  final String productId;

  const ProductDetailsViewPage({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailsViewPage> createState() =>
      _ProductDetailsViewPageState();
}

class _ProductDetailsViewPageState
    extends State<ProductDetailsViewPage> {
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

    if (!mounted) return;

    setState(() {
      _isInWishlist = exists;
    });
  }

  Future<void> incrementProductView() async {
    try {
      await _productDao.recordView(widget.productId);
    } catch (e) {
      debugPrint("Error updating view count: $e");
    }
  }

  String _getCategoryName(String categoryId) {
    if (_categoryList.isEmpty || categoryId.isEmpty) {
      return "Jewellery";
    }

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
    if (metal == "Select" || metal.isEmpty) {
      return 0.0;
    }

    final key = metal.trim().toUpperCase();

    if (_rateCache.containsKey(key)) {
      return _rateCache[key]!;
    }

    final rate = await _productDao.getLatestRateByType(key);

    _rateCache[key] = rate;

    return rate;
  }

  Future<void> _loadProduct() async {
    try {
      final fetchedProduct =
          await _productDao.getProductById(widget.productId);

      final rate = await _productDao.getLatestRateByType(
        fetchedProduct.metalName,
      );

      final calculatedMrp =
          PriceCalculator.calculateProductMRP(
        metalName: fetchedProduct.metalName,
        carats: fetchedProduct.carats,
        metalGrams: fetchedProduct.metalGrams,
        metalRate: rate,
        stoneWeight: fetchedProduct.stoneWeight,
        stoneCost: fetchedProduct.stoneCost,
        makingChargeValue: fetchedProduct.makingCharges,
        makingChargeType: "Flat",
      );

      final calculatedSellingPrice =
          PriceCalculator.calculateSellingPrice(
        mrp: calculatedMrp,
        discountPercent: fetchedProduct.discount,
      );

      if (!mounted) return;

      setState(() {
        product = fetchedProduct;
        metalRate = rate;
        mrp = calculatedMrp;
        sellingPrice = calculatedSellingPrice;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error loading product: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  QuillController _quillControllerFromJson(String json) {
    final delta = Delta.fromJson(jsonDecode(json));

    return QuillController(
      document: Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  Future<void> _printProductLabel() async {
    if (product == null) return;

    try {
      await TscPrinter.printProductLabel(product!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Print command sent successfully",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Printing failed: $e",
          ),
        ),
      );

      debugPrint("PRINT ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (product == null) {
      return const Scaffold(
        body: Center(
          child: Text("Product not found"),
        ),
      );
    }

    final grossWeight =
        product!.metalGrams + product!.stoneWeight;

    final purityText = switch (product!.carats) {
      14 => "585 G",
      18 => "750 G",
      20 => "833 G",
      22 => "916 G",
      23 => "958 G",
      24 => "999 G",
      _ => "${product!.carats} G",
    };

    final productNameText = product!.productName.trim().isNotEmpty
        ? product!.productName.trim().toUpperCase()
        : _getCategoryName(product!.categoryId).toUpperCase();

    final designText = product!.designCode.trim().isNotEmpty
        ? "NK / ${product!.designCode.trim()}"
        : "NK";

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
            icon: const Icon(
              Icons.search,
              color: Colors.black,
            ),
            onPressed: () {},
          ),

          IconButton(
            icon: const Icon(
              Icons.favorite_border,
              color: Colors.black,
            ),
            onPressed: () {},
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // --------------------------------------------------
            // PRODUCT IMAGES
            // --------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),

                child: SizedBox(
                  height: 300,

                  child: PageView.builder(
                    itemCount: product!.images.length,

                    onPageChanged: (i) {
                      setState(() {
                        _currentPage = i;
                      });
                    },

                    itemBuilder: (_, i) =>
                        GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FullScreenImagePage(
                              images: product!.images,
                              initialIndex: i,
                              heroTagPrefix:
                                  "productImage_${product!.productId}",
                            ),
                          ),
                        );
                      },

                      child: Hero(
                        tag:
                            "productImage_${product!.productId}_$i",

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

            // --------------------------------------------------
            // IMAGE INDICATOR
            // --------------------------------------------------

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: List.generate(
                product!.images.length,

                (i) => Container(
                  margin:
                      const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),

                  width:
                      _currentPage == i ? 24 : 8,

                  height: 8,

                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? primaryPurple
                        : Colors.grey.shade300,

                    borderRadius:
                        BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // PRODUCT INFORMATION
            // --------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,

                    children: [

                      Text(
                        productNameText,

                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),

                      Row(
                        children: [

                          // WISHLIST
                          MouseRegion(
                            cursor:
                                SystemMouseCursors.click,

                            child: GestureDetector(
                              onTap: () async {
                                final user =
                                    FirebaseAuth.instance
                                        .currentUser;

                                if (user == null) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please log in first",
                                      ),
                                    ),
                                  );

                                  return;
                                }

                                final currentUserId =
                                    user.uid;

                                final wishlistDao =
                                    WishlistDao();

                                if (_isInWishlist) {
                                  await wishlistDao
                                      .removeProduct(
                                    currentUserId,
                                    product!.productId,
                                  );

                                  if (!mounted) return;

                                  setState(() {
                                    _isInWishlist = false;
                                  });

                                  ToastHelper
                                      .showWishlistToast(
                                    context,
                                    message:
                                        "Removed from wishlist",
                                    isAdded: false,
                                  );
                                } else {
                                  final wishlistId =
                                      await wishlistDao
                                          .generateNextWishlistId();

                                  final wishlistItem =
                                      WishlistModel(
                                    wishlistId:
                                        wishlistId.toString(),
                                    userId:
                                        currentUserId,
                                    productId:
                                        product!.productId,
                                    createdAt:
                                        DateTime.now(),
                                  );

                                  await wishlistDao
                                      .addProduct(
                                    wishlistItem,
                                  );

                                  if (!mounted) return;

                                  setState(() {
                                    _isInWishlist = true;
                                  });

                                  ToastHelper
                                      .showWishlistToast(
                                    context,
                                    message:
                                        "Added to wishlist",
                                    isAdded: true,
                                  );
                                }
                              },

                              child: Icon(
                                _isInWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_border,

                                color: _isInWishlist
                                    ? const Color(
                                        0xFF9C27B0,
                                      )
                                    : Colors.black54,
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // SHARE
                          MouseRegion(
                            cursor:
                                SystemMouseCursors.click,

                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text("Share clicked"),
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

                  // --------------------------------------------------
                  // PRICE
                  // --------------------------------------------------

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.baseline,

                    textBaseline:
                        TextBaseline.alphabetic,

                    children: [

                      Text(
                        "₹ ${mrp.toStringAsFixed(2)}",

                        style: const TextStyle(
                          fontSize: 16,
                          decoration:
                              TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        "₹ ${sellingPrice.toStringAsFixed(2)}",

                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const Text(
                    "MRP Incl. of all taxes",

                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --------------------------------------------------
                  // PRODUCT LABEL
                  // --------------------------------------------------

                  const Text(
                    "Product Label",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Product ID
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Product ID",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          product!.productId,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // --------------------------------------------------
                  // LABEL PREVIEW
                  // --------------------------------------------------

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AspectRatio(
                      aspectRatio: 5 / 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.black54,
                          ),
                        ),
                        child: Row(
                          children: [
                            // --------------------------------------------------
                            // FIRST HALF: QR + ORNAMENT + BASIC LABEL DETAILS
                            // --------------------------------------------------
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Row(
                                  children: [
                                    // QR + PRODUCT NAME BELOW QR
                                    SizedBox(
                                      width: 70,
                                      height: double.infinity,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 1,
                                              ),
                                              child: BarcodeWidget(
                                                barcode: Barcode.qrCode(),
                                                data: product!.productId,
                                                drawText: false,
                                                padding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              productNameText,
                                              maxLines: 1,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 5),

                                    // BRAND + PC.1 / 916 G / NK / OCH
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "ZOMO GOLD",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              "PC.${product!.pieceCount}",
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              purityText,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              designText,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "OCH: ${product!.otherCharges.toStringAsFixed(0)}",
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // CENTER FOLD LINE
                            Container(
                              width: 1,
                              height: double.infinity,
                              color: Colors.grey.shade400,
                            ),

                            // --------------------------------------------------
                            // SECOND HALF: TWO COLUMNS
                            // --------------------------------------------------
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 3,
                                ),
                                child: Row(
                                  children: [
                                    // GW / NW / AD
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "GW: ${grossWeight.toStringAsFixed(2)} g",
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "NW: ${product!.metalGrams.toStringAsFixed(2)} g",
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "AD: ${product!.americanDiamondWeight.toStringAsFixed(2)} / ${product!.americanDiamondCount}",
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    Container(
                                      width: 1,
                                      height: double.infinity,
                                      color: Colors.grey.shade300,
                                    ),

                                    const SizedBox(width: 5),

                                    // KUN / ST
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "KUN: ${product!.kundanWeight.toStringAsFixed(2)} / ${product!.kundanCount}",
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "ST: ${product!.stoneWeight.toStringAsFixed(2)} / ${product!.stoneCount}",
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const SizedBox(height: 12),

                  // --------------------------------------------------
                  // SMALL PRINT BUTTON
                  // --------------------------------------------------

                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 58,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _printProductLabel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Icon(
                          Icons.print,
                          size: 21,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --------------------------------------------------
                  // PRODUCT CHIPS
                  // --------------------------------------------------

                  Row(
                    children: [

                      _infoChip(
                        "${product!.carats} karat",
                      ),

                      const SizedBox(width: 12),

                      _infoChip(
                        "${product!.makingCharges}% Making charges",
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --------------------------------------------------
                  // PRODUCT DETAILS
                  // --------------------------------------------------

                  _expandableSection(
                    "Product details",
                    product!.productInformation,
                  ),

                  const SizedBox(height: 12),

                  _expandableSection(
                    "Specifications",
                    product!.specifications,
                  ),

                  const SizedBox(height: 30),

                  // --------------------------------------------------
                  // RELATED PRODUCTS
                  // --------------------------------------------------

                  const Text(
                    "You May Also Like",

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 280,

                    child:
                        StreamBuilder<List<ProductModel>>(
                      stream:
                          _productDao.getProductsByMetal(
                        product!.metalName,
                        widget.productId,
                      ),

                      builder:
                          (context, snapshot) {

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child:
                                CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                            child:
                                Text(
                              "No related products",
                            ),
                          );
                        }

                        final relatedProducts =
                            snapshot.data!;

                        return ListView.separated(
                          scrollDirection:
                              Axis.horizontal,

                          itemCount:
                              relatedProducts.length,

                          separatorBuilder:
                              (_, __) =>
                                  const SizedBox(
                            width: 16,
                          ),

                          itemBuilder:
                              (context, index) {

                            final item =
                                relatedProducts[index];

                            return SizedBox(
                              width: 200,

                              child:
                                  FutureBuilder<double>(
                                future:
                                    _getRate(
                                  item.metalName,
                                ),

                                builder:
                                    (
                                  context,
                                  rateSnapshot,
                                ) {

                                  return MouseRegion(
                                    cursor:
                                        SystemMouseCursors
                                            .click,

                                    child:
                                        GestureDetector(
                                      onTap: () {
                                        Navigator
                                            .pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProductDetailsViewPage(
                                              productId:
                                                  item.productId,
                                            ),
                                          ),
                                        );
                                      },

                                      child:
                                          ProductCard(
                                        product: item,
                                        ratePerGram:
                                            rateSnapshot
                                                    .data ??
                                                0.0,
                                        categoryName:
                                            item.productName
                                                    .isNotEmpty
                                                ? item
                                                    .productName
                                                : _getCategoryName(
                                                    item
                                                        .categoryId,
                                                  ),
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

      // --------------------------------------------------
      // BOTTOM ORDER BUTTONS
      // --------------------------------------------------

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.08),

              blurRadius: 10,

              offset:
                  const Offset(0, -4),
            ),
          ],
        ),

        child: Row(
          children: [

            Expanded(
              child: ElevatedButton.icon(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF37BC69),

                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 20,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),

                  elevation: 3,
                ),

                onPressed:
                    _orderOnWhatsapp,

                icon: const Icon(
                  Icons.chat,
                  color: Colors.white,
                ),

                label: const Text(
                  "Order on Whatsapp",

                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: ElevatedButton.icon(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      primaryPurple,

                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 20,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),

                  elevation: 3,
                ),

                onPressed:
                    _callToOrder,

                icon: const Icon(
                  Icons.phone,
                  color: Colors.white,
                ),

                label: const Text(
                  "Call to Order",

                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w600,
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
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(12),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.05),

            blurRadius: 10,

            offset:
                const Offset(0, 4),
          ),
        ],

        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [

          const CircleAvatar(
            radius: 10,

            backgroundColor:
                Color(0xFFFFD700),

            child: Icon(
              Icons.circle,
              size: 12,
              color: Colors.orange,
            ),
          ),

          const SizedBox(width: 8),

          Text(
            text,

            style: const TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callToOrder() async {
    const phoneNumber =
        "tel:+918790343501";

    final Uri phoneUri =
        Uri.parse(phoneNumber);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      debugPrint(
        "Could not launch phone dialer",
      );
    }
  }

  Future<void> _orderOnWhatsapp() async {
    const phoneNumber =
        "918790343501";

    final productLink =
        "https://zomogold.com/product/${product!.productId}";

    final message = """
💎 ${product!.productName}
💰 ₹${sellingPrice.toStringAsFixed(0)}

View Product:
$productLink
""";

    final Uri whatsappUri =
        Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
    );

    await launchUrl(
      whatsappUri,
      mode:
          LaunchMode.externalApplication,
    );
  }

  Widget _expandableSection(
    String title,
    String quillJson,
  ) {
    if (quillJson.isEmpty) {
      return const SizedBox();
    }

    final controller =
        _quillControllerFromJson(
      quillJson,
    );

    return ExpansionTile(
      title: Text(
        title,
        style:
            const TextStyle(
          fontWeight:
              FontWeight.w600,
        ),
      ),

      childrenPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),

      children: [
        QuillEditor(
          controller:
              controller,

          scrollController:
              ScrollController(),

          focusNode:
              FocusNode(),
        ),
      ],
    );
  }
}