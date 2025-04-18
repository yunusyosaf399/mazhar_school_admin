import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PromotionPage extends StatefulWidget {
  const PromotionPage({Key? key}) : super(key: key);

  @override
  _PromotionPageState createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> allStudents = [];
  List<Map<String, dynamic>> filteredStudents = [];
  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchStudents();
    searchController.addListener(() {
      filterStudents(searchController.text);
    });
  }

  // Fetch students from the students table
  Future<void> fetchStudents() async {
    final response = await supabase.from('students').select('*');
    setState(() {
      allStudents = List<Map<String, dynamic>>.from(response);
      filteredStudents = allStudents;
      isLoading = false;
    });
  }

  // Promote a student to the next class
  Future<void> promoteStudent(String studentId, String currentClass) async {
    final newClass = getNextClass(currentClass);
    try {
      await supabase
          .from('students')
          .update({'class': newClass})
          .eq('student_id', studentId);
      fetchStudents(); // Refresh the student list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Student promoted to $newClass')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error promoting student: $e')),
      );
    }
  }

  // Determine the next class
  String getNextClass(String currentClass) {
    final classMap = {
      'Nursery': 'KG',
      'KG': '1st',
      '1st': '2nd',
      '2nd': '3rd',
      '3rd': '4th',
      '4th': '5th',
      '5th': '6th',
      '6th': '7th',
      '7th': '8th',
      '8th': '9th',
      '9th': '10th',
      '10th': '11th',
      '11th': '12th',
    };
    return classMap[currentClass] ?? currentClass;
  }

  // Filter students based on search input
  void filterStudents(String query) {
    final filtered = allStudents.where((student) {
      final name = student['student_name'].toString().toLowerCase();
      final className = student['class'].toString().toLowerCase();
      final fatherName = student['father_name'].toString().toLowerCase();
      return name.contains(query.toLowerCase()) ||
          className.contains(query.toLowerCase()) ||
          fatherName.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredStudents = filtered;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Promote Students"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: '🔍 Search by name, class, or father’s name',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Promote Students to Next Class',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (filteredStudents.isEmpty)
              const Expanded(
                child: Center(
                  child: Text("No matching students found 🧐"),
                ),
              ),
            if (filteredStudents.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    final studentId = student['student_id'].toString();
                    final studentName = student['student_name'];
                    final currentClass = student['class'];
                    final fatherName = student['father_name'];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    studentName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text("Class: $currentClass",
                                      style: const TextStyle(fontSize: 13)),
                                  Text("Father: $fatherName",
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_upward),
                              onPressed: () => promoteStudent(studentId, currentClass),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
