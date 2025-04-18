import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class FeeAnalyticsWidget extends StatefulWidget {
  const FeeAnalyticsWidget({Key? key}) : super(key: key);

  @override
  State<FeeAnalyticsWidget> createState() => _FeeAnalyticsWidgetState();
}

class _FeeAnalyticsWidgetState extends State<FeeAnalyticsWidget> {
  int totalCollected = 0;
  int totalDues = 0;
  int paidCount = 0;
  int pendingCount = 0;
  Map<String, int> feeByClass = {};
  bool loading = true;
  bool showDetailedAnalytics = false;

  String selectedRange = 'Monthly';

  final Map<String, Duration> durationMap = {
    'Monthly': Duration(days: 30),
    'Yearly': Duration(days: 365),
    '2 Years': Duration(days: 730),
  };

  @override
  void initState() {
    super.initState();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    setState(() => loading = true);
    final supabase = Supabase.instance.client;
    final now = DateTime.now();
    final startDate = now.subtract(durationMap[selectedRange]!);

    final response = await supabase
        .from('fee')
        .select()
        .gte('created_at', startDate.toIso8601String());

    final List data = response;

    int collected = 0;
    int dues = 0;
    int paid = 0;
    int pending = 0;
    Map<String, int> byClass = {};

    for (final row in data) {
      final int paidAmount = (row['amount_paid'] ?? 0).toInt();
      final int dueAmount = (row['dues'] ?? 0).toInt();
      final String status = row['status'] ?? 'pending';
      final String className = row['class'] ?? 'Unknown';

      collected += paidAmount;
      dues += dueAmount;
      status == 'paid' ? paid++ : pending++;

      byClass[className] = (byClass[className] ?? 0) + paidAmount;
    }

    setState(() {
      totalCollected = collected;
      totalDues = dues;
      paidCount = paid;
      pendingCount = pending;
      feeByClass = byClass;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
      children: [
        // Range selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
          child: DropdownButtonFormField<String>(
            value: selectedRange,
            items: durationMap.keys
                .map((label) => DropdownMenuItem(
                value: label, child: Text(label)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedRange = value);
                fetchAnalytics();
              }
            },
            decoration: InputDecoration(
              labelText: "Select Duration",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),

        // Summary Card
        Card(
          margin: const EdgeInsets.all(4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text("Analytics Summary - $selectedRange",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildStatCard("Total Collected", "Rs.$totalCollected", Colors.green)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard("Total Dues", "Rs.  $totalDues", Colors.red)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildStatCard("Paid", "$paidCount", Colors.blue)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard("Pending", "$pendingCount", Colors.orange)),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showDetailedAnalytics = !showDetailedAnalytics;
                    });
                  },
                  child: Text(showDetailedAnalytics
                      ? "Hide Detailed Analytics"
                      : "Show Detailed Analytics"),
                ),
              ],
            ),
          ),
        ),

        // Detailed Analytics
        if (showDetailedAnalytics)
          Card(
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  const Text("Fee Collected by Class",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 240,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: feeByClass.length * 30,
                        child: _BarChart(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _BarChart() {
    final barData = feeByClass.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= barData.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    barData[value.toInt()].key,
                    style: const TextStyle(fontSize: 7),
                    textAlign: TextAlign.center,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1000,
              reservedSize: 35,
              getTitlesWidget: (value, meta) =>
                  Text("Rs. ${value.toInt()}", style: const TextStyle(fontSize: 10)),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barData.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value.value.toDouble();
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: Colors.deepPurple,
                width: 8,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
