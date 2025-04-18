import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:developer';

class FeeUpdater {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> syncFeeRecords() async {
    DateTime now = DateTime.now();
    String currentMonth = DateFormat('yyyy-MM').format(now);
    log("Checking fee records for month: $currentMonth");

    if (now.day < 5 || now.day > 28) {
      log("Not in the valid date range (25-29), skipping update.");
      return; // Only run between 25th-29th
    }

    log("Fetching students...");
    final students = await supabase.from('students').select('serial_no, class, student_name, father_name');
    log("Fetched ${students.length} students.");

    log("Fetching fee structures...");
    final feeStructures = await supabase.from('fee_structure').select('class_name, fee_amount');
    log("Fetched ${feeStructures.length} fee structures.");

    Map<String, num> feeMap = {for (var f in feeStructures) f['class_name']: f['fee_amount']};

    for (var student in students) {
      int serialNo = student['serial_no'];
      String studentClass = student['class'];
      String studentName = student['student_name'];
      String fatherName = student['father_name'];
      int feeAmount = feeMap[studentClass]?.toInt() ?? 5000;

      log("Checking existing fee record for Student: $studentName, Serial: $serialNo, Month: $currentMonth");
      final existingRecord = await supabase
          .from('fee')
          .select('id')
          .eq('serial_no', serialNo)
          .eq('month', currentMonth)
          .maybeSingle();

      if (existingRecord == null) {
        log("No record found, inserting fee record for $studentName");
        await supabase.from('fee').insert({
          'serial_no': serialNo,
          'student_name': studentName,
          'father_name': fatherName, // <- added here
          'class': studentClass,
          'month': currentMonth,
          'amount_paid': 0,
          'dues': feeAmount,
          'status': 'pending',
          'monthly_fee':feeAmount,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        log("Fee record inserted for $studentName");
      } else {
        log("Fee record already exists for $studentName, skipping insertion.");
      }
    }
  }
}