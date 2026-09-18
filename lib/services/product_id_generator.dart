import 'dart:math';

import '../dao/product_dao.dart';

class ProductIdGenerator {
  static const int _maxAttempts = 5;
  static final Random _random = Random.secure();

  static Future<String> generate(ProductDao productDao) async {
    for (int attempt = 0; attempt < _maxAttempts; attempt++) {
      final productId = _generateCandidate();

      final exists = await productDao.productIdExists(productId);

      if (!exists) {
        print("GENERATED PRODUCT ID: $productId");
        return productId;
      }
    }

    throw Exception(
      'Unable to generate a unique product ID after $_maxAttempts attempts.',
    );
  }

  static String _generateCandidate() {
    return List.generate(
      8,
      (_) => (_random.nextInt(9) + 1).toString(),
    ).join();
  }
}