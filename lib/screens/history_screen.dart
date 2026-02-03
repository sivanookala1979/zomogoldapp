import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dao/product_rate_dao.dart';
import '../models/product_rate_model.dart';

const Color _kPrimaryColor = Color(0xFF673AB7);
const Color _kBackgroundColor = Color(0xFFF3F0F9);

class PriceHistoryScreen extends StatefulWidget {
  final String productType;

  const PriceHistoryScreen({super.key, required this.productType});

  @override
  State<PriceHistoryScreen> createState() => _PriceHistoryScreenState();
}

class _PriceHistoryScreenState extends State<PriceHistoryScreen> {
  String selectedRange = "6 Months";
  final List<String> ranges = [
    "1 Day",
    "1 Week",
    "1 Month",
    "3 Months",
    "6 Months",
    "1 Year",
  ];
  final ProductRateDao _dao = ProductRateDao();

  Map<String, int> _getTimestamps() {
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (selectedRange) {
      case "1 Day":
        start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case "1 Week":
        start = now.subtract(const Duration(days: 7));
        break;
      case "1 Month":
        start = DateTime(now.year, now.month - 1, now.day);
        break;
      case "3 Months":
        start = DateTime(now.year, now.month - 3, now.day);
        break;
      case "1 Year":
        start = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        start = DateTime(now.year, now.month - 6, now.day);
    }
    return {
      "start": start.millisecondsSinceEpoch,
      "end": end.millisecondsSinceEpoch,
    };
  }

  @override
  Widget build(BuildContext context) {
    final times = _getTimestamps();

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        backgroundColor: _kBackgroundColor,
        leading: const BackButton(color: Colors.black),
        title: Text(
          "${widget.productType} History",
          style: const TextStyle(color: Colors.black),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<ProductRateModel>>(
        stream: _dao.getFilteredRates(
          widget.productType,
          times['start']!,
          times['end']!,
        ),
        builder: (context, snapshot) {
          final data = snapshot.data ?? [];
          final bool isLoading =
              snapshot.connectionState == ConnectionState.waiting;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButton<String>(
                      value: selectedRange,
                      underline: const SizedBox(),
                      items: ranges
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedRange = val!),
                    ),
                  ),
                ),
              ),
              _buildLegend(),
              _buildGraphCard(data, isLoading),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Text(
                  "Price History",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(indent: 20, endIndent: 20),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : data.isEmpty
                    ? const Center(
                        child: Text("No data found for this selection"),
                      )
                    : _buildHistoryList(data),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGraphCard(List<ProductRateModel> data, bool isLoading) {
    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF673AB7), width: 1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LineChart(_mainData(data)),
    );
  }
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Row(
        children: [
          _legendItem(
            color: _kPrimaryColor,
            text: "Rate",
          ),
          const SizedBox(width: 16),
          _legendItem(
            color: const Color(0xFF00B4D8),
            text: "Live Rate",
          ),
        ],
      ),
    );
  }
  Widget _legendItem({required Color color, required String text}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  LineChartData _mainData(List<ProductRateModel> data) {
    List<ProductRateModel> sortedData = data.reversed.toList();
    final manualSpots = sortedData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.price);
    }).toList();

    final liveSpots = sortedData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.livePrice);
    }).toList();

    final allYValues = [
      ...manualSpots.map((e) => e.y),
      ...liveSpots.map((e) => e.y),
    ];

    late final minY = allYValues.reduce((a, b) => a < b ? a : b) * 0.995;
    late final maxY = allYValues.reduce((a, b) => a > b ? a : b) * 1.005;
    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(
        show: true,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) => Text(
              '${value.toInt()}',
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (sortedData.length > 5) ? (sortedData.length / 5) : 1,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index >= 0 && index < sortedData.length) {
                DateTime date = DateTime.fromMillisecondsSinceEpoch(
                  sortedData[index].timestamp,
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat(
                      selectedRange == "1 Day" ? 'HH:mm' : 'dd/MM',
                    ).format(date),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      lineBarsData: [
        if (data.isNotEmpty)
          LineChartBarData(
            spots: manualSpots,
            isCurved: true,
            color: _kPrimaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: _kPrimaryColor.withOpacity(0.1),
            ),
          ),
        LineChartBarData(
          spots: liveSpots,
          isCurved: true,
          color: const Color(0xFF00B4D8),
          barWidth: 2,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: _kPrimaryColor.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(List<ProductRateModel> data) {
    return ListView.separated(
      itemCount: data.length,
      separatorBuilder: (_, __) =>
          const Divider(indent: 20, endIndent: 20, height: 1),
      itemBuilder: (context, index) {
        final item = data[index];
        final date = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
        String dateDisplay = (selectedRange == "1 Day")
            ? "Today, ${DateFormat('hh:mm a').format(date)}"
            : DateFormat('dd MMM yyyy').format(date);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          title: Text(
            dateDisplay,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: Text(
            "₹ ${NumberFormat('#,##,###.00').format(item.price)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _kPrimaryColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Category"),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          label: "Orders",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: "Profile",
        ),
      ],
    );
  }
}
