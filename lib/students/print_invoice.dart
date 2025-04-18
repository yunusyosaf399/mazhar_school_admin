import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mazhar/students/invoice.dart';

class PrintInvoicePage extends StatefulWidget {
  const PrintInvoicePage({super.key});

  @override
  State<PrintInvoicePage> createState() => _PrintInvoicePageState();
}

List<String> months = [];

class _PrintInvoicePageState extends State<PrintInvoicePage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> studentInvoices = [];
  List<Map<String, dynamic>> filteredInvoices = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchInvoiceData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text.toLowerCase();
      filteredInvoices = studentInvoices.where((student) {
        final name = student['student_name'].toString().toLowerCase();
        return name.contains(searchQuery);
      }).toList();
    });
  }

  Future<void> fetchInvoiceData() async {
    final now = DateTime.now();
    months = List.generate(12, (i) {
      final date = DateTime(now.year, now.month - i, 1);
      return DateFormat('yyyy-MM').format(date);
    });
    final last12MonthsSet = months.toSet();

    try {
      final otherAmountsResponse = await supabase.from('other_amounts').select();
      final List<Map<String, dynamic>> otherAmounts = List<Map<String, dynamic>>.from(otherAmountsResponse);

      // Fetch fee data
      final response = await supabase.from('fee').select().order('student_name', ascending: true);
      final rawFees = response as List;

      final Map<String, Map<String, dynamic>> studentsMap = {};

      for (var row in rawFees) {
        final key = '${row['serial_no']}|${row['student_name']}';

        if (!studentsMap.containsKey(key)) {
          studentsMap[key] = {
            'student_name': row['student_name'],
            'class': row['class'],
            'serial_no': row['serial_no'],
            'father_name': row['father_name'],
            'monthly_fee': row['monthly_fee'],
            'records': {},
            'previous_dues': 0,
          };
        }

        final month = row['month'];
        final dues = int.tryParse('${row['dues'] ?? 0}') ?? 0;

        if (last12MonthsSet.contains(month)) {
          studentsMap[key]!['records'][month] = {
            'amount_paid': row['amount_paid'],
            'dues': dues,
            'status': row['status'],
          };
        } else {
          studentsMap[key]!['previous_dues'] += dues;
        }
      }

      studentInvoices = studentsMap.entries.map((entry) {
        final student = entry.value;
        final monthlyRecords = <Map<String, dynamic>>[];

        for (var month in months.reversed) {
          final record = student['records'][month];
          monthlyRecords.add({
            'month': DateFormat('MMM yyyy').format(DateTime.parse('$month-01')),
            'amount_paid': record?['amount_paid'] ?? 0,
            'dues': record?['dues'] ?? student['dues'],
            'status': record?['status'] ?? 'pending',
          });
        }

        return {
          ...student,
          'records': monthlyRecords,
        };
      }).toList();

      // Map other amounts to each student by serial_no
      for (var student in studentInvoices) {
        final serialNo = student['serial_no'];
        student['other_amounts'] = otherAmounts
            .where((entry) => entry['serial_no'] == serialNo)
            .toList();
      }

      filteredInvoices = List.from(studentInvoices);
      setState(() => isLoading = false);
    } catch (e) {
      print('Error fetching invoice data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Invoices")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Student Name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredInvoices.length,
              itemBuilder: (context, index) {
                final student = filteredInvoices[index];
                final records = student['records'] as List;
                final int previousDues = student['previous_dues'] ?? 0;
                final int totalDues = records.fold<int>(
                  previousDues,
                      (sum, r) => sum + int.tryParse('${r['dues'] ?? 0}')!,
                );

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student['student_name'],
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                                'Class: ${student['class']} • Serial No: ${student['serial_no']}'),
                            Text('Father: ${student['father_name']}'),
                            Text('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
                            const SizedBox(height: 4),
                            Text('Monthly Fee: Rs. ${student['monthly_fee']}'),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(flex: 3,
                                      child: Text('Month', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2,
                                      child: Text('Paid', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2,
                                      child: Text('Dues', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2,
                                      child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),
                            const Divider(),
                            for (var record in records)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(flex: 3,
                                        child: Text(record['month'], overflow: TextOverflow.ellipsis)),
                                    Expanded(flex: 2,
                                        child: Text('Rs. ${record['amount_paid']}')),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        record['dues'] == null
                                            ? 'NA'
                                            : 'Rs. ${record['dues']}',
                                        style: TextStyle(
                                          color: record['dues'] == null
                                              ? Colors.grey
                                              : (int.tryParse('${record['dues']}') ?? 0) > 0
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                      ),
                                    ),
                                    // Status
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        record['dues'] == null ? 'NA' : record['status'],
                                        style: TextStyle(
                                          color: record['dues'] == null
                                              ? Colors.grey
                                              : record['status'] == 'paid'
                                              ? Colors.green
                                              : Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Divider(height: 20),
                            Text(
                              months.isNotEmpty
                                  ? 'Previous Dues (before ${months.last}): Rs. $previousDues'
                                  : 'Previous Dues: Rs. $previousDues',
                              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Total Dues: Rs. $totalDues',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.redAccent,
                              ),
                            ),
                            // Other Amounts Section (Safe to inline)
                            if ((student['other_amounts'] ?? []).isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Other Amounts:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const SizedBox(height: 6),
                              for (var other in student['other_amounts'])
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 3, child: Text(other['amount_type'])),
                                      Expanded(flex: 2, child: Text('Rs. ${other['amount']}')),
                                      Expanded(flex: 2, child: Text('Paid: Rs. ${other['amount_paid'] ?? 0}', style: const TextStyle(color: Colors.green))),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Due: Rs. ${(num.tryParse('${other['amount']}') ?? 0) - (num.tryParse('${other['amount_paid'] ?? 0}') ?? 0)}',
                                          style: const TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.print),
        label: const Text("Save All Invoices"),
        onPressed: () async {
          // Call the method to save the invoice as a PDF
          await saveInvoiceAsPdf(studentInvoices);

          // Optionally, you can show a confirmation message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoices saved as PDF!')),
          );
        },
      ),
    );
  }
}
