import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

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
    String? customerAge,
    String? doctorName,
  }) async {
    final pdf = pw.Document();

    final ByteData bytes = await rootBundle.load('assets/LOGO.png');
    final Uint8List logoBytes = bytes.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    const primaryGreen = PdfColor(22 / 255.0, 101 / 255.0, 52 / 255.0);
    const borderGreen = PdfColor(34 / 255.0, 197 / 255.0, 94 / 255.0);
    const lightGreen = PdfColor(220 / 255.0, 252 / 255.0, 231 / 255.0);
    const lighterGreen = PdfColor(240 / 255.0, 253 / 255.0, 244 / 255.0);

    if (format == 'Thermal') {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: const pw.EdgeInsets.all(10),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Image(logoImage, width: 50, height: 50),
                pw.SizedBox(height: 5),
                pw.Text('Manju Medical Stores', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text('123 Health Avenue, Medical District', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                pw.Text('Phone: +91 98765 43210', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 5),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Inv: $invoiceNumber', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(DateFormat('dd-MM-yyyy').format(DateTime.now()), style: const pw.TextStyle(fontSize: 8)),
                  ]
                ),
                pw.SizedBox(height: 2),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('Customer: ${customerName.isNotEmpty ? customerName : 'Walk-in Customer'}', style: const pw.TextStyle(fontSize: 8)),
                ),
                if (customerPhone?.isNotEmpty == true)
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('Phone: $customerPhone', style: const pw.TextStyle(fontSize: 8)),
                  ),
                if (doctorName?.isNotEmpty == true)
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('Doctor: $doctorName', style: const pw.TextStyle(fontSize: 8)),
                  ),
                pw.SizedBox(height: 5),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    pw.Expanded(flex: 3, child: pw.Text('Item', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 1, child: pw.Text('Qty', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    pw.Expanded(flex: 2, child: pw.Text('Total', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  ]
                ),
                pw.SizedBox(height: 2),
                ...items.map((item) {
                  final price = (item['price'] as num).toDouble();
                  final qty = (item['qty'] as num).toInt();
                  final total = price * qty;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(flex: 3, child: pw.Text(item['name'], style: const pw.TextStyle(fontSize: 8))),
                        pw.Expanded(flex: 1, child: pw.Text('$qty', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                        pw.Expanded(flex: 2, child: pw.Text(total.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                      ]
                    )
                  );
                }).toList(),
                pw.SizedBox(height: 5),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(subtotal.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8)),
                  ]
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(discount.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8)),
                  ]
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tax (GST):', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(tax.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8)),
                  ]
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Grand Total:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(grandTotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ]
                ),
                pw.SizedBox(height: 10),
                pw.BarcodeWidget(
                  data: 'upi://pay?pa=manju@upi&pn=ManjuMedical&am=$grandTotal',
                  barcode: pw.Barcode.qrCode(),
                  width: 50,
                  height: 50,
                ),
                pw.SizedBox(height: 5),
                pw.Text('Thank you! Visit again.', style: const pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
              ],
            );
          }
        )
      );
    } else {
      // A4 or A5 format
      PdfPageFormat pageFormat = format == 'A4' ? PdfPageFormat.a4 : PdfPageFormat.a5.landscape;
      
      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: pageFormat,
            margin: const pw.EdgeInsets.all(16),
            buildBackground: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Container(
                  margin: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderGreen, width: 1.5),
                  ),
                  child: pw.Stack(
                    children: [
                      pw.Positioned.fill(
                        child: pw.Center(
                          child: pw.Opacity(
                            opacity: 0.1,
                            child: pw.Image(logoImage, width: 250),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          header: (pw.Context context) {
            return pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 60,
                        height: 35,
                        alignment: pw.Alignment.center,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Manju Medical Stores & Digital Clinic', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                            pw.Text('123 Health Avenue, Medical District', style: const pw.TextStyle(fontSize: 7)),
                            pw.Text('GSTIN: 29AAAAA0000A1Z5 | DL No: 20B/21B/2026', style: const pw.TextStyle(fontSize: 7)),
                            pw.Text('Phone: +91 98765 43210 | Email: care@manjumedical.in', style: const pw.TextStyle(fontSize: 7)),
                          ],
                        ),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Tax Invoice', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                          pw.Text('Invoice No: $invoiceNumber', style: const pw.TextStyle(fontSize: 7)),
                          pw.Text('Date: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 7)),
                          pw.Text('Place of Supply: State', style: const pw.TextStyle(fontSize: 7)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Divider(color: borderGreen, thickness: 1.5, height: 0),
              ],
            );
          },
          footer: (pw.Context context) {
            return pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: borderGreen, width: 1.5),
                    )
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: borderGreen))),
                          child: pw.Row(
                            children: [
                              pw.Expanded(
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('Bank Details', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                                    pw.Text('Bank: State Bank of India', style: const pw.TextStyle(fontSize: 7)),
                                    pw.Text('A/C No: 123456789012', style: const pw.TextStyle(fontSize: 7)),
                                    pw.Text('IFSC: SBIN0000123', style: const pw.TextStyle(fontSize: 7)),
                                  ],
                                ),
                              ),
                              pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.BarcodeWidget(
                                    data: 'upi://pay?pa=manju@upi&pn=ManjuMedical&am=$grandTotal',
                                    barcode: pw.Barcode.qrCode(),
                                    width: 30,
                                    height: 30,
                                    color: primaryGreen,
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text('UPI ID: manju@upi', style: const pw.TextStyle(fontSize: 5)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: borderGreen))),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('GST Summary', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                              pw.SizedBox(height: 2),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                                pw.Text('CGST', style: const pw.TextStyle(fontSize: 7)), pw.Text('0.00', style: const pw.TextStyle(fontSize: 7))
                              ]),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                                pw.Text('SGST', style: const pw.TextStyle(fontSize: 7)), pw.Text('0.00', style: const pw.TextStyle(fontSize: 7))
                              ]),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                                pw.Text('GST Total', style: const pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)), pw.Text('0.00', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))
                              ]),
                            ],
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Column(
                            children: [
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                                pw.Text('Taxable', style: const pw.TextStyle(fontSize: 7)), pw.Text(subtotal.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 7))
                              ]),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                                pw.Text('Discount', style: const pw.TextStyle(fontSize: 7)), pw.Text(discount.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 7))
                              ]),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                                pw.Text('Tax (GST)', style: const pw.TextStyle(fontSize: 7)), pw.Text(tax.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 7))
                              ]),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                                pw.Text('Grand Total', style: const pw.TextStyle(fontSize: 7)), pw.Text(grandTotal.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 7))
                              ]),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                                pw.Text('Round Off', style: const pw.TextStyle(fontSize: 7)), pw.Text('0.00', style: const pw.TextStyle(fontSize: 7))
                              ]),
                              pw.SizedBox(height: 2),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                                pw.Text('Rounded Total', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryGreen)), 
                                pw.Text(grandTotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryGreen))
                              ]),
                              pw.SizedBox(height: 2),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                pw.Text('In Words:', style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey700)),
                                pw.Expanded(child: pw.Text('Rupees Only', style: const pw.TextStyle(fontSize: 5, color: primaryGreen), textAlign: pw.TextAlign.right)),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Divider(color: borderGreen, thickness: 1.5, height: 0),
                pw.Container(
                  height: 25,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(2),
                          decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: borderGreen))),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Terms & Conditions', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                              pw.Text('1. Medicines once sold will not be taken back.', style: const pw.TextStyle(fontSize: 5)),
                              pw.Text('2. Store in cool and dry place.', style: const pw.TextStyle(fontSize: 5)),
                              pw.Text('3. Subject to City jurisdiction only.', style: const pw.TextStyle(fontSize: 5)),
                            ],
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(2),
                          alignment: pw.Alignment.bottomRight,
                          child: pw.Text('For Manju Medical Stores Authorized Signature', style: const pw.TextStyle(fontSize: 6, color: primaryGreen)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          build: (pw.Context context) {
            return [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Bill To', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                          pw.Text(customerName.isNotEmpty ? customerName : 'Walk-in Customer', style: const pw.TextStyle(fontSize: 8)),
                          pw.Text('Phone: ${customerPhone?.isNotEmpty == true ? customerPhone : "N/A"}', style: const pw.TextStyle(fontSize: 7)),
                          pw.Text('GSTIN: N/A', style: const pw.TextStyle(fontSize: 7)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Patient / Doctor', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                          pw.Text('Patient: ${customerName.isNotEmpty ? customerName : 'Walk-in'}', style: const pw.TextStyle(fontSize: 7)),
                          pw.Text('Age: ${customerAge?.isNotEmpty == true ? customerAge : "N/A"}', style: const pw.TextStyle(fontSize: 7)),
                          pw.Text('Doctor: ${doctorName?.isNotEmpty == true ? doctorName : "Dr. Default"}', style: const pw.TextStyle(fontSize: 7)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.Table(
                border: pw.TableBorder.all(color: borderGreen),
                columnWidths: const {
                  0: pw.FixedColumnWidth(25),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1),
                  4: pw.FlexColumnWidth(1),
                  5: pw.FlexColumnWidth(1),
                  6: pw.FlexColumnWidth(1),
                  7: pw.FlexColumnWidth(1),
                  8: pw.FlexColumnWidth(1),
                  9: pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: lightGreen),
                    children: [
                      'SN', 'Items', 'Batch', 'Exp', 'MRP', 'Rate', 'Disc', 'CGST', 'SGST', 'Total'
                    ].map((h) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                      child: pw.Text(h, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: primaryGreen), textAlign: pw.TextAlign.center),
                    )).toList(),
                  ),
                  ...List.generate(items.length, (index) {
                    final item = items[index];
                    final price = (item['price'] as num).toDouble();
                    final qty = (item['qty'] as num).toInt();
                    final total = price * qty;
                    
                    return pw.TableRow(
                      children: [
                        '${index + 1}',
                        item['name'],
                        'B123',
                        '12/26',
                        price.toStringAsFixed(2),
                        price.toStringAsFixed(2),
                        '0.00',
                        '0.00',
                        '0.00',
                        total.toStringAsFixed(2),
                      ].asMap().entries.map((e) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        child: pw.Text(
                          e.value,
                          style: const pw.TextStyle(fontSize: 7),
                          textAlign: e.key == 1 ? pw.TextAlign.left : (e.key == 0 ? pw.TextAlign.center : pw.TextAlign.right),
                        ),
                      )).toList(),
                    );
                  }),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: lighterGreen),
                    children: [
                      pw.Container(),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        child: pw.Text('Totals', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: primaryGreen), textAlign: pw.TextAlign.right),
                      ),
                      pw.Container(), pw.Container(), pw.Container(), pw.Container(),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        child: pw.Text('0.00', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        child: pw.Text('0.00', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        child: pw.Text('0.00', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        child: pw.Text(subtotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: primaryGreen), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );
    }

    return pdf.save();
  }
}
