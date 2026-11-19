import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'format_utils.dart';

class PdfThermalGenerator {
  /// Calculate the exact physical receipt height to avoid infinite height bugs
  /// on Windows spoolers and Web print engines.
  static double calculateThermalHeight({
    required int itemCount,
    bool hasLogo = false,
    bool hasQr = false,
    bool hasDrugLicence = false,
  }) {
    // Exact height breakdown in millimeters:
    // Top & Bottom margins: 2mm + 6mm = 8mm
    // Logo: 50mm height + 5mm gap = 55mm (if present)
    // Shop info (Name, address, phone, GSTIN, DL): ~30mm to 36mm
    // Invoice No, Date, Customer info: ~18mm
    // Table Header + Divider: ~12mm
    // Each Item row (Name, Qty, Amount): ~7.5mm
    // Table bottom divider + Totals (Subtotal, Tax, Grand Total): ~30mm
    // QR code: 60mm + 10mm gap = 70mm (if present)
    // Footer "Thank you! Visit Again.": ~15mm
    // Safety buffer: ~10mm
    double heightMm = 8.0 + 30.0 + 18.0 + 12.0 + (itemCount * 7.5) + 30.0 + 15.0 + 10.0;
    if (hasLogo) heightMm += 55.0;
    if (hasQr) heightMm += 70.0;
    if (hasDrugLicence) heightMm += 6.0;

    return heightMm * PdfPageFormat.mm;
  }

  static Future<Uint8List> generateThermalBill({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double tax,
    required double grandTotal,
    required double roundedTotal,
    required String invoiceNumber,
    required String customerName,
    String? customerPhone,
    String? customerGstNo,
    required String shopName,
    required String address,
    required String phone,
    required String shopGstNo,
    required String drugLicence,
    pw.ImageProvider? logoImage,
    pw.ImageProvider? qrImage,
    DateTime? billingDate,
    pw.ThemeData? theme,
  }) async {
    final pdf = pw.Document(theme: theme);

    final pageHeight = calculateThermalHeight(
      itemCount: items.length,
      hasLogo: logoImage != null,
      hasQr: qrImage != null,
      hasDrugLicence: drugLicence.isNotEmpty,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          72 * PdfPageFormat.mm,
          pageHeight,
          marginLeft: 3 * PdfPageFormat.mm,
          marginRight: 4 * PdfPageFormat.mm,
          marginTop: 1 * PdfPageFormat.mm,
          marginBottom: 4 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Align(
            alignment: pw.Alignment.topCenter,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
              if (logoImage != null)
                pw.Image(logoImage, width: 50, height: 50),
              pw.SizedBox(height: 5),
              pw.Text(
                shopName,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                address,
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Phone: $phone',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'GSTIN: $shopGstNo',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              if (drugLicence.isNotEmpty)
                pw.Text(
                  'D.L. No.: $drugLicence',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Inv: $invoiceNumber',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    DateFormat('dd-MM-yyyy').format(billingDate ?? DateTime.now()),
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Customer: ${customerName.isNotEmpty ? customerName : 'Walk-in Customer'}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              if (customerPhone != null && customerPhone.isNotEmpty)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'Phone: $customerPhone',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              if (customerGstNo != null && customerGstNo.isNotEmpty)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'GSTIN: $customerGstNo',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),

              // Thermal Items Table
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3.0),
                  1: const pw.FlexColumnWidth(0.9),
                  2: const pw.FlexColumnWidth(1.6),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'Item',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Qty',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(right: 2),
                        child: pw.Text(
                          'Amt',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  ...items.map(
                    (item) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Text(
                            item['name'] ?? 'Unknown Item',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Text(
                            FormatUtils.formatQty(item),
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2, bottom: 2, right: 2),
                          child: pw.Text(
                            (item['total'] ?? 0.0).toStringAsFixed(2),
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),

              // Totals
              pw.Padding(
                padding: const pw.EdgeInsets.only(right: 2),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Subtotal:',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          subtotal.toStringAsFixed(2),
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                    if (discount > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Discount:',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            discount.toStringAsFixed(2),
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Tax (GST):',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          tax.toStringAsFixed(2),
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Grand Total:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          roundedTotal.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              if (qrImage != null)
                pw.Container(width: 60, height: 60, child: pw.Image(qrImage)),
              pw.SizedBox(height: 10),
              pw.Text(
                'Thank you! Visit Again.',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        );
        },
      ),
    );

    return pdf.save();
  }
}
