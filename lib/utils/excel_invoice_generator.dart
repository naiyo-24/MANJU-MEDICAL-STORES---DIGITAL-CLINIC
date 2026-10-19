import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:manju_medical/utils/format_utils.dart';

/// Generates valid, styled Microsoft Excel (.xlsx) invoice files replicating the exact
/// A5 Landscape Bill layout (Pharmacy Header, Billed To, Product Table, Totals, Bank Details, and Terms).
class ExcelInvoiceGenerator {
  static Uint8List generateInvoiceExcel({
    required List<dynamic> items,
    required double subtotal,
    required double discount,
    required double tax,
    required double grandTotal,
    required String invoiceNumber,
    required String customerName,
    String? customerPhone,
    String? customerLocation,
    String? gstNumber,
    String? doctorName,
    String? paymentMethod,
    Map<String, dynamic>? shopSettings,
    DateTime? billingDate,
  }) {
    final excel = Excel.createExcel();
    const sheetName = 'Invoice';
    final Sheet sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);

    // Delete default 'Sheet1' if present
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final String shopName = shopSettings?['shop_name'] ?? 'MANJU MEDICAL STORES & DIGITAL CLINIC';
    final String tagline = shopSettings?['tagline'] ?? '';
    final String address = shopSettings?['address'] ?? '';
    final String phone = shopSettings?['phone'] ?? '';
    final String email = shopSettings?['email'] ?? '';
    final String shopGstNo = shopSettings?['gst_number'] ?? '';
    final String drugLicence = shopSettings?['drug_licence'] ?? '';

    final String bankName = shopSettings?['bank_name'] ?? 'NA';
    final String branchName = shopSettings?['branch_name'] ?? 'NA';
    final String acHolder = shopSettings?['ac_holder_name'] ?? 'NA';
    final String acNumber = shopSettings?['ac_number'] ?? 'NA';
    final String ifsc = shopSettings?['ifsc_code'] ?? 'NA';

    final String term1 = shopSettings?['terms_1'] ?? '1. Medicines once sold will not be taken back.';
    final String term2 = shopSettings?['terms_2'] ?? '2. Store in cool and dry place.';
    final String term3 = shopSettings?['terms_3'] ?? '';

