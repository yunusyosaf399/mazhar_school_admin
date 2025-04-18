import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class UpdateFeeStructurePage extends StatefulWidget {
  @override
  _UpdateFeeStructurePageState createState() => _UpdateFeeStructurePageState();
}

class _UpdateFeeStructurePageState extends State<UpdateFeeStructurePage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> classList = [];
  String? selectedClass;
  TextEditingController feeController = TextEditingController();
  String? message;
  Color messageColor = Colors.green;
  IconData? messageIcon;

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    final response = await supabase
        .from('fee_structure')
        .select('id, class_name, fee_amount')
        .order('class_name', ascending: true);

    setState(() {
      classList = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> updateFee() async {
    if (selectedClass == null || feeController.text.isEmpty) {
      showMessage('Please select a class and enter fee amount', Colors.red, Icons.error);
      return;
    }

    try {
      final selected =
      classList.firstWhere((item) => item['class_name'] == selectedClass);

      await supabase
          .from('fee_structure')
          .update({'fee_amount': double.parse(feeController.text)})
          .eq('id', selected['id']);

      setState(() {
        feeController.clear();
        selectedClass = null;
      });

      showMessage('Fee updated successfully', Colors.green, Icons.check_circle);
      fetchClasses();
    } catch (e) {
      showMessage('Error updating fee. Please try again.', Colors.red, Icons.error);
    }
  }

  void showMessage(String text, Color color, IconData icon) {
    setState(() {
      message = text;
      messageColor = color;
      messageIcon = icon;
    });

    if (color == Colors.green) {
      // Auto-hide success message after 5 seconds
      Timer(Duration(seconds: 5), () {
        setState(() {
          message = null;
          messageIcon = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Fee Structure'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedClass,
                    decoration: InputDecoration(
                      labelText: 'Select Class',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: classList.map((classData) {
                      return DropdownMenuItem<String>(
                        value: classData['class_name'],
                        child: Text(
                            '${classData['class_name']} (Fee: ${classData['fee_amount']})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClass = value;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: feeController,
                    decoration: InputDecoration(
                      labelText: 'New Fee Amount',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType:
                    TextInputType.numberWithOptions(decimal: true),
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: updateFee,
                      icon: Icon(Icons.update),
                      label: Text('Update Fee'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (message != null) ...[
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(messageIcon, color: messageColor),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            message!,
                            style: TextStyle(
                              color: messageColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
