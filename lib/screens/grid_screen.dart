import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../dao/product_dao.dart';
import '../models/product_model.dart';
import 'filter_screen.dart';
import 'product_card.dart';

class GridScreen extends StatefulWidget {
  const GridScreen({super.key});

  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  final ProductDao _productDao = ProductDao();
  final ScrollController _scrollController = ScrollController();

  final List<ProductModel> _products = [];
  final Map<String, double> _rateCache = {};

  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('Products')
          .orderBy('createdTimestamp', descending: true)
          .limit(15);

      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snap = await query.get();

      if (snap.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
      } else {
        if (snap.docs.length < 15) _hasMore = false;

        _lastDoc = snap.docs.last;
        final newProducts = snap.docs
            .map((e) => ProductModel.fromSnapshot(e))
            .toList();

        setState(() {
          _products.addAll(newProducts);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching products: $e");
      setState(() => _isLoading = false);
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

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  "Sort By",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              _buildSortOption("New Arrivals", true),
              _buildSortOption("Popular", false),
              _buildSortOption("Low to high price", false),
              _buildSortOption("High to low price", false),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title, bool isSelected) {
    const Color themePurple = Color(0xFF6B52A1);

    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? themePurple : Colors.grey,
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSortFilterBar() {
    const Color themePurple = Color(0xFF6B52A1);
    const Color borderColor = Color(0xFFE5E0F0);
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderColor, width: 1.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showSortBottomSheet(context),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort_rounded, color: themePurple, size: 22),
                    const SizedBox(width: 10),
                    const Text(
                      "Sort by",
                      style: TextStyle(
                        color: themePurple,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: double.infinity, color: borderColor),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FilterScreen()),
                );
              },
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt_outlined,
                      color: themePurple,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Filter",
                      style: TextStyle(
                        color: themePurple,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Women's jewellery",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Found ${_products.length} products",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: _products.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty && !_isLoading
          ? const Center(child: Text("No products found"))
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _products.clear();
                  _lastDoc = null;
                  _hasMore = true;
                });
                await _fetchProducts();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24),
                child: GridView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount:
                      _products.length + (_hasMore && _isLoading ? 1 : 0),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isMobile ? screenWidth / 2 : 280,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isMobile ? 0.68 : 0.80,
                  ),
                  itemBuilder: (context, index) {
                    if (index >= _products.length) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final product = _products[index];

                    return FutureBuilder<double>(
                      future: _getRate(product.metalName),
                      builder: (context, snapshot) {
                        String key = product.metalName.trim().toUpperCase();

                        double currentRate =
                            _rateCache[key] ?? snapshot.data ?? 0.0;

                        return ProductCard(
                          product: product,
                          ratePerGram: currentRate,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
      bottomNavigationBar: _buildSortFilterBar(),
    );
  }
}
