import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  static Future<void> exportToCSV(List<Map<String, dynamic>> data, String filename) async {
    if (data.isEmpty) return;
    
    final headers = data.first.keys.where((k) => k != 'id').toList();
    String csv = headers.join(',') + '\n';
    
    for (var row in data) {
      final values = headers.map((h) => '"${row[h]?.toString().replaceAll('"', '""') ?? ''}"').join(',');
      csv += values + '\n';
    }
    
    final bytes = Uint8List.fromList(utf8.encode(csv));
    await FileSaver.instance.saveFile(name: filename, bytes: bytes, fileExtension: 'csv', mimeType: MimeType.csv);
  }

  static Future<void> exportToExcel(List<Map<String, dynamic>> data, String filename) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];
    
    if (data.isNotEmpty) {
      final headers = data.first.keys.where((k) => k != 'id').toList();
      sheetObject.appendRow(headers.map((h) => TextCellValue(h.toUpperCase())).toList());
      
      for (var row in data) {
        final values = headers.map((h) => TextCellValue(row[h]?.toString() ?? '')).toList();
        sheetObject.appendRow(values);
      }
    }
    
    final bytes = excel.encode();
    if (bytes != null) {
      await FileSaver.instance.saveFile(name: filename, bytes: Uint8List.fromList(bytes), fileExtension: 'xlsx', mimeType: MimeType.microsoftExcel);
    }
  }

  static Future<void> exportToPDF(List<Map<String, dynamic>> data, String filename) async {
    final pdf = pw.Document();
    
    if (data.isNotEmpty) {
      final headers = data.first.keys.where((k) => k != 'id').toList();
      final tableData = [
        headers.map((h) => h.toUpperCase()).toList(),
      ];
      
      for (var row in data) {
        tableData.add(headers.map((h) => row[h]?.toString() ?? '').toList());
      }
      
      // Load the logo image
      final logoBytes = await rootBundle.load('assets/LOGO.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Image(logoImage, width: 40, height: 40),
                    pw.SizedBox(width: 12),
                    pw.Text('SirfBill Bill Karo, Befikar Raho', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text('Shop Directory Report', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                pw.SizedBox(height: 20),
              ],
            );
          },
          build: (pw.Context context) {
            return [
              pw.TableHelper.fromTextArray(
                context: context,
                data: tableData,
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green600),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(8),
                cellStyle: const pw.TextStyle(fontSize: 10),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Generated on ${DateTime.now().toString().split('.')[0]}', style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10)),
              ),
            ];
          },
        ),
      );
    }
    
    final bytes = await pdf.save();
    await FileSaver.instance.saveFile(name: filename, bytes: bytes, fileExtension: 'pdf', mimeType: MimeType.pdf);
  }
}
