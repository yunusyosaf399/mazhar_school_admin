import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtherAmountPage extends StatefulWidget {
  @override
  _OtherAmountPageState createState() => _OtherAmountPageState();
}

class _OtherAmountPageState extends State<OtherAmountPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> allStudents = [];
  List<Map<String, dynamic>> filteredStudents = [];
  Set<int> selectedSerialNos = {};

  String selectedClass = '';
  TextEditingController amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    final response = await supabase.from('students').select();
    setState(() {
      allStudents = List<Map<String, dynamic>>.from(response);
      filteredStudents = allStudents;
    });
  }

  void filterByClass(String className) {
    setState(() {
      selectedClass = className;
      filteredStudents =
          allStudents.where((student) => student['class'] == className).toList();
    });
  }

  void toggleStudentSelection(int serialNo) {
    setState(() {
      selectedSerialNos.contains(serialNo)
          ? selectedSerialNos.remove(serialNo)
          : selectedSerialNos.add(serialNo);
    });
  }

  void toggleSelectAll(bool selectAll) {
    setState(() {
      selectAll
          ? selectedSerialNos =
          filteredStudents.map((s) => s['serial_no'] as int).toSet()
          : selectedSerialNos.clear();
    });
  }

  Future<void> submitAmounts() async {
    final amount = double.tryParse(amountController.text);
    if (amount == null || selectedSerialNos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter a valid amount and select students.")),
      );
      return;
    }

    for (final student in filteredStudents
        .where((s) => selectedSerialNos.contains(s['serial_no']))) {
      await supabase.from('other_amounts').insert({
        'serial_no': student['serial_no'],
        'student_name': student['student_name'],
        'amount': amount,
        'amount_type': 'Materials & Resources',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Amount added for selected students.")),
    );

    setState(() {
      selectedSerialNos.clear();
      amountController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Assign Other Amounts"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown for Class Filter
            DropdownButtonFormField<String>(
              value: selectedClass.isNotEmpty ? selectedClass : null,
              decoration: InputDecoration(
                labelText: "Select Class",
                border: OutlineInputBorder(),
              ),
              items: allStudents
                  .map((s) => s['class'].toString())
                  .toSet()
                  .map((className) => DropdownMenuItem(
                value: className,
                child: Text(className),
              ))
                  .toList(),
              onChanged: (value) {
                if (value != null) filterByClass(value);
              },
            ),
            const SizedBox(height: 10),

            // Select All Checkbox
            CheckboxListTile(
              title: Text("Select All"),
              value: selectedSerialNos.length == filteredStudents.length &&
                  filteredStudents.isNotEmpty,
              onChanged: (bool? value) {
                toggleSelectAll(value ?? false);
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 10),

            // Student List
            Expanded(
              child: filteredStudents.isEmpty
                  ? Center(child: Text("No students found for this class."))
                  : ListView.separated(
                itemCount: filteredStudents.length,
                separatorBuilder: (_, __) => Divider(),
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  final serialNo = student['serial_no'] as int;
                  final isSelected =
                  selectedSerialNos.contains(serialNo);

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CheckboxListTile(
                      title: Text(student['student_name']),
                      subtitle: Text("Serial: $serialNo | Class: ${student['class']}"),
                      value: isSelected,
                      onChanged: (_) => toggleStudentSelection(serialNo),
                      secondary: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected
                            ? Colors.green
                            : Colors.grey.shade400,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Amount Entry
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: "Enter Amount",
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),

            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: submitAmounts,
                icon: Icon(Icons.send),
                label: Text("Submit Amounts"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
