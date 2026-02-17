import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

class ProductDao {
  final CollectionReference _productRef = FirebaseFirestore.instance.collection(
    "Products",
  );

  Future<void> addProduct(ProductModel product) {
    return _productRef.doc(product.productId).set(product.toJson());
  }

  Future<void> updateProduct(ProductModel product) {
    return _productRef.doc(product.productId).update(product.toJson());
  }

  Future<void> deleteProduct(String productId) {
    return _productRef.doc(productId).delete();
  }

  Future<ProductModel> getProductById(String productId) async {
    DocumentSnapshot doc = await _productRef.doc(productId).get();
    return ProductModel.fromSnapshot(doc);
  }

  Stream<List<ProductModel>> getAllProducts() {
    return _productRef.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList(),
    );
  }

  Stream<List<ProductModel>> getProductsByCategory(String categoryId) {
    return _productRef
        .where("categoryId", isEqualTo: categoryId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromSnapshot(doc))
              .toList(),
        );
  }

  Stream<List<ProductModel>> getProductsByUser(String userId) {
    return _productRef
        .where("userId", isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromSnapshot(doc))
              .toList(),
        );
  }

  Future<int> generateNextProductId() async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('sequences')
          .doc('product_sequence');
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({"nextId": 1});
        return 1;
      }
      int nextId = snap.get("nextId") + 1;
      await ref.update({"nextId": nextId});
      return nextId;
    } catch (e) {
      print("Debug Error: $e");
      return DateTime.now().millisecondsSinceEpoch;
    }
  }

  Future<double> getLatestRateByType(String productType) async {
    final snap = await FirebaseFirestore.instance
        .collection('product_rate')
        .where('productType', isEqualTo: productType.toUpperCase())
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return 0.0;

    return (snap.docs.first['price'] as num).toDouble();
  }
  Future<void> recordView(String productId) async {
    await _productRef.doc(productId).update({
      'viewCount': FieldValue.increment(1)});
  }
}
