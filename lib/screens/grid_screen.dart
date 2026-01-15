import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../dao/product_dao.dart';
import '../models/product_model.dart';
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

  Future<void> _fetchProducts() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('Products')
        .orderBy('createdTimestamp', descending: true)
        .limit(15);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snap = await query.get();

    if (snap.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDoc = snap.docs.last;
      _products.addAll(snap.docs.map((e) => ProductModel.fromSnapshot(e)));
    }

    setState(() => _isLoading = false);
  }

  Future<double> _getRate(String metal) async {
    if (_rateCache.containsKey(metal)) return _rateCache[metal]!;
    final rate = await _productDao.getLatestRateByType(metal);
    _rateCache[metal] = rate;
    return rate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('', style: TextStyle(color: Colors.black)),
        actions: const [
          Icon(Icons.search, color: Colors.black),
          SizedBox(width: 12),
          Icon(Icons.favorite_border, color: Colors.black),
          SizedBox(width: 12),
          Icon(Icons.shopping_cart_outlined, color: Colors.black),
          SizedBox(width: 12),
        ],
      ),
      body: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _products.length + (_isLoading ? 1 : 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.63,
        ),
        itemBuilder: (context, index) {
          if (index >= _products.length) {
            return const Center(child: CircularProgressIndicator());
          }

          final product = _products[index];

          return FutureBuilder<double>(
            future: _getRate(product.metalName),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }
              return ProductCard(product: product, ratePerGram: snapshot.data!);
            },
          );
        },
      ),
    );
  }
}
