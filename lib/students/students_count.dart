import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentsCount extends StatefulWidget {
  const StudentsCount({super.key});

  @override
  _StudentsCountState createState() => _StudentsCountState();
}

class _StudentsCountState extends State<StudentsCount> {
  int studentCount = 0;

  @override
  void initState() {
    super.initState();
    fetchStudentCount();
  }

  Future<void> fetchStudentCount() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase.rpc('get_student_count'); // Call the function

      setState(() {
        studentCount = response ?? 0;
      });
    } catch (e) {
      print("Error fetching student count: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Total Students Enrolled",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "$studentCount",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
          ],
        ),
      ),
    );
  }
}
