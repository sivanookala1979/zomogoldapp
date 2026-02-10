import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zomogoldapp/screens/search_screen.dart';

import 'gold_rate.dart';
import 'grid_screen.dart';

void main() {
  runApp(
    const MaterialApp(home: HomeScreen(), debugShowCheckedModeBanner: false),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> _categoryList = [];

  final List<Map<String, dynamic>> mainCategories = const [
    {'name': 'Rings', 'imageAsset': 'assets/ring.png'},
    {'name': 'Necklaces', 'imageAsset': 'assets/necklaces.png'},
    {'name': 'Nose accessories', 'imageAsset': 'assets/noserings.png'},
    {'name': 'Silver coin', 'imageAsset': 'assets/silver_coin.png'},
    {'name': 'Pendants', 'imageAsset': 'assets/pendants.png'},
    {'name': 'Earrings', 'imageAsset': 'assets/earrings.png'},
    {'name': 'Bracelets', 'imageAsset': 'assets/bracelets.png'},
    {'name': 'Anklets', 'imageAsset': 'assets/anklets.png'},
  ];

  final List<Map<String, dynamic>> shopByPeople = const [
    {'name': 'Men', 'imageAsset': 'assets/men.png'},
    {'name': 'Women', 'imageAsset': 'assets/women.png'},
    {'name': 'Boy', 'imageAsset': 'assets/boy.png'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Category')
          .orderBy('name')
          .get();

      setState(() {
        _categoryList = snapshot.docs
            .map((doc) => {'id': doc.id, 'name': doc['name'] as String})
            .toList();
      });
    } catch (e) {
      debugPrint("Error loading categories: $e");
    }
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
    String? categoryName,
  }) {
    List<String> categoryIds = [];
    if (categoryName != null) {
      String? id = _getCategoryIdByName(categoryName);
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
    final Color backgroundColor = const Color(0xFFFBF4FF);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              children: [
                const Text(
                  'Logo',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SearchScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.black),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 10),
                _buildBanner(isMobile),
                const SizedBox(height: 30),
                _buildSectionTitle('Shop By'),
                const SizedBox(height: 15),
                _buildShopByChips(context, isMobile),
                const SizedBox(height: 30),
                _buildSectionTitle('Shop by category'),
                const SizedBox(height: 15),
                _buildCategoryGrid(),
                const SizedBox(height: 30),
                _buildSectionTitle('Shop by'),
                const SizedBox(height: 15),
                _buildShopByPeopleRow(screenWidth > 1024),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 16),
                  child: Divider(color: Color(0xFFDDDDDD), thickness: 1),
                ),
                _buildAboutUsSection(context),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildBanner(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: AspectRatio(
        aspectRatio: isMobile ? 16 / 9 : 21 / 7,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFBE4D2),
              image: DecorationImage(
                image: AssetImage('assets/home_image.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopByChips(BuildContext context, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: <Widget>[
          _buildPillButton(
            context,
            'Gold',
            Icons.circle,
            Colors.amber,
            isMobile,
            () => _navigateToGrid(context, metals: ['Gold']),
          ),
          _buildPillButton(
            context,
            'Silver',
            Icons.horizontal_rule,
            Colors.grey,
            isMobile,
            () => _navigateToGrid(context, metals: ['Silver']),
          ),
          _buildPillButton(
            context,
            'Diamond',
            Icons.diamond,
            Colors.blueGrey,
            isMobile,
            () => _navigateToGrid(context, metals: ['Diamond']),
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton(
    BuildContext context,
    String title,
    IconData icon,
    Color iconColor,
    bool isMobile,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: isMobile ? (MediaQuery.of(context).size.width / 3) - 22 : 180,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.85,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: mainCategories.length,
        itemBuilder: (context, index) {
          final category = mainCategories[index];
          final String name = category['name'];
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _navigateToGrid(context, categoryName: name),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: Colors.grey.shade200),
                        image: DecorationImage(
                          image: AssetImage(category['imageAsset']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category['name'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShopByPeopleRow(bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 30,
        runSpacing: 20,
        alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
        children: shopByPeople.map((person) {
          final String name = person['name'] as String;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                String searchGender = name;
                if (name == 'Boy') {
                  searchGender = 'Children';
                }
                _navigateToGrid(context, genders: [searchGender]);
              },
              child: Column(
                children: <Widget>[
                  Container(
                    width: isDesktop ? 130 : 100,
                    height: isDesktop ? 130 : 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                      image: DecorationImage(
                        image: AssetImage(person['imageAsset'] as String),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAboutUsSection(BuildContext context) {
    return const Center(
      child: Column(
        children: [
          Text(
            'About us',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Zomo jewellers Pvt.Ltd.\nHyderabad, India',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        onTap: (index) {
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GoldRatesScreen()),
            );
          }
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_sharp), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.apps_sharp),
            label: 'Category',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
