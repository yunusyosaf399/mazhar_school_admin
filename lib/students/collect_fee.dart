import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CollectFeePage extends StatefulWidget {
  const CollectFeePage({super.key});

  @override
  State<CollectFeePage> createState() => _CollectFeePageState();
}

class _CollectFeePageState extends State<CollectFeePage> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<dynamic> allFeeRecords = [];
  List<dynamic> filteredFeeRecords = [];
  bool isLoading = true;
  String searchQuery = '';
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    fetchFeeRecords();
  }

  Future<void> fetchFeeRecords() async {
    setState(() => isLoading = true);
    try {
      final data = await supabase
          .from('fee')
          .select('id, student_name, serial_no, father_name, amount_paid, dues, class, month, status')
          .order('created_at', ascending: false);

      setState(() {
        allFeeRecords = data;
        filteredFeeRecords = allFeeRecords;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching fee records: $e');
      setState(() => isLoading = false);
    }
  }

  void filterRecords(String query) {
    final filtered = allFeeRecords.where((record) {
      final studentName = (record['student_name'] ?? '').toLowerCase();
      return studentName.contains(query.toLowerCase());
    }).toList();

    setState(() {
      searchQuery = query;
      filteredFeeRecords = filtered;
    });
  }

  Future<void> _showCollectFeePopup(Map<String, dynamic> record) async {
    if (_isDialogOpen) return; // Prevent opening the dialog multiple times
    _isDialogOpen = true;

    final feeStructure = await supabase
        .from('fee_structure')
        .select()
        .eq('class_name', record['class'])
        .maybeSingle();

    if (feeStructure == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No fee structure found for this class")),
        );
      }
      _isDialogOpen = false;
      return;
    }

    final double feeAmount = double.tryParse(feeStructure['fee_amount'].toString()) ?? 0;
    final double alreadyPaid = double.tryParse(record['amount_paid'].toString()) ?? 0;
    final double remainingFee = feeAmount - alreadyPaid;

    if (!mounted) return;

    // Show custom dialog
    await showDialog(
      context: context,
      builder: (context) {
        return CollectFeeDialog(
          record: record,
          feeAmount: feeAmount,
          remainingFee: remainingFee,
          onSubmit: (double enteredAmount) async {
            if (enteredAmount == null || enteredAmount <= 0) {
              return "Enter a valid amount";
            }

            if (enteredAmount > remainingFee) {
              return "Amount exceeds remaining fee";
            }

            final double newAmountPaid = alreadyPaid + enteredAmount;
            final String newStatus = (newAmountPaid >= feeAmount) ? 'paid' : 'partial';
            final int newMonthlyDues = (feeAmount - newAmountPaid).clamp(0, feeAmount).toInt();

            try {
              await supabase.from('fee').update({
                'amount_paid': newAmountPaid.toInt(),
                'status': newStatus,
                'dues': newMonthlyDues,
                'updated_at': DateTime.now().toIso8601String(),
              }).eq('id', record['id']);

              if (mounted) {
                await fetchFeeRecords();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Fee ${newStatus == 'paid' ? 'fully' : 'partially'} collected")),
                );
              }
            } catch (e) {
              debugPrint('Error updating fee: $e');
              return "Something went wrong. Try again.";
            }

            return null;
          },
        );
      },
    );

    _isDialogOpen = false;
  }

  Widget buildFeeCard(Map<String, dynamic> record) {
    final String status = record['status'] ?? 'pending';

    Color statusColor = Colors.orange;
    Color cardColor = Colors.orange[50]!;

    if (status.toLowerCase() == 'paid') {
      statusColor = Colors.green;
      cardColor = Colors.green[50]!;
    } else if (status.toLowerCase() == 'pending') {
      statusColor = Colors.red;
      cardColor = Colors.red[50]!;
    }

    return Center(
      child: SizedBox(
        width: 320, // Set your desired card width here
        child: Card(
          color: cardColor,
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${record['student_name']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('Serial No: ${record['serial_no'] ?? 'N/A'}', style: const TextStyle(fontSize: 15)),
                Text('Class: ${record['class']} | Month: ${record['month']}', style: const TextStyle(fontSize: 13)),
                Text('Paid: PKR ${record['amount_paid']} | Fee: PKR ${record['dues'] ?? 'N/A'}', style: const TextStyle(fontSize: 13)),
                Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    if (status.toLowerCase() != 'paid')
                      TextButton(
                        onPressed: () => _showCollectFeePopup(record),
                        child: const Text('Collect Fee', style: TextStyle(fontSize: 12)),
                      )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collect Fee')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by student name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: filterRecords,
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredFeeRecords.isEmpty
                ? const Center(child: Text('No fee records found.'))
                : ListView.builder(
              itemCount: filteredFeeRecords.length,
              itemBuilder: (context, index) {
                return buildFeeCard(filteredFeeRecords[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CollectFeeDialog extends StatefulWidget {
  final Map<String, dynamic> record;
  final double feeAmount;
  final double remainingFee;
  final Future<String?> Function(double) onSubmit;

  const CollectFeeDialog({
    Key? key,
    required this.record,
    required this.feeAmount,
    required this.remainingFee,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _CollectFeeDialogState createState() => _CollectFeeDialogState();
}

class _CollectFeeDialogState extends State<CollectFeeDialog> {
  final TextEditingController amountController = TextEditingController();
  String? errorMessage;

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Collect Fee'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Name: ${widget.record['student_name']}'),
          Text('Class: ${widget.record['class']}'),
          Text('Serial No: ${widget.record['serial_no']}'),
          const SizedBox(height: 10),
          Text('Monthly Fee: PKR ${widget.feeAmount}'),
          Text('Remaining Fee: PKR ${widget.remainingFee.toStringAsFixed(0)}'),
          const SizedBox(height: 10),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Enter amount to collect',
              border: OutlineInputBorder(),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final enteredAmount = double.tryParse(amountController.text);
            final error = await widget.onSubmit(enteredAmount ?? 0);

            if (error != null) {
              setState(() {
                errorMessage = error;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