    final String dateStr = billingDate != null
        ? DateFormat('dd-MM-yyyy HH:mm').format(billingDate)
        : DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());

    double roundedTotal = grandTotal.roundToDouble();
    double roundOff = roundedTotal - grandTotal;

    // Set Column Widths (A through K: 11 columns)
    sheet.setColumnWidth(0, 8.0);   // S.No
    sheet.setColumnWidth(1, 32.0);  // Item Name
    sheet.setColumnWidth(2, 14.0);  // Batch
    sheet.setColumnWidth(3, 14.0);  // Expiry
    sheet.setColumnWidth(4, 12.0);  // HSN
    sheet.setColumnWidth(5, 10.0);  // Qty
    sheet.setColumnWidth(6, 12.0);  // MRP
    sheet.setColumnWidth(7, 10.0);  // Disc%
    sheet.setColumnWidth(8, 10.0);  // CGST%
    sheet.setColumnWidth(9, 10.0);  // SGST%
    sheet.setColumnWidth(10, 14.0); // Total

    // Cell Styles
    final titleStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#166534'),
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Left,
    );

    final taxInvoiceStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#166534'),
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Right,
    );

    final subheaderStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('#475569'),
      fontSize: 10,
    );

    final boldText = CellStyle(
      bold: true,
      fontSize: 10,
    );

    final rightBold = CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Right,
    );

    final tableHeaderStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#166534'),
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final tableRowCenter = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
    );

    final tableRowLeft = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Left,
    );

    final tableRowRight = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Right,
    );

    final tableRowRightBold = CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Right,
    );

    final sectionHeaderStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#166534'),
      fontSize: 11,
    );

    int currentRow = 0;

    // 1. TOP HEADER
    // Shop Name & TAX INVOICE
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue(shopName);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = titleStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).value = TextCellValue('TAX INVOICE');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).cellStyle = taxInvoiceStyle;
    currentRow++;

    // Tagline & Invoice No
    if (tagline.isNotEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue(tagline);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = subheaderStyle;
    }
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).value = TextCellValue('Invoice No: $invoiceNumber');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).cellStyle = rightBold;
    currentRow++;

    // Address & Date
    if (address.isNotEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue(address);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = subheaderStyle;
    }
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).value = TextCellValue('Date: $dateStr');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).cellStyle = CellStyle(fontSize: 10, horizontalAlign: HorizontalAlign.Right);
    currentRow++;

    // Contact info
    final contactParts = [
      if (phone.isNotEmpty) 'Phone: $phone',
      if (email.isNotEmpty) 'Email: $email',
    ].join(' | ');
    if (contactParts.isNotEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue(contactParts);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = subheaderStyle;
      currentRow++;
    }

    // Reg info
    final regParts = [
      if (shopGstNo.isNotEmpty) 'GSTIN: $shopGstNo',
      if (drugLicence.isNotEmpty) 'D.L. No.: $drugLicence',
    ].join(' | ');
    if (regParts.isNotEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue(regParts);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = boldText;
      currentRow++;
    }

    currentRow++; // Empty space

    // 2. BILLED TO & REFERRED BY
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Billed To:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = subheaderStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).value = TextCellValue('Referred By:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).cellStyle = CellStyle(fontSize: 9, horizontalAlign: HorizontalAlign.Right, fontColorHex: ExcelColor.fromHexString('#64748B'));
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue(customerName);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = boldText;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).value = TextCellValue(doctorName ?? 'Walk-in');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).cellStyle = rightBold;
    currentRow++;

    if (customerPhone != null && customerPhone.isNotEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Phone: $customerPhone');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = subheaderStyle;
      currentRow++;
    }
    if (customerLocation != null && customerLocation.isNotEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Location: $customerLocation');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = subheaderStyle;
      currentRow++;
    }
    if (gstNumber != null && gstNumber.isNotEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('GSTIN: $gstNumber');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = boldText;
      currentRow++;
    }

    currentRow++; // Spacing before table

    // 3. MAIN TABLE HEADERS
    final headers = [
      'S.No', 'Item Name', 'Batch', 'Expiry', 'HSN', 'Qty', 'MRP', 'Disc%', 'CGST%', 'SGST%', 'Total'
    ];
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = tableHeaderStyle;
    }
    currentRow++;

    // TABLE ROWS
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final String name = item['name']?.toString().split(' - Item')[0] ?? '';
      final String batch = item['batch']?.toString() ?? '-';
      final String expiry = item['expiry']?.toString() ?? '-';
      final String hsn = item['hsn']?.toString() ?? '-';
      final String qtyStr = FormatUtils.formatQty(item);
      final double mrp = _parseDouble(item['mrp']);
      final String disc = '${item['discount']?.toString() ?? '0'}%';
      final String cgst = '${item['cgst']?.toString() ?? '0'}%';
      final String sgst = '${item['sgst']?.toString() ?? '0'}%';
      final double total = _parseDouble(item['total']);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = IntCellValue(i + 1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = tableRowCenter;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue(name);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).cellStyle = tableRowLeft;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value = TextCellValue(batch);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).cellStyle = tableRowCenter;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue(expiry);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).cellStyle = tableRowCenter;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow)).value = TextCellValue(hsn);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow)).cellStyle = tableRowCenter;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).value = TextCellValue(qtyStr);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).cellStyle = tableRowCenter;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow)).value = DoubleCellValue(mrp);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow)).cellStyle = tableRowRight;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow)).value = TextCellValue(disc);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow)).cellStyle = tableRowRight;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: currentRow)).value = TextCellValue(cgst);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: currentRow)).cellStyle = tableRowRight;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRow)).value = TextCellValue(sgst);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRow)).cellStyle = tableRowRight;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).value = DoubleCellValue(total);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).cellStyle = tableRowRightBold;

      currentRow++;
    }

    currentRow++; // Empty row

    // 4. TOTALS & SUMMARY SECTION
    // Col 0-3: Bank Details | Col 5-6: GST Summary | Col 9-10: Amounts
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Bank Details');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = sectionHeaderStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).value = TextCellValue('GST Summary');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).cellStyle = sectionHeaderStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRow)).value = TextCellValue('Taxable Amount:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRow)).cellStyle = boldText;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).value = DoubleCellValue(subtotal);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).cellStyle = tableRowRight;
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Bank: $bankName');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = subheaderStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).value = TextCellValue('CGST:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow)).value = DoubleCellValue(tax / 2);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow)).cellStyle = tableRowRight;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRow)).value = TextCellValue('Discount:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRow)).cellStyle = boldText;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).value = DoubleCellValue(discount);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).cellStyle = tableRowRight;
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Branch: $branchName');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = subheaderStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).value = TextCellValue('SGST:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow)).value = DoubleCellValue(tax / 2);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow)).cellStyle = tableRowRight;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRow)).value = TextCellValue('Total Tax (GST):');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRow)).cellStyle = boldText;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).value = DoubleCellValue(tax);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).cellStyle = tableRowRight;
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('A/C Name: $acHolder');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = subheaderStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).value = TextCellValue('GST Total:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow)).cellStyle = boldText;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow)).value = DoubleCellValue(tax);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow)).cellStyle = tableRowRightBold;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRow)).value = TextCellValue('Payment Mode:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRow)).cellStyle = boldText;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).value = TextCellValue(paymentMethod ?? 'CASH');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).cellStyle = rightBold;
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('A/C No: $acNumber');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = subheaderStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRow)).value = TextCellValue('Round Off:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRow)).cellStyle = boldText;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).value = DoubleCellValue(roundOff);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).cellStyle = tableRowRight;
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('IFSC: $ifsc');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = subheaderStyle;

    final grandTotalStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#166534'),
      fontSize: 12,
      horizontalAlign: HorizontalAlign.Right,
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRow)).value = TextCellValue('Rounded Total:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRow)).cellStyle = grandTotalStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).value = DoubleCellValue(roundedTotal);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).cellStyle = grandTotalStyle;
    currentRow++;

    currentRow++; // Empty row

    // 5. TERMS & CONDITIONS AND SIGNATORY
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue('Terms & Conditions:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = sectionHeaderStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).value = TextCellValue('For $shopName');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).cellStyle = rightBold;
    currentRow++;

    if (term1.isNotEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue(term1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = subheaderStyle;
      currentRow++;
    }
    if (term2.isNotEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue(term2);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = subheaderStyle;
      currentRow++;
    }
    if (term3.isNotEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue(term3);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = subheaderStyle;
      currentRow++;
    }

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).value = TextCellValue('Authorized Signatory');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: currentRow)).cellStyle = CellStyle(fontSize: 10, horizontalAlign: HorizontalAlign.Right, fontColorHex: ExcelColor.fromHexString('#64748B'));

    final fileBytes = excel.save();
    return Uint8List.fromList(fileBytes ?? []);
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString().replaceAll(',', '')) ?? 0.0;
  }
}
