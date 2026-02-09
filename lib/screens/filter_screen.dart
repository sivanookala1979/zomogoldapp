import 'package:flutter/material.dart';
class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  int _selectedCategoryIndex = 1;

  final List<String> _categories = [
    "Product type", "Price", "Metal", "Line", "Story",
    "Earring style", "New In", "Discounts", "Finish",
    "Motifs and patterns", "Look", "Curated", "Gifts", "Exclude Out of stock"
  ];

  @override
  Widget build(BuildContext context) {
    const Color themePurple = Color(0xFF6B52A1);
    const Color lightPurple = Color(0xFFE5E0F0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Filters", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: const [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Text("499 Items found", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                // Left Side: Categories
                SizedBox(
                  width: 150,
                  child: ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      bool isSelected = _selectedCategoryIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategoryIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          decoration: BoxDecoration(
                            color: isSelected ? lightPurple : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                              right: BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                          ),
                          child: Text(
                            _categories[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? themePurple : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Right Side: Selection Details (e.g., Price Range)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildRightSideContent(),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Buttons
          _buildBottomButtons(themePurple),
        ],
      ),
    );
  }

  Widget _buildRightSideContent() {
    // Show price slider if "Price" is selected
    if (_selectedCategoryIndex == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Chip(
              label: Text("₹ 90,000", style: TextStyle(color: Colors.white)),
              backgroundColor: Color(0xFF9E8BCA),
            ),
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6B52A1),
              inactiveTrackColor: const Color(0xFFE5E0F0),
              thumbColor: const Color(0xFF6B52A1),
            ),
            child: Slider(value: 0.45, onChanged: (v) {}),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("₹ 0", style: TextStyle(fontSize: 12)), Text("₹ 2,00,000", style: TextStyle(fontSize: 12))],
          ),
          const SizedBox(height: 30),
          const Row(
            children: [
              Expanded(child: Text("Min", style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text("Max", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          Row(
            children: [
              _priceBox("₹ 1,000"),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  "To",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              _priceBox("₹ 1,00,000"),
            ],
          ),
        ],
      );
    }
    return const Center(child: Text("Select a category"));
  }

  Widget _priceBox(String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F1F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons(Color themePurple) {
    return Container(
      height: 60,
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {},
              child: const Text("Reset", style: TextStyle(color: Color(0xFF6B52A1), fontSize: 18)),
            ),
          ),
          Expanded(
            child: Container(
              height: double.infinity,
              color: themePurple,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Clear Filter", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}