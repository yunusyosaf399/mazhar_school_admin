import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

class DmcPage extends StatefulWidget {
  const DmcPage({super.key});

  @override
  State<DmcPage> createState() => _DmcPageState();
}

class _DmcPageState extends State<DmcPage> {
  final supabase = Supabase.instance.client;
  final pdf = pw.Document();
  final today = DateTime.now();
  bool isGenerated = false;
  String? selectedExam;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, showExamTypeDialog);
  }

  Future<void> showExamTypeDialog() async {
    final exams = ['1st Term', 'Mid Term', 'Final Term'];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String? tempSelected;
        return AlertDialog(
          title: const Text('Select Exam Type'),
          content: DropdownButtonFormField<String>(
            value: tempSelected,
            items: exams.map((e) {
              return DropdownMenuItem(value: e, child: Text(e));
            }).toList(),
            onChanged: (val) => tempSelected = val,
            decoration: const InputDecoration(labelText: 'Exam Type'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (tempSelected != null) {
                  setState(() {
                    selectedExam = tempSelected;
                  });
                  Navigator.pop(context);
                  generateDmc();
                }
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
  }

  Future<void> generateDmc() async {
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      final logo = pw.MemoryImage(logoData.buffer.asUint8List());
      final ttf = pw.Font.ttf(await rootBundle.load("assets/fonts/Roboto-Regular.ttf"));

      final response = await supabase
          .from('results')
          .select('*, students(father_name)')
          .eq('exam_type', selectedExam!)
          .gte('exam_date', today.subtract(const Duration(days: 35)).toIso8601String())
          .order('exam_date', ascending: false);

      final results = response as List;

      if (results.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No records found for selected exam.")),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Group by class
      final classGroups = <String, List<Map<String, dynamic>>>{};
      for (final record in results) {
        final className = record['class_name'];
        classGroups.putIfAbsent(className, () => []).add(record);
      }

      for (final classEntry in classGroups.entries) {
        final className = classEntry.key;
        final classResults = classEntry.value;

        // Group by student
        final studentGroups = <String, List<Map<String, dynamic>>>{};
        for (final record in classResults) {
          final studentId = record['student_id'];
          studentGroups.putIfAbsent(studentId, () => []).add(record);
        }

        // Calculate total marks for each student
        final studentTotals = studentGroups.map((id, records) {
          final total = records.fold<int>(0, (sum, r) => sum + (r['marks_obtained'] as num).toInt());
          return MapEntry(id, total);
        });

        // Sort students by obtained marks
        final sortedStudents = studentTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final positionMap = <String, int>{};
        int rank = 1;
        int skip = 1;
        int? previousMarks;

        for (int i = 0; i < sortedStudents.length; i++) {
          final current = sortedStudents[i];

          if (previousMarks != null && current.value == previousMarks) {
            // Same marks as previous student, give same rank
            positionMap[current.key] = rank;
            skip++;
          } else {
            // New rank
            rank = i + 1;
            positionMap[current.key] = rank;
            skip = 1;
          }

          previousMarks = current.value;
        }


        for (final entry in studentGroups.entries) {
          final studentId = entry.key;
          final studentResults = entry.value;
          final studentName = studentResults.first['student_name'];
          final fatherName = studentResults.first['students']['father_name'];
          final examType = studentResults.first['exam_type'];
          final examDate = DateFormat.yMMMd().format(DateTime.parse(studentResults.first['exam_date']));
          final serialNo = studentResults.first['serial_no'];

          final totalMarks = studentResults.fold(0, (int sum, r) => sum + (r['total_marks'] as num).toInt());
          final marksObtained = studentTotals[studentId]!;
          final percentage = (marksObtained / totalMarks) * 100;
          final overallGrade = calculateGrade(marksObtained, totalMarks);
          final remark = getRemark(percentage);
          final position = positionMap[studentId]!;
          final average = classResults
              .map((r) => (r['marks_obtained'] as num).toInt())
              .fold<int>(0, (a, b) => a + b) /
              studentGroups.length;

          final backgroundColor = getGradeColor(overallGrade);

          pdf.addPage(
            pw.Page(
              pageTheme: pw.PageTheme(
                pageFormat: PdfPageFormat.a4,
                theme: pw.ThemeData.withFont(base: ttf),
                buildBackground: (context) => pw.FullPage(
                  ignoreMargins: true,
                  child: pw.Container(color: backgroundColor),
                ),
              ),
              build: (context) => pw.Padding(
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Image(logo, width: 60),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text("Mazhar Public School & Dar-Ul-Uloom Azizia", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                            pw.Text("Campus: Main Campus"),
                            pw.Text("Contact: +92 3474546146"),
                            pw.Text("Address: Shamas, Darmai, Matta, Swat"),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Center(
                      child: pw.Text("Detail Marks Certificate", style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Divider(),
                    // Student Info
                    pw.Text("Serial No: $serialNo"),
                    pw.Text("Student Name: $studentName"),
                    pw.Text("Father Name: $fatherName"),
                    pw.Text("Class: $className"),
                    pw.Text("Exam: $examType"),
                    pw.Text("Date: $examDate"),
                    pw.SizedBox(height: 10),
                    // Subject Table
                    pw.Table.fromTextArray(
                      headers: ['S.No', 'Subject', 'Total', 'Obtained', 'Grade', 'Remarks'],
                      data: List.generate(studentResults.length, (index) {
                        final r = studentResults[index];
                        final grade = calculateGrade(r['marks_obtained'], r['total_marks']);
                        final subjectRemark = getRemark((r['marks_obtained'] / r['total_marks']) * 100);
                        return [
                          (index + 1).toString(),
                          r['subject'],
                          r['total_marks'].toString(),
                          r['marks_obtained'].toString(),
                          grade,
                          subjectRemark
                        ];
                      }),
                      cellStyle: const pw.TextStyle(fontSize: 10),
                      headerStyle: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      cellAlignments: {
                        0: pw.Alignment.center,
                        1: pw.Alignment.centerLeft,
                        2: pw.Alignment.center,
                        3: pw.Alignment.center,
                        4: pw.Alignment.center,
                        5: pw.Alignment.center,
                      },
                    ),
                    pw.SizedBox(height: 15),
                    // Summary
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("Total Marks: $totalMarks"),
                            pw.Text("Marks Obtained: $marksObtained"),
                            pw.Text("Percentage: ${percentage.toStringAsFixed(2)}%"),
                            pw.Text("Overall Grade: $overallGrade"),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("Remarks: $remark"),
                            pw.Text("Position in Class: $position"),
                            pw.Text("Class Average: ${average.toStringAsFixed(2)}"),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    // Grading Table
                    pw.Text("Grading System:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Table.fromTextArray(
                      headers: ['Grade', 'Range (%)', 'Remarks'],
                      data: [
                        ['A+', '90-100', 'Outstanding'],
                        ['A', '80-89', 'Excellence'],
                        ['B+', '70-79', 'Good'],
                        ['B', '60-69', 'Average'],
                        ['C', '35-59', 'Fair'],
                        ['F', '< 35', 'Need Attention'],
                      ],
                      cellStyle: const pw.TextStyle(fontSize: 9),
                      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      cellAlignments: {
                        0: pw.Alignment.center,
                        1: pw.Alignment.center,
                        2: pw.Alignment.centerLeft,
                      },
                    ),
                    pw.SizedBox(height: 30),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text("Controller of Examination", style: const pw.TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'dmc.pdf',
      );

      setState(() {
        isGenerated = true;
      });
    } catch (e) {
      print("Error generating DMC: $e");
    }
  }

  // Helpers remain unchanged
  String calculateGrade(int marksObtained, int totalMarks) {
    double percentage = (marksObtained / totalMarks) * 100;
    if (percentage >= 90) return "A+";
    if (percentage >= 80) return "A";
    if (percentage >= 70) return "B+";
    if (percentage >= 60) return "B";
    if (percentage >= 35) return "C";
    return "F";
  }

  String getRemark(double percentage) {
    if (percentage >= 90) return "Outstanding";
    if (percentage >= 80) return "Excellence";
    if (percentage >= 70) return "Good";
    if (percentage >= 60) return "Average";
    if (percentage >= 35) return "Fair";
    return "Need Attention";
  }

  PdfColor getGradeColor(String grade) {
    switch (grade) {
      case "A+": return const PdfColor.fromInt(0xc6f8fa);
      case "A": return const PdfColor.fromInt(0xFFAFF7F8);
      case "B+": return const PdfColor.fromInt(0xf5f8f8);
      case "B": return const PdfColor.fromInt(0xf5f8f8);
      case "C": return const PdfColor.fromInt(0xf5f8f8);
      case "F": return const PdfColor.fromInt(0xf5f8f8);
      default: return PdfColors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isGenerated
          ? AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("DMC Generated"),
      )
          : null,
      body: const Center(child: Text("Generating DMC...")),
    );
  }
}
