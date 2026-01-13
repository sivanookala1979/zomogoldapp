import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:zomogoldapp/screens/product_details.dart';

import '../dao/product_rate_dao.dart';
import '../models/product_rate_model.dart';
import 'history_screen.dart';

const Color _kPrimaryColor = Color(0xFF673AB7);
const Color _kBackgroundColor = Color(0xFFF3F0F9);

enum AdminTab { rateUpdate, productUpdate }

class GoldRatesScreen extends StatefulWidget {
  const GoldRatesScreen({super.key});

  @override
  State<GoldRatesScreen> createState() => _GoldRatesScreenState();
}

class _GoldRatesScreenState extends State<GoldRatesScreen> {
  AdminTab _activeTab = AdminTab.rateUpdate;
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  final ProductRateDao _rateDao = ProductRateDao();

  String selectedMetal = 'GOLD';
  String goldPriceFormatted = 'N/A';
  String silverPriceFormatted = 'N/A';
  double goldRawPrice = 0.0;
  double silverRawPrice = 0.0;
  String updateTimestamp = 'N/A';
  bool isLoading = false;

  final TextEditingController _manualRateController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchLiveRates();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    double offset = _scrollController.offset;
    double maxScroll = _scrollController.position.maxScrollExtent;

    String newMetal = offset > (maxScroll / 2) ? 'SILVER' : 'GOLD';

    if (newMetal != selectedMetal) {
      setState(() {
        selectedMetal = newMetal;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _manualRateController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> fetchLiveRates() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = Uri.parse(
        'https://statewisebcast.dpgold.in:7768/VOTSBroadcastStreaming/Services/xml/GetLiveRateByTemplateID/dpgold?_=$timestamp',
      );
      final response = await http.get(url);
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> ratesData = _parseLiveRates(response.body);
        final now = DateTime.now();
        if (mounted) {
          setState(() {
            goldPriceFormatted = ratesData['goldPriceFormatted'];
            silverPriceFormatted = ratesData['silverPriceFormatted'];
            goldRawPrice = ratesData['goldPriceRaw'];
            silverRawPrice = ratesData['silverPriceRaw'];
            updateTimestamp =
                'Last updated on ${TimeOfDay.fromDateTime(now).format(context)}, ${now.day} ${_monthName(now.month)} ${now.year}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleManualUpdate() async {
    final String enteredValue = _manualRateController.text.trim();
    final double? manualPrice = double.tryParse(enteredValue);
    if (manualPrice == null || manualPrice <= 0) {
      _showSnackBar('Please enter a valid rate');
      return;
    }

    try {
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      final model = ProductRateModel(
        id: '${selectedMetal}_$timestamp',
        productType: selectedMetal,
        price: manualPrice,
        unit: selectedMetal == 'GOLD' ? 'per 1g' : 'per KG',
        userId: 'admin',
        timestamp: timestamp,
        remarks: _remarksController.text.trim(),
      );

      await _rateDao.addRateEntry(model);
      _showSnackBar('$selectedMetal rate updated successfully!');
      _manualRateController.clear();
      _remarksController.clear();
    } catch (e) {
      _showSnackBar('Error updating rate: $e');
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        backgroundColor: _kBackgroundColor,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Text('Admin', style: TextStyle(color: Colors.black)),
      ),
      body: Column(
        children: [
          _buildUnifiedToggles(),
          const SizedBox(height: 10),
          Expanded(
            child: _activeTab == AdminTab.rateUpdate
                ? _buildRateUpdateView()
                : const ProductDetailsPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildRateUpdateView() {
    double screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: RawScrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              thickness: 8,
              radius: const Radius.circular(20),
              thumbColor: _kPrimaryColor.withOpacity(0.9),
              interactive: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const PageScrollPhysics(),
                  child: Row(
                    children: [
                      SizedBox(
                        width: screenWidth - 32,
                        height: 280,
                        child: _buildRateCard(
                          'GOLD',
                          goldPriceFormatted,
                          'per 1g',
                        ),
                      ),
                      SizedBox(
                        width: screenWidth - 32,
                        height: 280,
                        child: _buildRateCard(
                          'SILVER',
                          silverPriceFormatted,
                          'per KG',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Text(
                  'UPDATE $selectedMetal RATE',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFormTextField(
                  _manualRateController,
                  'Update new rate (Per ${selectedMetal == 'GOLD' ? 'gram/tola' : 'kg'})',
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFormTextField(
                  _remarksController,
                  'Remarks',
                  isMultiline: true,
                ),
                const SizedBox(height: 16),
                _buildUpdateRateButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedToggles() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _tabButton('Rate update', AdminTab.rateUpdate),
          _tabButton('Product update', AdminTab.productUpdate),
        ],
      ),
    );
  }

  Widget _tabButton(String title, AdminTab tab) {
    final isActive = _activeTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? _kPrimaryColor : Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormTextField(
    TextEditingController controller,
    String hint, {
    bool isMultiline = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters:
          keyboard == const TextInputType.numberWithOptions(decimal: true)
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : null,
      maxLines: isMultiline ? 10 : 1,
      minLines: isMultiline ? 10 : 1,
      textAlignVertical: isMultiline
          ? TextAlignVertical.top
          : TextAlignVertical.center,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kPrimaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildProductRow(
    String label,
    String initial, {
    bool isCurrency = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 48,
              child: TextField(
                decoration: InputDecoration(
                  prefixText: isCurrency ? '₹ ' : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kPrimaryColor),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateCard(String metal, String price, String unit) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          Text(
            'CURRENT $metal RATE',
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isLoading)
            SizedBox(
              height: 43,
              child: Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    color: _kPrimaryColor,
                    strokeWidth: 3,
                  ),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                    height: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.refresh,
                    color: _kPrimaryColor,
                    size: 30,
                  ),
                  onPressed: fetchLiveRates,
                ),
              ],
            ),

          Text(
            unit,
            style: const TextStyle(color: Colors.black54, fontSize: 16),
          ),
          Text(
            updateTimestamp,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PriceHistoryScreen(productType: selectedMetal),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              elevation: 2,
            ),
            child: const Text(
              'View History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateRateButton() {
    return ElevatedButton(
      onPressed: _handleManualUpdate,
      style: ElevatedButton.styleFrom(
        backgroundColor: _kPrimaryColor,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: const Text(
        'Update Rate',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Map<String, dynamic> _parseLiveRates(String body) {
    double goldRaw = 0.0;
    double silverRaw = 0.0;
    List<String> lines = body.split('\n');
    for (String line in lines) {
      if (line.contains('GOLD') &&
          line.contains('999') &&
          line.contains('/ 10 Gm')) {
        List<String> cols = line.split('\t');
        if (cols.length >= 6) goldRaw = double.tryParse(cols[3]) ?? 0.0;
      } else if (line.contains('SILVER 30 KG PAN India')) {
        List<String> cols = line.split('\t');
        if (cols.length >= 6) silverRaw = double.tryParse(cols[3]) ?? 0.0;
      }
    }
    return {
      'goldPriceFormatted': '₹${goldRaw.toStringAsFixed(2)}',
      'goldPriceRaw': goldRaw,
      'silverPriceFormatted': '₹${silverRaw.toStringAsFixed(2)}',
      'silverPriceRaw': silverRaw,
    };
  }

  String _monthName(int month) {
    const m = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return m[month];
  }
}
