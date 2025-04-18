import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeachersCount extends StatefulWidget {
  const TeachersCount({super.key});

  @override
  _TeachersCountState createState() => _TeachersCountState();
}

class _TeachersCountState extends State<TeachersCount> {
  int teacherCount = 0;

  @override
  void initState() {
    super.initState();
    fetchTeacherCount();
  }

  Future<void> fetchTeacherCount() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase.rpc('get_teacher_count'); // Call the function

      setState(() {
        teacherCount = response ?? 0;
      });
    } catch (e) {
      print("Error fetching teacher count: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.orange.shade50, // Different color for teachers
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Total Teachers",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "$teacherCount",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}
