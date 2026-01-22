import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../models/product_rate_model.dart';

class ProductRateDao {
  final CollectionReference _rateRef = FirebaseFirestore.instance.collection(
    "product_rate",
  );

  Future<void> addRateEntry(ProductRateModel rate) {
    return _rateRef.doc(rate.id).set(rate.toJson());
  }

  Stream<List<ProductRateModel>> getFilteredRates(
    String productType,
    int startTs,
    int endTs,
  ) {
    return _rateRef
        .where('productType', isEqualTo: productType)
        .where('timestamp', isGreaterThanOrEqualTo: startTs)
        .where('timestamp', isLessThanOrEqualTo: endTs)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductRateModel.fromSnapshot(doc))
              .toList(),
        );
  }

  // Inside ProductDao class
  Future<double> getLatestRateByType(String metalName) async {
    try {
      // We query the product_rate collection directly
      final snap = await FirebaseFirestore.instance
          .collection('product_rate')
          .where('productType', isEqualTo: metalName.toUpperCase())
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return 0.0;

      // Returns the 'price' field from the most recent document
      return (snap.docs.first.data()['price'] as num).toDouble();
    } catch (e) {
      debugPrint("Error fetching rate for $metalName: $e");
      return 0.0;
    }
  }
}
