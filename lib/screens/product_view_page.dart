import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

import '../dao/product_dao.dart';
import '../models/price_calculator.dart';
import '../models/product_model.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProduct();
    incrementProductView();
  }

  Future<void> incrementProductView() async {
    try {
      await _productDao.recordView(widget.productId);
    } catch (e) {
      print("Error updating view count: $e");
    }
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
                    itemBuilder: (_, i) =>
                        Image.network(product!.images[i], fit: BoxFit.cover),
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
                          const Icon(
                            Icons.favorite_border,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.share_outlined,
                            color: Colors.black54,
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
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) => Container(
                        width: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey.shade100,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: product!.images.isNotEmpty
                              ? Image.network(
                                  product!.images[0],
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
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
