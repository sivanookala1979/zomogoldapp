import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistModel {
  final String wishlistId;
  final String userId;
  final String productId;
  final DateTime createdAt;

  WishlistModel({
    required this.wishlistId,
    required this.userId,
    required this.productId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'wishlistId': wishlistId,
      'userId': userId,
      'productId': productId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WishlistModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WishlistModel(
      wishlistId: data['wishlistId'] ?? '',
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      createdAt: DateTime.parse(data['createdAt']),
    );
  }
}