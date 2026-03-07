import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();

  factory CategoryService() => _instance;

  CategoryService._internal();

  final List<Map<String, String>> _categoryList = [];

  Future<void> loadCategories() async {
    if (_categoryList.isNotEmpty) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Category')
          .orderBy('name')
          .get();

      _categoryList.clear();

      for (var doc in snapshot.docs) {
        _categoryList.add({
          'id': doc["id"].toString(),
          'name': doc['name'] as String,
        });
      }
    } catch (e) {
      debugPrint("Error loading categories: $e");
    }
  }

  String getCategoryName(String categoryId) {
    if (_categoryList.isEmpty || categoryId.isEmpty) {
      return "Jewellery";
    }

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

  List<Map<String, String>> get categories => _categoryList;
}
