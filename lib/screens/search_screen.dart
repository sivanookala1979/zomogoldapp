import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/custom_buttons.dart';
import '../theme/app_theme.dart';
import 'grid_screen.dart';
import 'home_screen.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Map<String, String>> _categoryList = [];
  final TextEditingController _searchController = TextEditingController();
  List<String> recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    loadRecentSearches();
  }

  Future<void> _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Category')
        .orderBy('name')
        .get();

    setState(() {
      _categoryList = snapshot.docs
          .map(
            (doc) => {
              'id': doc["id"].toString(),
              'name': doc['name'] as String,
            },
          )
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
    String? searchQuery,
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
          initialSearchQuery: searchQuery,
        ),
      ),
    );
  }

  Future<List<String>> _getSuggestions(String query) async {
    if (query.isEmpty) return [];

    String searchKey = query.toLowerCase();

    final snapshot = await FirebaseFirestore.instance
        .collection('Products')
        .where("productNameLower", isGreaterThanOrEqualTo: searchKey)
        .where("productNameLower", isLessThanOrEqualTo: "$searchKey\uf8ff")
        .orderBy("productNameLower")
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => doc["productName"].toString())
        .toSet()
        .toList();
  }

  Future<void> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('recent_searches') ?? [];
    setState(() {
      recentSearches = data;
    });
  }

  Future<void> saveRecentSearch(String search) async {
    search = search.trim();
    if (search.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    List<String> searches = prefs.getStringList('recent_searches') ?? [];

    searches.remove(search);
    searches.insert(0, search);

    if (searches.length > 5) {
      searches = searches.sublist(0, 5);
    }

    await prefs.setStringList('recent_searches', searches);

    setState(() {
      recentSearches = searches;
    });
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
                  horizontal: 12,
                  vertical: 10,
                ),
                color: Colors.white,
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
                    Expanded(
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.purple.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: TypeAheadField<String>(
                          suggestionsCallback: (pattern) async {
                            return await _getSuggestions(pattern);
                          },
                          itemBuilder: (context, suggestion) {
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                mouseCursor: SystemMouseCursors.click,
                                onTap: () {
                                  _searchController.text = suggestion;
                                  saveRecentSearch(suggestion);
                                  _navigateToGrid(
                                    context,
                                    searchQuery: suggestion,
                                  );
                                },
                                child: ListTile(
                                  title: Text(
                                    suggestion,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  trailing: const Icon(Icons.north_west),
                                ),
                              ),
                            );
                          },
                          onSelected: (suggestion) {
                            _searchController.text = suggestion;
                            saveRecentSearch(suggestion);
                            _navigateToGrid(context, searchQuery: suggestion);
                          },
                          emptyBuilder: (context) => SizedBox(),
                          builder: (context, controller, focusNode) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (value) {
                                saveRecentSearch(value);
                                _navigateToGrid(
                                  context,
                                  searchQuery: value.trim(),
                                );
                              },
                              decoration: InputDecoration(
                                hintText: "Search...",
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.all(10.0),
                                suffixIcon: IconButton(
                                  icon: const  Icon(Icons.search),
                                  onPressed: () {
                                    final value = controller.text.trim();
                                    if (value.isNotEmpty) {
                                      saveRecentSearch(value);
                                    }
                                    _navigateToGrid(context, searchQuery: value);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    actionCircleIcon(
                      icon: Icons.favorite_border,
                      context: context,
                    ),
                    const SizedBox(width: 8),
                    actionCircleIcon(
                      icon: Icons.shopping_bag_outlined,
                      context: context,
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
                      children: recentSearches
                          .map((search) => _pillChip(search))
                          .toList(),
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
      onPressed: () {
        _searchController.text = label;
        _navigateToGrid(context, searchQuery: label);
      },
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
