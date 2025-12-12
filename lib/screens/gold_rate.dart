import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Color _kPrimaryColor = Color(0xFF673AB7); // Dark Purple for main buttons
const Color _kBackgroundColor = Color(0xFFF3F0F9); // Light Lilac background
const Color _kCardColor = Colors.white;
const double _kCardRadius = 12.0;
const TextStyle _kLabelStyle = TextStyle(
  color: Colors.black54,
  fontSize: 14.0,
  fontWeight: FontWeight.w400,
);
const TextStyle _kRateValueStyle = TextStyle(
  color: Colors.black,
  fontSize: 32.0,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.5,
);
const TextStyle _kRateUnitStyle = TextStyle(
  color: Colors.black54,
  fontSize: 16.0,
  fontWeight: FontWeight.w400,
);

class GoldRatesScreen extends StatefulWidget {
  const GoldRatesScreen({super.key});

  @override
  State<GoldRatesScreen> createState() => _GoldRatesScreenState();
}

class _GoldRatesScreenState extends State<GoldRatesScreen> {
  String goldPrice = 'N/A';
  String goldUpdateTimestamp = 'N/A';
  String silverPrice = 'N/A';
  String silverUpdateTimestamp = 'N/A';

  bool isGoldLoading = false;
  String goldError = '';

  @override
  void initState() {
    super.initState();
    fetchLiveRates();
  }

  Future<void> fetchLiveRates() async {
    if (mounted) {
      setState(() {
        isGoldLoading = true;
        goldError = '';
      });
    }

    try {
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final url = Uri.parse(
        'https://statewisebcast.dpgold.in:7768/VOTSBroadcastStreaming/Services/xml/GetLiveRateByTemplateID/dpgold?_= $timestamp',
      );
      final response = await http.get(url);
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        String newGoldPrice = 'No gold data found';
        String newSilverPrice = 'No silver data found';
        final rates = _parseLiveRates(response.body);
        newGoldPrice = rates['goldPrice'] ?? newGoldPrice;
        newSilverPrice = rates['silverPrice'] ?? newSilverPrice;

        final now = DateTime.now();

        if (mounted) {
          setState(() {
            goldPrice = newGoldPrice;
            silverPrice = newSilverPrice;
            goldUpdateTimestamp =
                'Last updated on ${TimeOfDay.fromDateTime(now).format(context)}, ${now.day} ${monthName(now.month)} ${now.year}';
            silverUpdateTimestamp =
                'Last updated on ${TimeOfDay.fromDateTime(now).format(context)}, ${now.day} ${monthName(now.month)} ${now.year}';
            isGoldLoading = false;
          });
        }
      } else {
        throw Exception('API Status: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final msg = e.toString();
          goldError = msg.length > 80
              ? 'Error: ${msg.substring(0, 80)}...'
              : 'Error: $msg';
          isGoldLoading = false;
        });
      }
    }
  }

  Map<String, String> _parseLiveRates(String body) {
    String foundGold = 'N/A';
    String foundSilver = 'N/A';
    List<String> lines = body.split('\n');
    for (String line in lines) {
      if (line.contains('GOLD') &&
          line.contains('999') &&
          line.contains('/ 10 Gm')) {
        List<String> cols = line.split('\t');
        if (cols.length >= 6) {
          foundGold = '₹${_formatPrice(cols[3])}';
        }
      }

      if (line.contains('SILVER 30 KG PAN India')) {
        List<String> cols = line.split('\t');
        if (cols.length >= 6) {
          foundSilver = '₹${_formatPrice(cols[3])}';
        }
      }
      if (foundGold != 'N/A' && foundSilver != 'N/A') break;
    }

    return {'goldPrice': foundGold, 'silverPrice': foundSilver};
  }

  String _formatPrice(String price) {
    try {
      final double value = double.tryParse(price) ?? 0.0;
      return value.toStringAsFixed(2);
    } catch (e) {
      return price;
    }
  }

  String monthName(int month) {
    const months = [
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
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        backgroundColor: _kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Admin',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
        ),
      ),
      body: Column(
        children: [
          _buildRateProductToggles(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 250,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildRateCard(
                          title: 'CURRENT GOLD RATE',
                          rate: goldPrice,
                          unit: 'per 10g',
                          updateInfo: goldUpdateTimestamp,
                          isLoading: isGoldLoading,
                          error: goldError,
                        ),
                        const SizedBox(width: 16),
                        _buildRateCard(
                          title: 'CURRENT SILVER RATE',
                          rate: silverPrice,
                          unit: 'per KG',
                          updateInfo: silverUpdateTimestamp,
                          isLoading: isGoldLoading,
                          error: goldError,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateProductToggles() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 16.0,
              ),
              decoration: BoxDecoration(
                color: _kPrimaryColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Center(
                child: Text(
                  'Rate update',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 16.0,
              ),
              child: Center(
                child: Text(
                  'Product update',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateCard({
    required String title,
    required String rate,
    required String unit,
    required String updateInfo,
    required bool isLoading,
    required String error,
  }) {
    final cardWidth = MediaQuery.of(context).size.width * 0.9;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: _kCardColor,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: _kLabelStyle.copyWith(
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: fetchLiveRates,
                child: const Icon(Icons.history, color: _kPrimaryColor),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator(color: _kPrimaryColor)
                  : error.isNotEmpty
                  ? Text(
                      error,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(rate, style: _kRateValueStyle),
                        Text(unit, style: _kRateUnitStyle),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Text(updateInfo, style: _kLabelStyle),
        ],
      ),
    );
  }
}
