import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RemoveStudentScreen extends StatefulWidget {
  const RemoveStudentScreen({super.key});

  @override
  State<RemoveStudentScreen> createState() => _RemoveStudentScreenState();
}

class _RemoveStudentScreenState extends State<RemoveStudentScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> allStudents = [];
  List<dynamic> filteredStudents = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() async {
    final res = await supabase.from('students').select().order('serial_no');
    setState(() {
      allStudents = res;
      filteredStudents = res;
    });
  }

  void _filterStudents(String query) {
    setState(() {
      filteredStudents = allStudents.where((student) {
        final name = student['student_name'].toString().toLowerCase();
        final father = student['father_name'].toString().toLowerCase();
        return name.contains(query.toLowerCase()) || father.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _confirmRemove(Map student) async {
    String enteredUID = '';
    String? message;
    bool? isSuccess;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Confirm Removal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter Admin UID to confirm removing "${student['student_name']}"'),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: 'Admin UID'),
                onChanged: (value) => enteredUID = value,
              ),
              const SizedBox(height: 12),
              if (message != null)
                Row(
                  children: [
                    if (isSuccess == true)
                      const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        message!,
                        style: TextStyle(
                          color: isSuccess == true ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final isValid = await _verifyUID(enteredUID);
                if (isValid) {
                  await supabase.from('students').delete().eq('serial_no', student['serial_no']);
                  setState(() {
                    message = 'Student removed successfully';
                    isSuccess = true;
                  });
                  await Future.delayed(const Duration(seconds: 2));
                  Navigator.pop(context);
                  _loadStudents();
                } else {
                  setState(() {
                    message = 'Invalid UID. You are not authorized.';
                    isSuccess = false;
                  });
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _verifyUID(String uid) async {
    final res = await supabase
        .from('admin_cred')
        .select()
        .eq('UID', uid)
        .limit(1)
        .maybeSingle();
    return res != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Remove Student')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by student or father name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterStudents,
            ),
          ),
          Expanded(
            child: filteredStudents.isEmpty
                ? const Center(child: Text('No students found.'))
                : ListView.builder(
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(student['student_name']),
                    subtitle: Text('Father: ${student['father_name']} | Class: ${student['class']}'),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      onPressed: () => _confirmRemove(student),
                      child: const Text('Remove'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
