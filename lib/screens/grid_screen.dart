import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../dao/product_dao.dart';
import '../models/price_calculator.dart';
import '../models/product_model.dart';
import 'filter_screen.dart';
import 'product_card.dart';

class GridScreen extends StatefulWidget {
  final List<String> initialMetals;
  final List<String> initialGenders;
  final List<String> initialCategoryIds;

  const GridScreen({
    super.key,
    this.initialMetals = const [],
    this.initialGenders = const [],
    this.initialCategoryIds = const [],
  });

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
  List<Map<String, String>> _categoryList = [];
  List<String> _activeCategoryIds = [];
  List<String> _activeGenders = [];
  List<String> _activeMetals = [];
  double? _currentMinPrice;
  double? _currentMaxPrice;

  @override
  void initState() {
    super.initState();
    _activeMetals = List.from(widget.initialMetals);
    _activeGenders = List.from(widget.initialGenders);
    _activeCategoryIds = List.from(widget.initialCategoryIds);
    _fetchProducts();
    _loadCategories();
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

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Category')
          .orderBy('name')
          .get();

      final fetched = snapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name'] as String})
          .toList();

      setState(() {
        _categoryList = fetched;
      });
    } catch (e) {
      debugPrint("Error loading categories: $e");
    }
  }

  Future<void> _fetchProducts({bool isRefresh = false}) async {
    if (_isLoading || (!_hasMore && !isRefresh)) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _products.clear();
        _lastDoc = null;
        _hasMore = true;
      }
    });

    try {
      Query query = FirebaseFirestore.instance.collection('Products');
      if (_activeCategoryIds.isNotEmpty) {
        query = query.where('categoryId', whereIn: _activeCategoryIds);
      } else if (_activeGenders.isNotEmpty) {
        query = query.where('gender', whereIn: _activeGenders);
      } else if (_activeMetals.isNotEmpty) {
        query = query.where('metalName', whereIn: _activeMetals);
      }
      query = query.orderBy('createdTimestamp', descending: true).limit(20);

      if (_lastDoc != null && !isRefresh) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snap = await query.get();

      if (snap.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
      } else {
        if (snap.docs.length < 20) _hasMore = false;
        _lastDoc = snap.docs.last;

        final fetchedProducts = snap.docs
            .map((e) => ProductModel.fromSnapshot(e))
            .toList();

        List<ProductModel> filteredItems = [];

        for (var product in fetchedProducts) {
          bool matchesGender =
              _activeGenders.isEmpty || _activeGenders.contains(product.gender);
          if (!matchesGender) continue;
          bool matchesMetal =
              _activeMetals.isEmpty ||
                  _activeMetals.any(
                        (m) =>
                    m.toLowerCase() == product.metalName.toLowerCase(),
                  );

          if (!matchesMetal) continue;
          bool matchesPrice = true;
          if (_currentMinPrice != null && _currentMaxPrice != null) {
            double currentRate =
                _rateCache[product.metalName.toUpperCase()] ?? 0.0;

            double mrp = PriceCalculator.calculateProductMRP(
              metalName: product.metalName,
              carats: product.carats,
              metalGrams: product.metalGrams,
              metalRate: currentRate,
              stoneWeight: product.stoneWeight,
              stoneCost: product.stoneCost,
              makingChargeValue: product.makingCharges,
              makingChargeType: "Flat",
            );

            double sellingPrice = PriceCalculator.calculateSellingPrice(
              mrp: mrp,
              discountPercent: product.discount,
            );

            matchesPrice =
                sellingPrice >= _currentMinPrice! &&
                    sellingPrice <= _currentMaxPrice!;
          }

          if (matchesPrice) {
            filteredItems.add(product);
          }
        }

        if (!mounted) return;
        setState(() {
          _products.addAll(filteredItems);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
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

  void _openFilter() async {
    final Map<String, dynamic>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FilterScreen(
              initialSelectedIds: _activeCategoryIds,
              initialSelectedGenders: _activeGenders,
              initialSelectedMetals: _activeMetals,
              currentMinPrice: _currentMinPrice ?? 0.0,
              currentMaxPrice: _currentMaxPrice ?? 2000000.0,
            ),
      ),
    );

    if (result != null) {
      setState(() {
        _activeCategoryIds = List<String>.from(result["categories"]);
        _activeGenders = List<String>.from(result["genders"]);
        _activeMetals = List<String>.from(result["metals"]);
        _currentMinPrice = result["minPrice"];
        _currentMaxPrice = result["maxPrice"];
      });
      _fetchProducts(isRefresh: true);
    }
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
    final bool isPriceFiltered =
        _currentMinPrice != null && _currentMaxPrice != null;

    final int selectedCount =
        _activeCategoryIds.length +
            _activeGenders.length +
            _activeMetals.length +
            (isPriceFiltered ? 1 : 0);
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderColor, width: 1.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showSortBottomSheet(context),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort_rounded, color: themePurple, size: 22),
                    SizedBox(width: 10),
                    Text(
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
              onTap: () => _openFilter(),
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
                    Text(
                      selectedCount > 0 ? "Filter ($selectedCount)" : "Filter",
                      style: const TextStyle(
                        color: themePurple,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
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
              "Jewellery",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _isLoading && _products.isEmpty
                  ? "Updating..."
                  : "Found ${_products.length} products",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchProducts(isRefresh: true),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: _isLoading && _products.isEmpty
                    ? _buildSkeletonGrid(isMobile, screenWidth)
                    : _products.isEmpty
                    ? const Center(child: Text("No products found"))
                    : GridView.builder(
                  controller: _scrollController,
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
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final product = _products[index];
                    return FutureBuilder<double>(
                      future: _getRate(product.metalName),
                      builder: (context, snapshot) {
                        return ProductCard(
                          product: product,
                          ratePerGram: snapshot.data ?? 0.0,
                          categoryName: _getCategoryName(
                            product.categoryId,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildSortFilterBar(),
    );
  }

  Widget _buildSkeletonGrid(bool isMobile, double screenWidth) {
    return GridView.builder(
      itemCount: 6,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isMobile ? screenWidth / 2 : 280,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isMobile ? 0.68 : 0.80,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Expanded(child: Container(color: Colors.grey[200])),
              Container(
                height: 15,
                margin: const EdgeInsets.all(8),
                color: Colors.grey[100],
              ),
              Container(
                height: 15,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 60,
                color: Colors.grey[50],
              ),
            ],
          ),
        );
      },
    );
  }
}
