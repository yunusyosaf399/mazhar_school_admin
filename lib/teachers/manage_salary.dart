import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:intl/intl.dart';
class ManageSalaryScreen extends StatefulWidget {
  @override
  _ManageSalaryScreenState createState() => _ManageSalaryScreenState();
}

class _ManageSalaryScreenState extends State<ManageSalaryScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _salaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSalaries();
  }

  Future<void> _fetchSalaries() async {
    try {
      final response = await _supabase.from('salary').select('*').neq('status', 'paid');

      setState(() {
        _salaries = response.map<Map<String, dynamic>>((salary) {
          final mappedSalary = Map<String, dynamic>.from(salary as Map);
          final String? createdAt = mappedSalary['created_at']?.toString();

          print("Raw created_at value: $createdAt");

          String monthYear = 'Unknown';
          if (createdAt != null) {
            try {
              monthYear = DateFormat('MMMM yyyy').format(DateTime.parse(createdAt));
            } catch (e) {
              print("Error parsing date: $e");
            }
          }

          print("Extracted Month and Year: $monthYear");

          return {
            ...mappedSalary,
            'amount_paid': (mappedSalary['amount_paid'] as num?)?.toDouble() ?? 0.0,
            'salary': (mappedSalary['salary'] as num?)?.toDouble() ?? 0.0,
            'month': monthYear,
            'created_date': createdAt != null
                ? DateFormat('yyyy-MM-dd').format(DateTime.parse(createdAt))
                : 'Unknown',
          };
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching salaries: $e');
      setState(() => _isLoading = false);
    }
  }








  Future<void> _updateSalaryAndGenerateInvoice(int serialNo, String teacherId, double amountPaid, num currentPaid, num salary) async {
    if (amountPaid + currentPaid > salary) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Enter amount less than remaining salary', style: TextStyle(color: Colors.red)),
      ));
      return;
    }

    double newAmountPaid = amountPaid + currentPaid.toDouble();
    double totalSalary = salary.toDouble();
    String status = newAmountPaid >= totalSalary ? 'paid' : 'partial';

    try {
      await _supabase.from('salary').update({
        'amount_paid': newAmountPaid,
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).match({'serial_no': serialNo, 'teacher_id': teacherId});

      final updatedSalary = await _supabase
          .from('salary')
          .select('*')
          .match({'serial_no': serialNo, 'teacher_id': teacherId})
          .single();

      // ✅ Ensure "month" is extracted safely
      String monthYear = 'Unknown';
      if (updatedSalary['created_at'] != null) {
        try {
          monthYear = DateFormat('MMMM yyyy').format(DateTime.parse(updatedSalary['created_at'].toString()));
        } catch (e) {
          print("Error parsing created_at: $e");
        }
      }

      final Map<String, dynamic> processedSalary = {
        ...updatedSalary,
        'month': monthYear,
      };

      print("Updated Salary Data (Before PDF): $processedSalary");

      _generateInvoice(processedSalary);  // Now month should be available
      await _fetchSalaries();
    } catch (e) {
      print('Error updating salary: $e');
    }
  }



  Future<void> _generateInvoice(Map<String, dynamic> salary) async {
    print("Generating PDF with data: $salary");  // Debugging

    final pdf = pw.Document();
    final logo = pw.MemoryImage(
      File('assets/images/logo.png').readAsBytesSync(),
    );

    // 📌 Get Current Date in "dd MMMM yyyy" format
    String currentDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 1),
            ),
            padding: pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Image(logo, width: 30),
                    pw.SizedBox(width: 10),
                    pw.Text('Mazhar Public School and Dar-Ul-Uloom Azizia', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Text('Address: 123 School Street, City, Country', style: pw.TextStyle(fontSize: 8)),
                pw.Text('Contact: +123 456 7890', style: pw.TextStyle(fontSize: 8)),
                pw.Divider(),

                // 📌 Teacher Copy
                pw.Text('Teacher Copy', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('Month: ${salary['month'] ?? 'Unknown'}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: $currentDate', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)), // ✅ Add Current Date
                pw.Text('Teacher Name: ${salary['name']}', style: pw.TextStyle(fontSize: 8)),
                pw.Text('Serial No: ${salary['serial_no']}', style: pw.TextStyle(fontSize: 8)),
                pw.Text('Salary: ${salary['salary']}', style: pw.TextStyle(fontSize: 8)),
                pw.Text('Amount Paid: ${salary['amount_paid']}', style: pw.TextStyle(fontSize: 8)),
                pw.Text('Status: ${salary['status']}', style: pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.Text('Signature:', style: pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 20),
                pw.Divider(),

                // 📌 Office Copy
                pw.Row(
                  children: [
                    pw.Image(logo, width: 30),
                    pw.SizedBox(width: 10),
                    pw.Text('Mazhar Public School and Dar-Ul-Uloom Azizia', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Text('Office Copy', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('Month: ${salary['month'] ?? 'Unknown'}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: $currentDate', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)), // ✅ Add Current Date
                pw.Text('Teacher Name: ${salary['name']}', style: pw.TextStyle(fontSize: 8)),
                pw.Text('Serial No: ${salary['serial_no']}', style: pw.TextStyle(fontSize: 8)),
                pw.Text('Salary: ${salary['salary']}', style: pw.TextStyle(fontSize: 8)),
                pw.Text('Amount Paid: ${salary['amount_paid']}', style: pw.TextStyle(fontSize: 8)),
                pw.Text('Status: ${salary['status']}', style: pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 8),
                pw.Text('Signature:', style: pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 20),
                pw.Divider(),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Salaries')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _salaries.length,
        itemBuilder: (context, index) {
          final salary = _salaries[index];
          final TextEditingController amountController = TextEditingController();

          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text(salary['name']),
              subtitle: Text(
                'Month: ${salary['month']} | Status: ${salary['status']} | Paid: ${salary['amount_paid']} / ${salary['salary']}',
              ),
              trailing: IconButton(
                icon: Icon(Icons.payment),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Update Payment'),
                        content: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(hintText: 'Enter amount paid'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              double amountPaid = double.tryParse(amountController.text) ?? 0;
                              await _updateSalaryAndGenerateInvoice(
                                salary['serial_no'],
                                salary['teacher_id'],
                                amountPaid,
                                salary['amount_paid'],
                                salary['salary'],
                              );
                              Navigator.pop(context);
                            },
                            child: Text('Update & Print Invoice'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}