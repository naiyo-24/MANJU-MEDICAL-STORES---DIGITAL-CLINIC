with open('/Users/sayarpaul/Project/MANJU MEDICAL STORES & DIGITAL CLINIC/lib/utils/pdf_generator.dart', 'w') as f:
    f.write('''import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

class PdfGenerator {
  static Future<Uint8List> generateBill({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double tax,
    required double grandTotal,
    required String invoiceNumber,
    required String customerName,
    required String format,
    String? customerPhone,
    String? customerLocation,
    String? doctorName,
    Map<String, dynamic>? shopSettings,
  }) async {
    final pdf = pw.Document();

    pw.ImageProvider? logoImage;
    pw.ImageProvider? qrImage;

    // Load default logo
    final ByteData bytes = await rootBundle.load('assets/LOGO.png');
    logoImage = pw.MemoryImage(bytes.buffer.asUint8List());

    // Fetch custom logo if exists
    if (shopSettings != null && shopSettings['logo_url'] != null) {
      try {
        final response = await http.get(Uri.parse('http://127.0.0.1:8000${shopSettings['logo_url']}'));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        print('Error loading custom logo: $e');
      }
    }

    // Fetch custom QR if exists
    if (shopSettings != null && shopSettings['qr_url'] != null) {
      try {
        final response = await http.get(Uri.parse('http://127.0.0.1:8000${shopSettings['qr_url']}'));
        if (response.statusCode == 200) {
          qrImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        print('Error loading custom QR: $e');
      }
    }

    final String shopName = shopSettings?['shop_name'] ?? 'SirfBill Pharmacy';
    final String tagline = shopSettings?['tagline'] ?? 'Your Trusted Health Partner';
    final String address = shopSettings?['address'] ?? '123 Health Avenue, Medical District';
    final String phone = shopSettings?['phone'] ?? '+91 98765 43210';
    final String landline = shopSettings?['landline'] ?? '';
    final String email = shopSettings?['email'] ?? 'contact@sirfbill.com';
    final String gstNo = shopSettings?['gst_number'] ?? 'GSTIN27XXXXX1234';

    final String bankName = shopSettings?['bank_name'] ?? 'State Bank of India';
    final String branchName = shopSettings?['branch_name'] ?? 'Main Branch';
    final String acHolder = shopSettings?['ac_holder_name'] ?? shopName;
    final String acNumber = shopSettings?['ac_number'] ?? '123456789012';
    final String ifsc = shopSettings?['ifsc_code'] ?? 'SBIN0000123';

    final String term1 = shopSettings?['terms_1'] ?? '1. Medicines once sold will not be taken back.';
    final String term2 = shopSettings?['terms_2'] ?? '2. Store in cool and dry place.';
    final String term3 = shopSettings?['terms_3'] ?? '';

    final primaryGreen = PdfColor.fromHex('#166534');
    
    // Calculate rounded total
    double roundedTotal = grandTotal.roundToDouble();
    double roundOff = roundedTotal - grandTotal;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 80,
                    height: 80,
                    child: pw.Image(logoImage),
                  ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(shopName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                      if (tagline.isNotEmpty) pw.Text(tagline, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text(address, style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Phone: $phone ${landline.isNotEmpty ? '| $landline' : ''}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Email: $email', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('GSTIN: $gstNo', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ]
                  )
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                    pw.SizedBox(height: 8),
                    pw.Text('Invoice No: $invoiceNumber', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
                  ]
                )
              ]
            ),
            pw.SizedBox(height: 16),
            pw.Divider(color: primaryGreen, thickness: 1.5),
            pw.SizedBox(height: 8),
            
            // Customer Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Billed To:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text(customerName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    if (customerPhone != null && customerPhone.isNotEmpty) pw.Text('Phone: $customerPhone', style: const pw.TextStyle(fontSize: 10)),
                    if (customerLocation != null && customerLocation.isNotEmpty) pw.Text('Location: $customerLocation', style: const pw.TextStyle(fontSize: 10)),
                  ]
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Referred By:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text(doctorName ?? 'Walk-in', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ]
                )
              ]
            ),
            pw.SizedBox(height: 16),
            
            // Items Table
            pw.Table(
              border: pw.TableBorder.all(color: primaryGreen, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5), // S.No
                1: const pw.FlexColumnWidth(2.5), // Item Name
                2: const pw.FlexColumnWidth(1),   // Batch
                3: const pw.FlexColumnWidth(1),   // Expiry
                4: const pw.FlexColumnWidth(1),   // HSN
                5: const pw.FlexColumnWidth(0.8), // Qty
                6: const pw.FlexColumnWidth(1),   // MRP
                7: const pw.FlexColumnWidth(1),   // CGST
                8: const pw.FlexColumnWidth(1),   // SGST
                9: const pw.FlexColumnWidth(1.2), // Total
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primaryGreen),
                  children: [
                    'S.No', 'Item Name', 'Batch', 'Expiry', 'HSN', 'Qty', 'MRP', 'CGST%', 'SGST%', 'Total'
                  ].map((text) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(text, style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)
                  )).toList(),
                ),
                // Data rows
                ...items.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var item = entry.value;
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${idx + 1}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item['name'], style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item['batch']?.toString() ?? '-', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item['expiry']?.toString() ?? '-', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item['hsn']?.toString() ?? '-', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item['qty'].toString(), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item['mrp'].toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${item['cgst']?.toString() ?? '0'}%', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${item['sgst']?.toString() ?? '0'}%', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item['total'].toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                    ]
                  );
                }),
              ],
            ),
            
            pw.SizedBox(height: 16),
            
            // Footer section (Bank Details, Terms, Summary)
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(color: primaryGreen, width: 1)),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left Side: Bank Details & QR
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: primaryGreen, width: 1))),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Bank Details', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                                pw.SizedBox(height: 4),
                                pw.Text('Bank: $bankName', style: const pw.TextStyle(fontSize: 8)),
                                pw.Text('Branch: $branchName', style: const pw.TextStyle(fontSize: 8)),
                                pw.Text('A/C Name: $acHolder', style: const pw.TextStyle(fontSize: 8)),
                                pw.Text('A/C No: $acNumber', style: const pw.TextStyle(fontSize: 8)),
                                pw.Text('IFSC: $ifsc', style: const pw.TextStyle(fontSize: 8)),
                              ]
                            )
                          ),
                          if (qrImage != null)
                            pw.Container(
                              width: 60, height: 60,
                              child: pw.Image(qrImage)
                            )
                        ]
                      )
                    )
                  ),
                  
                  // Middle: GST Summary
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: primaryGreen, width: 1))),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('GST Summary', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                          pw.SizedBox(height: 4),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('CGST', style: const pw.TextStyle(fontSize: 8)), pw.Text((tax/2).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8))]),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('SGST', style: const pw.TextStyle(fontSize: 8)), pw.Text((tax/2).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8))]),
                          pw.Divider(color: PdfColors.grey300),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('GST Total', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)), pw.Text(tax.toStringAsFixed(2), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))]),
                        ]
                      )
                    )
                  ),
                  
                  // Right: Amount Summary
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Taxable', style: const pw.TextStyle(fontSize: 8)), pw.Text(subtotal.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8))]),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Discount', style: const pw.TextStyle(fontSize: 8)), pw.Text(discount.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8))]),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Tax (GST)', style: const pw.TextStyle(fontSize: 8)), pw.Text(tax.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8))]),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Grand Total', style: const pw.TextStyle(fontSize: 8)), pw.Text(grandTotal.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8))]),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Round Off', style: const pw.TextStyle(fontSize: 8)), pw.Text(roundOff.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8))]),
                          pw.Divider(color: primaryGreen),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                            pw.Text('Rounded Total', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryGreen)), 
                            pw.Text(roundedTotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryGreen))
                          ]),
                        ]
                      )
                    )
                  )
                ]
              )
            ),
            
            // Terms & Conditions and Signature
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: primaryGreen, width: 1), right: pw.BorderSide(color: primaryGreen, width: 1), bottom: pw.BorderSide(color: primaryGreen, width: 1))),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 7,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: primaryGreen, width: 1))),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Terms & Conditions', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                          if (term1.isNotEmpty) pw.Text(term1, style: const pw.TextStyle(fontSize: 8)),
                          if (term2.isNotEmpty) pw.Text(term2, style: const pw.TextStyle(fontSize: 8)),
                          if (term3.isNotEmpty) pw.Text(term3, style: const pw.TextStyle(fontSize: 8)),
                        ]
                      )
                    )
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.SizedBox(height: 30), // Space for signature
                          pw.Text('For $shopName', style: const pw.TextStyle(fontSize: 8)),
                          pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8)),
                        ]
                      )
                    )
                  )
                ]
              )
            ),
          ];
        },
      )
    );

    return pdf.save();
  }
}
''')
