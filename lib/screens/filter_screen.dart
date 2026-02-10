import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FilterScreen extends StatefulWidget {
  final List<String> initialSelectedIds;
  final List<String> initialSelectedGenders;
  final List<String> initialSelectedMetals;
  final double? currentMinPrice;
  final double? currentMaxPrice;

  const FilterScreen({
    super.key,
    required this.initialSelectedIds,
    required this.initialSelectedGenders,
    required this.initialSelectedMetals,
    required this.currentMinPrice,
    required this.currentMaxPrice,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  int _selectedCategoryIndex = 0;

  Set<String> _tempSelectedCategoryIds = {};
  List<Map<String, String>> _categoryList = [];
  bool _isLoading = true;
  Set<String> _tempSelectedGenders = {};
  Set<String> _tempSelectedMetals = {};
  final List<String> _menuItems = ["Product type", "Price", "Metal", "Gender"];
  final List<String> _metalOptions = ['Platinum', 'Gold', 'Silver', 'Diamond'];
  late RangeValues _currentRangeValues;

  @override
  void initState() {
    super.initState();
    _tempSelectedCategoryIds = Set.from(widget.initialSelectedIds);
    _tempSelectedGenders = Set.from(widget.initialSelectedGenders);
    _tempSelectedMetals = Set.from(widget.initialSelectedMetals);
    _currentRangeValues = RangeValues(
      widget.currentMinPrice ?? 0.0,
      widget.currentMaxPrice ?? 2000000.0,
    );
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Category')
          .orderBy('name')
          .get();

      final fetched = snapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name'] as String})
          .toList();

      setState(() {
        _categoryList = fetched;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading categories: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color themePurple = Color(0xFF6B52A1);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Filters",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: Colors.black26),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 150,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      bool isSelected = _selectedCategoryIndex == index;
                      String countSuffix = "";
                      if (index == 0 && _tempSelectedCategoryIds.isNotEmpty) {
                        countSuffix = " (${_tempSelectedCategoryIds.length})";
                      } else if (index == 1) {
                        bool isPriceActive =
                            _currentRangeValues.start != 0 ||
                            _currentRangeValues.end != 2000000;
                        if (isPriceActive) countSuffix = " (1)";
                      } else if (index == 3 &&
                          _tempSelectedGenders.isNotEmpty) {
                        countSuffix = " (${_tempSelectedGenders.length})";
                      } else if (index == 2 && _tempSelectedMetals.isNotEmpty) {
                        countSuffix = " (${_tempSelectedMetals.length})";
                      }
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategoryIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFFF9F9F9),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              ),
                              left: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF6B52A1)
                                    : Colors.transparent,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _menuItems[index],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? const Color(0xFF6B52A1)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (countSuffix.isNotEmpty)
                                Text(
                                  countSuffix,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B52A1),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(child: _buildRightSideContent()),
              ],
            ),
          ),
          _buildBottomButtons(themePurple),
        ],
      ),
    );
  }

  Widget _buildGenderContent() {
    final List<String> genderOptions = ['Male', 'Female', 'Kids', 'Unisex'];

    return ListView.builder(
      itemCount: genderOptions.length,
      itemBuilder: (context, index) {
        String gender = genderOptions[index];
        bool isSelected = _tempSelectedGenders.contains(gender);

        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _tempSelectedGenders.remove(gender);
              } else {
                _tempSelectedGenders.add(gender);
              }
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFBCB1D8) : Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
              ),
            ),
            child: Text(
              gender,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRightSideContent() {
    if (_selectedCategoryIndex == 0) {
      if (_isLoading) return const Center(child: CircularProgressIndicator());
      return ListView.builder(
        itemCount: _categoryList.length,
        itemBuilder: (context, index) {
          final cat = _categoryList[index];
          final String catId = cat['id']!;
          bool isSelected = _tempSelectedCategoryIds.contains(catId);

          return InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _tempSelectedCategoryIds.remove(catId);
                } else {
                  _tempSelectedCategoryIds.add(catId);
                }
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFBCB1D8) : Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                ),
              ),
              child: Text(
                cat['name']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          );
        },
      );
    }
    if (_selectedCategoryIndex == 1) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Chip(
                label: Text(
                  "₹ ${_currentRangeValues.start.toInt()} - ₹ ${_currentRangeValues.end.toInt()}",
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: const Color(0xFF9E8BCA),
              ),
            ),
            const SizedBox(height: 20),
            RangeSlider(
              values: _currentRangeValues,
              min: 0,
              max: 2000000,
              divisions: 200,
              activeColor: const Color(0xFF6B52A1),
              inactiveColor: const Color(0xFFE5E0F0),
              labels: RangeLabels(
                _currentRangeValues.start.round().toString(),
                _currentRangeValues.end.round().toString(),
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _currentRangeValues = values;
                });
              },
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                _priceBox("₹ ${_currentRangeValues.start.toInt()}"),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("To"),
                ),
                _priceBox("₹ ${_currentRangeValues.end.toInt()}"),
              ],
            ),
          ],
        ),
      );
    }
    if (_selectedCategoryIndex == 2) {
      if (_metalOptions.isEmpty)
        return const Center(child: CircularProgressIndicator());
      return ListView.builder(
        itemCount: _metalOptions.length,
        itemBuilder: (context, index) {
          String metal = _metalOptions[index];
          bool isSelected = _tempSelectedMetals.contains(metal);

          return InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _tempSelectedMetals.remove(metal);
                } else {
                  _tempSelectedMetals.add(metal);
                }
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFBCB1D8) : Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                ),
              ),
              child: Text(
                metal,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          );
        },
      );
    }
    if (_selectedCategoryIndex == 3) {
      if (_isLoading) return const Center(child: CircularProgressIndicator());
      return _buildGenderContent();
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
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _tempSelectedCategoryIds.clear();
                  _tempSelectedGenders.clear();
                  _tempSelectedMetals.clear();
                  _currentRangeValues = const RangeValues(0, 2000000);
                });
              },
              child: const Text(
                "Reset",
                style: TextStyle(color: Color(0xFF6B52A1), fontSize: 18),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: double.infinity,
              color: themePurple,
              child: TextButton(
                onPressed: () {
                  bool isPriceDefault =
                      _currentRangeValues.start == 0 &&
                      _currentRangeValues.end == 2000000;
                  Navigator.pop(context, {
                    "categories": _tempSelectedCategoryIds.toList(),
                    "genders": _tempSelectedGenders.toList(),
                    "metals": _tempSelectedMetals.toList(),
                    "minPrice": isPriceDefault
                        ? null
                        : _currentRangeValues.start,
                    "maxPrice": isPriceDefault ? null : _currentRangeValues.end,
                  });
                },
                child: const Text(
                  "Apply Filter",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
