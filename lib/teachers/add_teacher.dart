import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
class AddTeacherScreen extends StatefulWidget {
  @override
  _AddTeacherScreenState createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController joiningDateController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();

  Future<void> _addTeacher() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _supabase.from('teacher').insert({
          'name': nameController.text,
          'father_name': fatherNameController.text,
          'contact': contactController.text,
          'subject': subjectController.text,
          'joining_date': joiningDateController.text,
          'address': addressController.text,
          'cnic': cnicController.text.isNotEmpty ? int.parse(cnicController.text) : null,
          'salary': double.parse(salaryController.text),
          'resign_status': false, // Default resign status is false
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Teacher added successfully')));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Teacher')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(nameController, 'Name'),
              _buildTextField(fatherNameController, 'Father Name'),
              _buildTextField(contactController, 'Contact', keyboardType: TextInputType.phone),
              _buildTextField(subjectController, 'Subject'),
              _buildTextField(joiningDateController, 'Joining Date (YYYY-MM-DD)'),
              _buildTextField(addressController, 'Address'),
              _buildTextField(cnicController, 'CNIC', keyboardType: TextInputType.number),
              _buildTextField(salaryController, 'Salary', keyboardType: TextInputType.number),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addTeacher,
                child: Text('Add Teacher'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        keyboardType: keyboardType,
        validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }
}