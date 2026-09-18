import 'package:flutter/material.dart';

import '../dao/product_dao.dart';
import 'product_view_page.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final TextEditingController _controller = TextEditingController();
  final ProductDao _productDao = ProductDao();

  bool _isLoading = false;

  Future<void> _searchProduct(String value) async {
    final productId = value.trim();

    if (productId.length != 8 ||
        !RegExp(r'^[1-9]{8}$').hasMatch(productId)) {
      _showMessage('Enter a valid 8-digit Product ID.');
      _controller.clear();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final exists = await _productDao.productIdExists(productId);

      if (!exists) {
        _showMessage('Product ID $productId was not found.');
        return;
      }

      final product = await _productDao.getProductById(productId);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsViewPage(
            productId: productId,
          ),
        ),
      );
    } catch (e) {
      _showMessage('Unable to find product.');
      debugPrint('BARCODE SCAN ERROR: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_scanner,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Scan Product Barcode',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Scan the product barcode or enter the Product ID.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                decoration: const InputDecoration(
                  hintText: 'Enter Product ID',
                  hintStyle: TextStyle(
                    fontSize: 20,
                  ),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                onSubmitted: _searchProduct,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
