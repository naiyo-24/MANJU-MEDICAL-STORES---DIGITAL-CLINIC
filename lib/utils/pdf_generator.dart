import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';
import 'package:manju_medical/config/api_client.dart';
import 'package:printing/printing.dart';

Future<Uint8List> generateBillIsolate(Map<String, dynamic> args) async {
  return PdfGenerator.generateBill(
    items: args['items'],
    subtotal: args['subtotal'],
    discount: args['discount'],
    tax: args['tax'],
    grandTotal: args['grandTotal'],
    invoiceNumber: args['invoiceNumber'],
    customerName: args['customerName'],
    format: args['format'],
    customerPhone: args['customerPhone'],
    customerLocation: args['customerLocation'],
    doctorName: args['doctorName'],
    shopSettings: args['shopSettings'],
    logoBytes: args['logoBytes'],
    qrBytes: args['qrBytes'],
  );
}

class PdfGenerator {
  static pw.Font? _cachedFont;
  static pw.Font? _cachedFontBold;
  static Uint8List? _cachedDefaultLogo;
  static Uint8List? _cachedLogoBytes;
  static String? _cachedLogoUrl;
  
  static Uint8List? _cachedQrBytes;
  static String? _cachedQrUrl;

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
    String? gstNumber,
    Map<String, dynamic>? shopSettings,
    Uint8List? logoBytes,
    Uint8List? qrBytes,
  }) async {
    _cachedFont ??= await PdfGoogleFonts.robotoRegular();
    _cachedFontBold ??= await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: _cachedFont,
        bold: _cachedFontBold,
      ),
    );

    pw.ImageProvider? logoImage;
    pw.ImageProvider? qrImage;

    if (logoBytes != null) {
      logoImage = pw.MemoryImage(logoBytes);
    } else if (shopSettings?['logo_url'] != null && shopSettings!['logo_url'].toString().isNotEmpty) {
      String url = shopSettings['logo_url'];
      if (_cachedLogoUrl == url && _cachedLogoBytes != null) {
        logoImage = pw.MemoryImage(_cachedLogoBytes!);
      } else {
        try {
          final res = await ApiClient().dio.get(
            url,
            options: Options(responseType: ResponseType.bytes),
          );
          if (res.statusCode == 200) {
            _cachedLogoBytes = res.data;
            _cachedLogoUrl = url;
            logoImage = pw.MemoryImage(_cachedLogoBytes!);
          }
        } catch (e) {
          // Fallback to local
        }
      }
    }
    
    // Final fallback for logo
    if (logoImage == null) {
      try {
        if (_cachedDefaultLogo == null) {
          final ByteData data = await rootBundle.load('assets/LOGO.png');
          _cachedDefaultLogo = data.buffer.asUint8List();
        }
        logoImage = pw.MemoryImage(_cachedDefaultLogo!);
      } catch (e) {
        // ignore
      }
    }

    if (qrBytes != null) {
      qrImage = pw.MemoryImage(qrBytes);
    } else if (shopSettings?['qr_url'] != null && shopSettings!['qr_url'].toString().isNotEmpty) {
      String url = shopSettings['qr_url'];
      if (_cachedQrUrl == url && _cachedQrBytes != null) {
        qrImage = pw.MemoryImage(_cachedQrBytes!);
      } else {
        try {
          final res = await ApiClient().dio.get(
            url,
            options: Options(responseType: ResponseType.bytes),
          );
          if (res.statusCode == 200) {
            _cachedQrBytes = res.data;
            _cachedQrUrl = url;
            qrImage = pw.MemoryImage(_cachedQrBytes!);
          }
        } catch (e) {
          // Fallback
        }
      }
    }

    // No default QR code fallback available

    final String shopName = shopSettings?['shop_name'] ?? 'SirfBill Pharmacy';
    final String tagline = shopSettings?['tagline'] ?? 'Your Trusted Health Partner';
    final String address = shopSettings?['address'] ?? '123 Health Avenue, Medical District';
    final String phone = shopSettings?['phone'] ?? '+91 98765 43210';
    final String landline = shopSettings?['landline'] ?? '';
    final String email = shopSettings?['email'] ?? 'contact@sirfbill.com';
    final String gstNo = gstNumber?.isNotEmpty == true ? gstNumber! : (shopSettings?['gst_number'] ?? 'GSTIN27XXXXX1234');

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
                if (logoImage != null) pw.Image(logoImage, width: 50, height: 50),
                pw.SizedBox(height: 5),
                pw.Text(shopName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                pw.Text(address, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                pw.Text('Phone: $phone', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                pw.Text('GSTIN: $gstNo', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
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
                if (customerPhone != null && customerPhone.isNotEmpty)
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('Phone: $customerPhone', style: const pw.TextStyle(fontSize: 8)),
                  ),
                pw.SizedBox(height: 5),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 5),
                
                // Thermal Items Table
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Text('Item', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Qty', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        pw.Text('Amt', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      ]
                    ),
                    ...items.map((item) => pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(item['name'] ?? 'Unknown Item', style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text((item['qty'] ?? 0).toString(), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text((item['total'] ?? 0.0).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                      ]
                    )),
                  ]
                ),
                pw.SizedBox(height: 5),
                pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 5),
                
                // Totals
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(subtotal.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8)),
                  ]
                ),
                if (discount > 0) pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(discount.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8)),
                  ]
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tax (GST):', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(tax.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8)),
                  ]
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Grand Total:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(roundedTotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ]
                ),
                pw.SizedBox(height: 10),
                if (qrImage != null)
                  pw.Container(
                    width: 60, height: 60,
                    child: pw.Image(qrImage)
                  ),
                pw.SizedBox(height: 10),
                pw.Text('Thank you! Visit Again.', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
              ]
            );
          }
        )
      );
    } else {
      // A4 or A5 format
      PdfPageFormat pageFormat = format == 'A4' ? PdfPageFormat.a4 : PdfPageFormat.a5.landscape;
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.all(format == 'A4' ? 24 : 12),
          header: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        width: format == 'A4' ? 65 : 40,
                        height: format == 'A4' ? 65 : 40,
                        child: pw.Image(logoImage),
                      ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(shopName, style: pw.TextStyle(fontSize: format == 'A4' ? 16 : 12, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                          if (tagline.isNotEmpty) pw.Text(tagline, style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8, color: PdfColors.grey700)),
                          pw.SizedBox(height: 2),
                          pw.Text(address, style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8)),
                          pw.Text('Phone: $phone ${landline.isNotEmpty ? '| $landline' : ''}', style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8)),
                          pw.Text('Email: $email', style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8)),
                          pw.Text('GSTIN: $gstNo', style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8, fontWeight: pw.FontWeight.bold)),
                        ]
                      )
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: format == 'A4' ? 16 : 12, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                        pw.SizedBox(height: 4),
                        pw.Text('Invoice No: $invoiceNumber', style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Date: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}', style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8)),
                      ]
                    )
                  ]
                ),
                pw.SizedBox(height: format == 'A4' ? 8 : 4),
                pw.Divider(color: primaryGreen, thickness: 1.5),
                pw.SizedBox(height: format == 'A4' ? 4 : 2),
                
                // Customer Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Billed To:', style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8, color: PdfColors.grey700)),
                        pw.Text(customerName, style: pw.TextStyle(fontSize: format == 'A4' ? 12 : 10, fontWeight: pw.FontWeight.bold)),
                        if (customerPhone != null && customerPhone.isNotEmpty) pw.Text('Phone: $customerPhone', style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8)),
                        if (customerLocation != null && customerLocation.isNotEmpty) pw.Text('Location: $customerLocation', style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8)),
                      ]
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Referred By:', style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8, color: PdfColors.grey700)),
                        pw.Text(doctorName ?? 'Walk-in', style: pw.TextStyle(fontSize: format == 'A4' ? 12 : 10, fontWeight: pw.FontWeight.bold)),
                      ]
                    )
                  ]
                ),
                pw.SizedBox(height: format == 'A4' ? 16 : 8),
              ]
            );
          },
          footer: (pw.Context context) {
            return pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
              // Bank Details, GST, Summary (Appended immediately after the table on the last page)
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(color: primaryGreen, width: 1)),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left Side: Bank Details & QR
                    pw.Expanded(
                      flex: 4,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: primaryGreen, width: 1))),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Bank Details', style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                                  pw.SizedBox(height: 2),
                                  pw.Text('Bank: $bankName', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                  pw.Text('Branch: $branchName', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                  pw.Text('A/C Name: $acHolder', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                  pw.Text('A/C No: $acNumber', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                  pw.Text('IFSC: $ifsc', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                                ]
                              )
                            ),
                            if (qrImage != null)
                              pw.Container(
                                width: format == 'A4' ? 80 : 60, 
                                height: format == 'A4' ? 80 : 60,
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
                        padding: const pw.EdgeInsets.all(4),
                        decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: primaryGreen, width: 1))),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('GST Summary', style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                            pw.SizedBox(height: 2),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('CGST', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)), pw.Text((tax/2).toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7))]),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('SGST', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)), pw.Text((tax/2).toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7))]),
                            pw.Divider(color: PdfColors.grey300),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('GST Total', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7, fontWeight: pw.FontWeight.bold)), pw.Text(tax.toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7, fontWeight: pw.FontWeight.bold))]),
                          ]
                        )
                      )
                    ),
                    
                    // Right: Amount Summary
                    pw.Expanded(
                      flex: 3,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Taxable', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)), pw.Text(subtotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7))]),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Discount', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)), pw.Text(discount.toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7))]),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Tax (GST)', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)), pw.Text(tax.toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7))]),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Grand Total', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)), pw.Text(grandTotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7))]),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Round Off', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)), pw.Text(roundOff.toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7))]),
                            pw.Divider(color: primaryGreen),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                              pw.Text('Rounded Total', style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8, fontWeight: pw.FontWeight.bold, color: primaryGreen)), 
                              pw.Text(roundedTotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8, fontWeight: pw.FontWeight.bold, color: primaryGreen))
                            ]),
                          ]
                        )
                      )
                    )
                  ]
                )
              ),
                pw.SizedBox(height: 4),
                pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(color: primaryGreen, width: 1)),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 7,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: primaryGreen, width: 1))),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Terms & Conditions', style: pw.TextStyle(fontSize: format == 'A4' ? 10 : 8, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                          if (term1.isNotEmpty) pw.Text(term1, style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                          if (term2.isNotEmpty) pw.Text(term2, style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                          if (term3.isNotEmpty) pw.Text(term3, style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                        ]
                      )
                    )
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.SizedBox(height: format == 'A4' ? 15 : 10),
                          pw.Text('For $shopName', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                          pw.Text('Authorized Signatory', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7)),
                        ]
                      )
                    )
                  )
                ]
              )
            )
              ]
            );
          },
          build: (pw.Context context) {
            return [
              // Items Table
              pw.Table(
                border: pw.TableBorder(
                  left: pw.BorderSide(color: primaryGreen, width: 0.5),
                  right: pw.BorderSide(color: primaryGreen, width: 0.5),
                  top: pw.BorderSide(color: primaryGreen, width: 0.5),
                  bottom: pw.BorderSide(color: primaryGreen, width: 0.5),
                  verticalInside: pw.BorderSide(color: primaryGreen, width: 0.5),
                  horizontalInside: pw.BorderSide.none, // Removed horizontal lines
                ),
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
                    repeat: true,
                    decoration: pw.BoxDecoration(color: primaryGreen),
                    children: [
                      'S.No', 'Item Name', 'Batch', 'Expiry', 'HSN', 'Qty', 'MRP', 'CGST%', 'SGST%', 'Total'
                    ].map((text) => pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(text, style: pw.TextStyle(color: PdfColors.white, fontSize: format == 'A4' ? 8 : 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)
                    )).toList(),
                  ),
                  // Data rows
                  ...items.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var item = entry.value;
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: format == 'A4' ? 4 : 2, horizontal: 4), child: pw.Text('${idx + 1}', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: format == 'A4' ? 4 : 2, horizontal: 4), child: pw.Text(item['name'], style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7))),
                        pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: format == 'A4' ? 4 : 2, horizontal: 4), child: pw.Text(item['batch']?.toString() ?? '-', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: format == 'A4' ? 4 : 2, horizontal: 4), child: pw.Text(item['expiry']?.toString() ?? '-', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: format == 'A4' ? 4 : 2, horizontal: 4), child: pw.Text(item['hsn']?.toString() ?? '-', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: format == 'A4' ? 4 : 2, horizontal: 4), child: pw.Text((item['qty'] ?? 0).toString(), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: format == 'A4' ? 4 : 2, horizontal: 4), child: pw.Text((item['mrp'] ?? 0.0).toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: format == 'A4' ? 4 : 2, horizontal: 4), child: pw.Text('${item['cgst']?.toString() ?? '0'}%', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: format == 'A4' ? 4 : 2, horizontal: 4), child: pw.Text('${item['sgst']?.toString() ?? '0'}%', style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: format == 'A4' ? 4 : 2, horizontal: 4), child: pw.Text((item['total'] ?? 0.0).toStringAsFixed(2), style: pw.TextStyle(fontSize: format == 'A4' ? 8 : 7), textAlign: pw.TextAlign.right)),
                      ]
                    );
                  }),
                ],
              ),
              
            ];
          }
        )
      );
    }

    return pdf.save();
  }
}
