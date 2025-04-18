import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

Future<void> saveInvoiceAsPdf(List<Map<String, dynamic>> studentInvoices) async {
  final pdf = pw.Document();

  final ByteData logoBytes = await rootBundle.load('assets/images/logo.png');
  final Uint8List logo = logoBytes.buffer.asUint8List();

  for (int i = 0; i < studentInvoices.length; i += 2) {
    final students = studentInvoices.skip(i).take(2).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 82, vertical: 12),
        build: (pw.Context context) {
          return pw.Column(
            children: students.map((student) {
              final List records = student['records'] as List;
              final previousDues = student['previous_dues'] ?? 0;
              final totalDues = records.fold<int>(
                previousDues,
                    (sum, r) => sum + int.tryParse('${r['dues'] ?? 0}')!,
              );

              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: buildInvoiceForStudent(student, logo, records, previousDues, totalDues),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  await Printing.sharePdf(
    bytes: await pdf.save(),
    filename: 'student_invoices_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
  );
}

pw.Widget buildInvoiceForStudent(Map student, Uint8List logo, List records, int previousDues, int totalDues) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Student Copy -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------',
        style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 2),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Image(pw.MemoryImage(logo), height: 40),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Mazhar Public School & Dar-Ul-Uloom Azizia', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('19030, Shamas, Darmai, Matta, Swat', style: pw.TextStyle(fontSize: 8)),
              pw.Text('Phone: +92 3474546146', style: pw.TextStyle(fontSize: 8)),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Student Name: ${student['student_name']}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.Text('Father\'s Name: ${student['father_name']}', style: pw.TextStyle(fontSize: 10)),
        ],
      ),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Class: ${student['class']}', style: pw.TextStyle(fontSize: 9)),
          pw.Text('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: pw.TextStyle(fontSize: 9)),
        ],
      ),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Serial No: ${student['serial_no']}', style: pw.TextStyle(fontSize: 9)),
          pw.Text('Monthly Fee: Rs. ${student['monthly_fee']}', style: pw.TextStyle(fontSize: 9)),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Container(
        color: PdfColors.grey300,
        padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        child: pw.Row(
          children: [
            pw.Expanded(flex: 4, child: pw.Text('Month', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 3, child: pw.Text('Paid', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 3, child: pw.Text('Dues', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 3, child: pw.Text('Status', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
          ],
        ),
      ),
      ...records.map((record) {
        final dues = record['dues'];
        final isDuesNA = dues == null;
        final duesText = isDuesNA ? 'NA' : 'Rs. $dues';
        final statusText = isDuesNA ? 'NA' : record['status'];
        final duesColor = isDuesNA
            ? PdfColors.grey
            : (int.tryParse('$dues') ?? 0) > 0
            ? PdfColors.red
            : PdfColors.green;
        final statusColor = isDuesNA
            ? PdfColors.grey
            : record['status'] == 'paid'
            ? PdfColors.green
            : PdfColors.orange;

        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 4, child: pw.Text(record['month'], style: pw.TextStyle(fontSize: 8))),
              pw.Expanded(flex: 3, child: pw.Text('Rs. ${record['amount_paid']}', style: pw.TextStyle(fontSize: 8))),
              pw.Expanded(flex: 3, child: pw.Text(duesText, style: pw.TextStyle(fontSize: 8, color: duesColor))),
              pw.Expanded(flex: 3, child: pw.Text(statusText, style: pw.TextStyle(fontSize: 8, color: statusColor))),
            ],
          ),
        );
      }).toList(),
      pw.SizedBox(height: 1),
      pw.Divider(thickness: 0.5),
      pw.Text('Previous Dues: Rs. $previousDues', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Total Dues: Rs. $totalDues', style: pw.TextStyle(fontSize: 9)),
          pw.Text('Signature: ______________', style: pw.TextStyle(fontSize: 9)),
          pw.Text('Total Paid: Rs. _________', style: pw.TextStyle(fontSize: 9)),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Text(
        'Office Copy -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------',
        style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 8),
      pw.Row(
        children: [
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Student Name: ${student['student_name']}', style: pw.TextStyle(fontSize: 10)),
                pw.Text('Previous Dues: Rs. $previousDues', style: pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Father\'s Name: ${student['father_name']}', style: pw.TextStyle(fontSize: 10)),
                pw.Text('Total Dues: Rs. $totalDues', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
              ],
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Serial No: ${student['serial_no']}', style: pw.TextStyle(fontSize: 10)),
                pw.Text('Signature: ______________', style: pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Row(
        children: [
          pw.Expanded(flex: 1, child: pw.Text('Class: ${student['class']}', style: pw.TextStyle(fontSize: 10))),
          pw.Expanded(flex: 1, child: pw.Text('Total Paid: Rs. _________', style: pw.TextStyle(fontSize: 10))),
        ],
      ),
      // Display Other Amounts if available
      if ((student['other_amounts'] ?? []).isNotEmpty) ...[
        pw.SizedBox(height: 8),
        pw.Text(
          'Other Amounts:',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
        ),
        ...student['other_amounts'].map((other) {
          return pw.Row(
            children: [
              pw.Expanded(flex: 4, child: pw.Text(other['amount_type'], style: pw.TextStyle(fontSize: 9))),
              pw.Expanded(flex: 3, child: pw.Text('Rs. ${other['amount']}', style: pw.TextStyle(fontSize: 9))),
              pw.Expanded(flex: 3, child: pw.Text('Paid: Rs. ${other['amount_paid'] ?? 0}', style: pw.TextStyle(fontSize: 9, color: PdfColors.green))),
              pw.Expanded(flex: 3, child: pw.Text('Due: Rs. ${(num.tryParse('${other['amount']}') ?? 0) - (num.tryParse('${other['amount_paid'] ?? 0}') ?? 0)}', style: pw.TextStyle(fontSize: 9, color: PdfColors.red))),
            ],
          );
        }).toList(),
      ],
    ],
  );
}
