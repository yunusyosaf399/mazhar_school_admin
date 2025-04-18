import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CollectOtherAmountPage extends StatefulWidget {
  @override
  _CollectOtherAmountPageState createState() => _CollectOtherAmountPageState();
}

class _CollectOtherAmountPageState extends State<CollectOtherAmountPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> amounts = [];
  Map<String, TextEditingController> payControllers = {};

  @override
  void initState() {
    super.initState();
    fetchOtherAmounts();
  }

  Future<void> fetchOtherAmounts() async {
    final response = await supabase
        .from('other_amounts')
        .select()
        .order('created_at', ascending: false);

    setState(() {
      amounts = List<Map<String, dynamic>>.from(response);
      payControllers.clear();
      for (var record in amounts) {
        payControllers[record['id']] = TextEditingController();
      }
    });
  }

  Future<void> updatePayment(String id, num currentAmount, num currentPaid, num newPaid) async {
    final newTotalPaid = currentPaid + newPaid;
    final updatedAmount = currentAmount - newPaid <= 0 ? 0 : currentAmount - newPaid;

    // Update the payment in the database
    await supabase.from('other_amounts').update({
      'amount': updatedAmount,
      'amount_paid': newTotalPaid,
    }).eq('id', id);

    if (updatedAmount == 0) {
      await supabase.from('other_amounts').delete().eq('id', id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment completed, record deleted.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment updated successfully.")),
      );
    }

    await fetchOtherAmounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Collect Other Amounts", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white12,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: amounts.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: amounts.length,
          itemBuilder: (context, index) {
            final item = amounts[index];
            final controller = payControllers[item['id']]!;
            final paid = item['amount_paid'] ?? 0;
            final amount = item['amount'] ?? 0;

            return Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "(${item['serial_no']}) ${item['student_name']}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Total Amount: Rs. $amount",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "Paid: Rs. $paid",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Enter Amount to Pay",
                              labelStyle: TextStyle(color: Colors.deepPurple),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final entered = num.tryParse(controller.text);
                            if (entered == null || entered <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Invalid amount.")),
                              );
                              return;
                            }

                            if (amount == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Amount is already fully paid.")),
                              );
                              return;
                            }

                            if (entered > amount) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Cannot pay more than the remaining amount.")),
                              );
                              return;
                            }

                            updatePayment(item['id'], amount, paid, entered);
                          },
                          child: Text("Pay"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,  // Use backgroundColor instead of primary
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: TextStyle(fontSize: 16),
                          ),
                        ),

                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
