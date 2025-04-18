import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';  // For printing
import 'package:pdf/widgets.dart' as pw;  // PDF Generation
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _enrollmentDateController = TextEditingController();
  final TextEditingController _previousSchoolController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController(); // New CNIC controller

  bool _isOrphan = false;
  bool _isDisabled = false;

  int? _serialNo;

  Future<void> _addStudent() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await _supabase.from('students').insert({
          'student_name': _nameController.text,
          'father_name': _fatherNameController.text,
          'class': _classController.text,
          'enrollment_date': _enrollmentDateController.text,
          'previous_school': _previousSchoolController.text.isEmpty ? null : _previousSchoolController.text,
          'address': _addressController.text,
          'birth_date': _birthDateController.text,
          'orphan': _isOrphan,
          'disable': _isDisabled,
          'contact': _contactController.text,
          'cnic': _cnicController.text, // New CNIC field
        }).select('serial_no').single();

        int studentSerialNo = response['serial_no'];

        setState(() {
          _serialNo = studentSerialNo;
        });

        await _supabase.from('exams').insert({
          'serial_no': studentSerialNo,
          'student_name': _nameController.text,
          'class': _classController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _printAdmissionForm() async {
    if (_serialNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Serial Number not found! Add student first.')),
      );
      return;
    }

    final pdf = pw.Document();
    final ByteData logoBytes = await rootBundle.load('assets/images/logo.png');
    final Uint8List logoData = logoBytes.buffer.asUint8List();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(pw.MemoryImage(logoData), height: 60),
              pw.SizedBox(height: 10),
              pw.Text("Mazhar Public School", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.Text("19030 Near Azlan Hotel, Shamas Darmai, Matta, Swat"),
              pw.Text("Contact: +92 3474546146"),
              pw.Divider(),
              pw.Text("Admission Form", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Serial No: $_serialNo"),
                      pw.Text("Student Name: ${_nameController.text}"),
                      pw.Text("Father Name: ${_fatherNameController.text}"),
                      pw.Text("Previous School: ${_previousSchoolController.text.isEmpty ? 'N/A' : _previousSchoolController.text}"),
                      pw.Text("Address: ${_addressController.text}"),
                      pw.Text("CNIC: ${_cnicController.text}"), // Include CNIC
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Enrollment Date: ${_enrollmentDateController.text}"),
                      pw.Text("Birth Date: ${_birthDateController.text}"),
                      pw.Text("Orphan: ${_isOrphan ? 'Yes' : 'No'}"),
                      pw.Text("Disabled: ${_isDisabled ? 'Yes' : 'No'}"),
                      pw.Text("Contact: ${_contactController.text}"),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text("School Rules and Regulations:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: "Students must wear proper uniform."),
              pw.Bullet(text: "Regular attendance is mandatory."),
              pw.Bullet(text: "Respect teachers and fellow students."),
              pw.Bullet(text: "Mobile phones are not allowed during class hours."),
              pw.Bullet(text: "Follow school timings strictly."),
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text("Principal's Signature", style: pw.TextStyle(fontSize: 14)),
                      pw.Container(height: 1, width: 100, color: PdfColors.black),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text("Parent's Signature", style: pw.TextStyle(fontSize: 14)),
                      pw.Container(height: 1, width: 100, color: PdfColors.black),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Student')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(_nameController, 'Student Name'),
                      _buildTextField(_fatherNameController, 'Father Name'),
                      _buildTextField(_classController, 'Class'),
                      _buildTextField(_enrollmentDateController, 'Enrollment Date (YYYY-MM-DD)'),
                      _buildTextField(_previousSchoolController, 'Previous School (Optional)', isRequired: false),
                      _buildTextField(_addressController, 'Address'),
                      _buildTextField(_birthDateController, 'Birth Date (YYYY-MM-DD)'),
                      _buildTextField(_contactController, 'Contact Number'),
                      _buildTextField(_cnicController, 'CNIC (14-digit)', validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter CNIC';
                        if (!RegExp(r'^\d{14}$').hasMatch(value)) return 'Invalid CNIC: must be 14 digits';
                        return null;
                      }),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSwitchTile('Orphan', _isOrphan, (val) => setState(() => _isOrphan = val)),
                          _buildSwitchTile('Disabled', _isDisabled, (val) => setState(() => _isDisabled = val)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _addStudent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        ),
                        child: const Text('Submit', style: TextStyle(fontSize: 16)),
                      ),
                      if (_serialNo != null) ...[
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _printAdmissionForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          ),
                          child: const Text('Print Form', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isRequired = true, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: label.contains('CNIC') || label.contains('Contact') ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: validator ?? (isRequired ? (value) => value!.isEmpty ? 'Enter $label' : null : null),
      ),
    );
  }

  Widget _buildSwitchTile(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Text(label),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}