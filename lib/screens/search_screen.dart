import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'grid_screen.dart';
import 'home_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Map<String, String>> _categoryList = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Category')
        .orderBy('name')
        .get();

    setState(() {
      _categoryList = snapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name'] as String})
          .toList();
    });
  }

  String? _getCategoryIdByName(String name) {
    try {
      return _categoryList.firstWhere(
        (cat) => cat['name']!.toLowerCase() == name.toLowerCase(),
      )['id'];
    } catch (e) {
      return null;
    }
  }

  void _navigateToGrid(
    BuildContext context, {
    List<String>? metals,
    List<String>? genders,
    String? categorySearchName,
  }) {
    List<String> categoryIds = [];

    if (categorySearchName != null) {
      String? id = _getCategoryIdByName(categorySearchName);
      if (id != null) categoryIds.add(id);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GridScreen(
          initialMetals: metals ?? [],
          initialGenders: genders ?? [],
          initialCategoryIds: categoryIds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                color: const Color(0xFFFAF5FF),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => HomeScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEAF7),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Search',
                                style: TextStyle(
                                  color: AppColors.textColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.search,
                                color: Colors.black54,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GridScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("Recent searches"),
                    Wrap(
                      spacing: 10,
                      children: [
                        _pillChip("Bracelet"),
                        _pillChip("Platinum ring"),
                      ],
                    ),

                    const SizedBox(height: 30),

                    _sectionTitle("Top recommendations"),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _recommendationTile(
                          "Gold jewellery",
                          () => _navigateToGrid(context, metals: ["Gold"]),
                        ),
                        _recommendationTile(
                          "Silver jewellery",
                          () => _navigateToGrid(context, metals: ["Silver"]),
                        ),
                        _recommendationTile(
                          "Men's jewellery",
                          () => _navigateToGrid(context, genders: ["Male"]),
                        ),
                        _recommendationTile(
                          "Ladies jewellery",
                          () => _navigateToGrid(context, genders: ["Female"]),
                        ),
                        _recommendationTile(
                          "New born",
                          () => _navigateToGrid(context, genders: ["Children"]),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    _sectionTitle("Trending searches"),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _rectChip(
                          "Gold jeweller",
                          () => _navigateToGrid(context, metals: ["Gold"]),
                        ),
                        _rectChip(
                          "Silver",
                          () => _navigateToGrid(context, metals: ["Silver"]),
                        ),
                        _rectChip(
                          "Bracelets",
                          () => _navigateToGrid(
                            context,
                            categorySearchName: "Bracelets",
                          ),
                        ),
                        _rectChip(
                          "Women",
                          () => _navigateToGrid(context, genders: ["Female"]),
                        ),
                        _rectChip(
                          "Men",
                          () => _navigateToGrid(context, genders: ["Male"]),
                        ),
                        _rectChip(
                          "Children",
                          () => _navigateToGrid(context, genders: ["Children"]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _pillChip(String label) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE0E0E0)),
        shape: const StadiumBorder(),
      ),
      child: Text(label, style: const TextStyle(color: Colors.black87)),
    );
  }

  Widget _rectChip(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE0E0E0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _recommendationTile(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: (100.0 * 1.6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 18, backgroundColor: Color(0xFFD7CCC8)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
