import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zomogoldapp/screens/product_details.dart';

import '../dao/product_rate_dao.dart';
import '../models/product_rate_model.dart';

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
    final double livePrice = selectedMetal == 'GOLD'
        ? goldRawPrice
        : silverRawPrice;
    if (manualPrice == null || manualPrice <= 0) {
      _showSnackBar('Please enter a valid rate');
      return;
    }

    if (livePrice > 0) {
      double tolerance = livePrice * 0.05;
      if ((manualPrice - livePrice).abs() > tolerance) {
        _showSnackBar('Rate is too far from live market rate!');
        return;
      }
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
    return Column(
      children: [
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => selectedMetal = index == 0 ? 'GOLD' : 'SILVER');
            },
            children: [
              _buildRateCard('GOLD', goldPriceFormatted, 'per 1g'),
              _buildRateCard('SILVER', silverPriceFormatted, 'per KG'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Padding(
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
                  keyboard: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildFormTextField(
                    _remarksController,
                    'Remarks',
                    isMultiline: true,
                  ),
                ),
                const SizedBox(height: 16),
                _buildUpdateRateButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
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
                color: isActive ? Colors.white : Colors.black54,
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
      maxLines: isMultiline ? null : 1,
      expands: isMultiline,
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CURRENT $metal RATE',
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.history, color: _kPrimaryColor),
                onPressed: fetchLiveRates,
              ),
            ],
          ),
          const Spacer(),
          if (isLoading)
            const CircularProgressIndicator(color: _kPrimaryColor)
          else ...[
            Text(
              price,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),
            Text(
              unit,
              style: const TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ],
          const Spacer(),
          Text(
            updateTimestamp,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
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
