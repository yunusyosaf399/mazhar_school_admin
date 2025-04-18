import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignExamResultScreen extends StatefulWidget {
  @override
  _AssignExamResultScreenState createState() => _AssignExamResultScreenState();
}

class _AssignExamResultScreenState extends State<AssignExamResultScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchStudents();
    searchController.addListener(() {
      filterStudents();
    });
  }

  Future<void> fetchStudents() async {
    final response = await supabase.from('students').select();
    setState(() {
      students = List<Map<String, dynamic>>.from(response);
      filteredStudents = students;
    });
  }

  void filterStudents() {
    setState(() {
      filteredStudents = students.where((student) {
        return student['student_name']
            .toLowerCase()
            .contains(searchController.text.toLowerCase());
      }).toList();
    });
  }

  String calculateGrade(int marksObtained, int totalMarks) {
    double percentage = (marksObtained / totalMarks) * 100;
    if (percentage >= 90) return "A+";
    if (percentage >= 80) return "A";
    if (percentage >= 70) return "B+";
    if (percentage >= 60) return "B";
    if (percentage >= 35) return "C";
    return "F";
  }

  bool determinePassStatus(String grade) {
    return grade != "F";
  }

  void showExamFormDialog(Map<String, dynamic> student) {
    TextEditingController examTypeController = TextEditingController();
    TextEditingController examDateController = TextEditingController();
    TextEditingController subjectController = TextEditingController();
    TextEditingController totalMarksController = TextEditingController();
    TextEditingController marksObtainedController = TextEditingController();
    String grade = "";
    bool passStatus = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Assign Exam Record for ${student['student_name']}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: examTypeController,
                      decoration: InputDecoration(labelText: 'Exam Type'),
                    ),
                    TextField(
                      controller: examDateController,
                      decoration: InputDecoration(labelText: 'Exam Date (YYYY-MM-DD)'),
                    ),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(labelText: 'Subject'),
                    ),
                    TextField(
                      controller: totalMarksController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Total Marks'),
                      onChanged: (value) {
                        int marksObtained = int.tryParse(marksObtainedController.text) ?? 0;
                        int totalMarks = int.tryParse(value) ?? 0;
                        setState(() {
                          grade = calculateGrade(marksObtained, totalMarks);
                          passStatus = determinePassStatus(grade);
                        });
                      },
                    ),
                    TextField(
                      controller: marksObtainedController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Marks Obtained'),
                      onChanged: (value) {
                        int marksObtained = int.tryParse(value) ?? 0;
                        int totalMarks = int.tryParse(totalMarksController.text) ?? 0;
                        setState(() {
                          grade = calculateGrade(marksObtained, totalMarks);
                          passStatus = determinePassStatus(grade);
                        });
                      },
                    ),
                    Text('Grade: $grade', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Text('Pass Status: '),
                        Checkbox(
                          value: passStatus,
                          onChanged: null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final resultData = {
                      'student_id': student['student_id'],
                      'student_name': student['student_name'],
                      'serial_no': student['serial_no'],
                      'class_name': student['class'],
                      'exam_type': examTypeController.text,
                      'exam_date': examDateController.text,
                      'subject': subjectController.text,
                      'total_marks': int.tryParse(totalMarksController.text) ?? 0,
                      'marks_obtained': int.tryParse(marksObtainedController.text) ?? 0,
                      'grade': grade,
                      'pass_status': passStatus,
                    };

                    await supabase.from('results').insert(resultData);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Exam record assigned successfully!')),
                    );
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assign Exam Results')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Student',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                return ListTile(
                  title: Text(student['student_name']),
                  subtitle: Text('Class: ${student['class']}'),
                  onTap: () => showExamFormDialog(student),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}