import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const Color primaryPurple = Color(0xFF7F55B5);

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final List<dynamic> _extraImages = [];
  final PageController _pageController = PageController();
  Timer? _autoSlideTimer;
  int _currentPage = 0;
  static const int maxImages = 5;

  String _selectedMetal = 'Platinum';
  final List<String> _metalOptions = ['Platinum', 'Gold', 'Silver', 'Copper'];

  final TextEditingController _stoneWeightController = TextEditingController();
  final TextEditingController _stoneCostController = TextEditingController();
  final TextEditingController _makingChargesController =
      TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _productDetailsController =
      TextEditingController();
  final TextEditingController _specificationsController =
      TextEditingController();

  bool _hallmarkAvailable = false;
  String _weightUnit = 'Select';
  String _makingChargeType = '%';

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (_extraImages.length <= 1) return;

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_pageController.hasClients) return;
      _currentPage = (_currentPage + 1) % _extraImages.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _pickNewImage() async {
    if (_extraImages.length >= maxImages) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final data = kIsWeb
        ? await pickedFile.readAsBytes()
        : File(pickedFile.path);

    setState(() {
      _extraImages.add(data);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _currentPage = _extraImages.length - 1;
        _pageController.jumpToPage(_currentPage);
      }
    });

    _startAutoSlide();
  }

  Widget _displayImage(dynamic img) {
    if (img is Uint8List) {
      return Image.memory(img, fit: BoxFit.cover);
    } else if (img is File) {
      return Image.file(img, fit: BoxFit.cover);
    }
    return Container(color: Colors.grey.shade200);
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    int maxLines = 1,
    String? prefixText,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryPurple, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down, color: primaryPurple),
          items: options
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Product Details",
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _extraImages.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "Upload Product Pictures",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _extraImages.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (_, i) => _displayImage(_extraImages[i]),
                      ),
                    ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ReorderableListView(
                scrollDirection: Axis.horizontal,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _extraImages.removeAt(oldIndex);
                    _extraImages.insert(newIndex, item);

                    _currentPage = newIndex;
                    _pageController.jumpToPage(_currentPage);
                  });
                },
                children: [
                  for (int index = 0; index < _extraImages.length; index++)
                    GestureDetector(
                      key: ValueKey(_extraImages[index]),
                      onTap: () => _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 70,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _currentPage == index
                                ? primaryPurple
                                : Colors.grey.shade300,
                            width: _currentPage == index ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _displayImage(_extraImages[index]),
                        ),
                      ),
                    ),

                  if (_extraImages.length < maxImages)
                    Container(
                      key: const ValueKey("add_button"),
                      width: 70,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.grey),
                        onPressed: _pickNewImage,
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Metal Name",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                _buildDropdown(
                  _selectedMetal,
                  _metalOptions,
                  (v) => setState(() => _selectedMetal = v!),
                ),
              ],
            ),

            _buildSectionLabel("Stone Weight"),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(_stoneWeightController, hint: "0.00"),
                ),
                const SizedBox(width: 12),
                _buildDropdown(_weightUnit, [
                  'Select',
                  'Gram',
                  'Carat',
                ], (v) => setState(() => _weightUnit = v!)),
              ],
            ),

            _buildSectionLabel("Stone Cost"),
            _buildTextField(
              _stoneCostController,
              prefixText: "₹ ",
              hint: "Enter cost",
            ),

            _buildSectionLabel("Making Charges"),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _makingChargesController,
                    hint: "Charge amount",
                  ),
                ),
                const SizedBox(width: 12),
                _buildDropdown(_makingChargeType, [
                  '%',
                  'Flat',
                ], (v) => setState(() => _makingChargeType = v!)),
              ],
            ),

            _buildSectionLabel("Discount"),
            _buildTextField(_discountController, hint: "0"),

            _buildSectionLabel("Product Details"),
            _buildTextField(
              _productDetailsController,
              maxLines: 3,
              hint: "Description of the product...",
            ),

            _buildSectionLabel("Specifications"),
            _buildTextField(
              _specificationsController,
              maxLines: 3,
              hint: "Size, Purity, etc.",
            ),

            const SizedBox(height: 16),

            InkWell(
              onTap: () =>
                  setState(() => _hallmarkAvailable = !_hallmarkAvailable),
              child: Row(
                children: [
                  Checkbox(
                    value: _hallmarkAvailable,
                    activeColor: primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (v) => setState(() => _hallmarkAvailable = v!),
                  ),
                  const Text(
                    "Hallmark available",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => debugPrint("Product Saved!"),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            "Save",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    _stoneWeightController.dispose();
    _stoneCostController.dispose();
    _makingChargesController.dispose();
    _discountController.dispose();
    _productDetailsController.dispose();
    _specificationsController.dispose();
    super.dispose();
  }
}
