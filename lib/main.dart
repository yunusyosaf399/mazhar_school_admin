import 'package:flutter/material.dart';
import 'package:mazhar/database/promotion.dart';
import 'package:mazhar/students/collect_fee.dart';
import 'package:mazhar/students/exams.dart';
import 'package:mazhar/teachers/manage_salary.dart';
import 'package:mazhar/students/print_invoice.dart';
import 'students/add_student.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'students/update_fee.dart';
import 'teachers/add_teacher.dart';
import 'package:intl/intl.dart';
import 'teachers/count_teacher.dart';
import 'students/students_count.dart';
import 'database/removestudent.dart';
import 'login.dart';
import 'dart:async';
import 'students/dmc.dart';
import 'database/update_fee_structure.dart';
import 'package:table_calendar/table_calendar.dart';
import 'database/Analytics.dart';
import 'students/other_amount.dart';
import 'students/collect_other_amount.dart';
import 'other/feed.dart';
import 'database/authpromot.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rcaemptrskatvfthacwe.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjYWVtcHRyc2thdHZmdGhhY3dlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ1NDI3NjgsImV4cCI6MjA2MDExODc2OH0.HWBt_sk74yVVBOGonMfpsw_-C14L_8lSEGZQc43eFjI',
  );

  FeeUpdater feeUpdater = FeeUpdater();
  Future.delayed(Duration.zero, () async {
    await feeUpdater.syncFeeRecords();
  });

  await updateSalary();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _loggedIn = false;
  Timer? _inactivityTimer;

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 30), () {
      setState(() {
        _loggedIn = false;
      });
    });
  }

  void _resetInactivityTimer() {
    if (_loggedIn) {
      _startInactivityTimer();
    }
  }

  void _handleUserInteraction([_]) => _resetInactivityTimer();

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleUserInteraction,
      behavior: HitTestBehavior.translucent,
      child: MaterialApp(
        title: 'School Management System',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: _loggedIn
            ? const MyHomePage()
            : LoginPage(onLoginSuccess: () {
          setState(() {
            _loggedIn = true;
          });
          _startInactivityTimer();
        }),
      ),
    );
  }
}

Future<void> updateSalary() async {
  final supabase = Supabase.instance.client;
  final now = DateTime.now();
  final currentMonth = DateFormat('yyyy-MM').format(now);
  final firstDayOfMonth = DateTime(now.year, now.month, 1);
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
  final today = now.day;

  if (today < 20 || today > 29) {
    return;
  }

  try {
    final teachers = await supabase
        .from('teacher')
        .select('serial_no, teacher_id, name, salary, resign_status');

    for (var teacher in teachers) {
      if (teacher['resign_status'] == true) continue;

      final existingRecord = await supabase
          .from('salary')
          .select('serial_no')
          .eq('serial_no', teacher['serial_no'])
          .gte('created_at', firstDayOfMonth.toIso8601String())
          .lte('created_at', lastDayOfMonth.toIso8601String())
          .maybeSingle();

      if (existingRecord == null) {
        await supabase.from('salary').insert({
          'serial_no': teacher['serial_no'],
          'teacher_id': teacher['teacher_id'],
          'name': teacher['name'],
          'salary': teacher['salary'],
          'amount_paid': 0,
          'status': 'pending',
          'resign_status': teacher['resign_status'],
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
      }
    }
  } catch (e) {
    print('Error updating salary records: $e');
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Future<void> _handleUpdate() async {
    FeeUpdater feeUpdater = FeeUpdater();
    await feeUpdater.syncFeeRecords();
    await updateSalary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.deepPurple.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.update),
            onPressed: () async {
              await _handleUpdate();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data updated successfully!')),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildStatsRow(),
            // 👇 Fee Analytics Widget Here
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: FeeAnalyticsWidget(), // Your analytics widget
                ),
              ),
            ),

            const SizedBox(height: 20),
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildCalendarCard(),
          ],
        ),

      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade100,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 60,
          ),
          const SizedBox(width: 10),
          const Text(
            "Mazhar Public School &\nDar-Ul-Uloom Azizia",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),

    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: StudentsCount(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: TeachersCount(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      color: Colors.deepPurple.shade50,
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            'Welcome to the Dashboard!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }



  Widget _buildCalendarCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarFormat: _calendarFormat,
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.deepPurpleAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.all(4),
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFCAADFC)),
            child: Text('Mazhar Public School', style: TextStyle(color: Colors.deepPurple, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          _buildExpansionTile('Students', Icons.school, [
            _buildListTile('Add', context, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddStudentPage()))),
            _buildListTile('Remove', context, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RemoveStudentScreen()))),
            _buildListTile('Promotion', context, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthPromotion()))),
          ]),
          _buildExpansionTile('Teachers', Icons.person, [
            _buildListTile('Add', context, () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddTeacherScreen()))),
            _buildListTile('Remove', context, () {}),
            _buildListTile('Manage Salary', context, () => Navigator.push(context, MaterialPageRoute(builder: (context) => ManageSalaryScreen()))),
          ]),
          _buildExpansionTile('Fee & Payments', Icons.paypal, [
            _buildListTile('Update Fee Structure', context, () => Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateFeeStructurePage()))),
            _buildListTile('Update Other Amount', context, () => Navigator.push(context, MaterialPageRoute(builder: (context) => OtherAmountPage()))),
            _buildListTile('Collect Other Amount', context, () => Navigator.push(context, MaterialPageRoute(builder: (context) => CollectOtherAmountPage()))),
            _buildListTile('Print Invoice', context, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrintInvoicePage()))),
            _buildListTile('Collect Fee', context, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CollectFeePage()))),
          ]),
          _buildExpansionTile('Exams', Icons.assignment, [
            _buildListTile('Result', context, () => Navigator.push(context, MaterialPageRoute(builder: (context) => AssignExamResultScreen()))),
            _buildListTile('Test', context, () {}),
            _buildListTile('Exam Schedule', context, () {}),
            _buildListTile('DMC', context, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DmcPage()))),
          ]),

          _buildExpansionTile('Other', Icons.feedback, [
            _buildListTile('Feedback', context, () => Navigator.push(context, MaterialPageRoute(builder: (context) => FeedbackPage()))),
            _buildListTile('Improve', context, () {}),
          ]),


        ],
      ),
    );
  }

  Widget _buildExpansionTile(String title, IconData icon, List<Widget> children) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      children: children,
    );
  }

  Widget _buildListTile(String title, BuildContext context, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
