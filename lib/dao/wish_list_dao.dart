import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zomogoldapp/models/wish_list_model.dart';

class WishlistDao {
  final CollectionReference _wishlistRef = FirebaseFirestore.instance
      .collection('Wishlist');

  Future<void> addProduct(WishlistModel wishlist) {
    return _wishlistRef.doc(wishlist.wishlistId).set(wishlist.toJson());
  }

  Future<void> removeProduct(String userId, String productId) async {
    final query = await _wishlistRef
        .where('userId', isEqualTo: userId)
        .where('productId', isEqualTo: productId)
        .get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  Future<bool> isInWishlist(String wishlistId) async {
    final doc = await _wishlistRef.doc(wishlistId).get();
    return doc.exists;
  }

  Stream<List<WishlistModel>> getWishlistForUser(String userId) {
    return _wishlistRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WishlistModel.fromSnapshot(doc))
              .toList(),
        );
  }

  Future<bool> isProductInWishlist(String userId, String productId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Wishlist')
        .where('userId', isEqualTo: userId)
        .where('productId', isEqualTo: productId)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<int> generateNextWishlistId() async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('sequences')
          .doc('wishlist_sequence');

      final snap = await ref.get();

      if (!snap.exists) {
        await ref.set({"nextId": 1});
        return 1;
      }

      int nextId = (snap.get("nextId") as int) + 1;
      await ref.update({"nextId": nextId});
      return nextId;
    } catch (e) {
      print("Debug Error in generateNextWishlistId: $e");
      return DateTime.now().millisecondsSinceEpoch;
    }
  }
}
