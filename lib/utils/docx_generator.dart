import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:manju_medical/utils/format_utils.dart';

/// Generates valid, clean Microsoft Word (.docx) documents for invoices.
/// Fully compatible with Microsoft Word, Apple Pages, Google Docs, and LibreOffice.
class DocxGenerator {
  /// Generates a .docx file as raw bytes for a billing invoice.
  static Uint8List generateInvoiceDocx({
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
    final archive = Archive();

    // 1. [Content_Types].xml
    const contentTypesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\r\n'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\r\n'
        '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\r\n'
        '  <Default Extension="xml" ContentType="application/xml"/>\r\n'
        '  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>\r\n'
        '  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>\r\n'
        '</Types>';
    final contentTypesBytes = utf8.encode(contentTypesXml);
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesBytes.length, contentTypesBytes));

    // 2. _rels/.rels
    const rootRelsXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\r\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\r\n'
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>\r\n'
        '</Relationships>';
    final rootRelsBytes = utf8.encode(rootRelsXml);
    archive.addFile(ArchiveFile('_rels/.rels', rootRelsBytes.length, rootRelsBytes));

    // 3. word/_rels/document.xml.rels
    const docRelsXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\r\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\r\n'
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>\r\n'
        '</Relationships>';
    final docRelsBytes = utf8.encode(docRelsXml);
    archive.addFile(ArchiveFile('word/_rels/document.xml.rels', docRelsBytes.length, docRelsBytes));

    // 4. word/styles.xml
    const stylesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\r\n'
        '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">\r\n'
        '  <w:docDefaults>\r\n'
        '    <w:rPrDefault>\r\n'
        '      <w:rPr>\r\n'
        '        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>\r\n'
        '        <w:sz w:val="20"/>\r\n'
        '        <w:szCs w:val="20"/>\r\n'
        '      </w:rPr>\r\n'
        '    </w:rPrDefault>\r\n'
        '    <w:pPrDefault>\r\n'
        '      <w:pPr>\r\n'
        '        <w:spacing w:after="60" w:line="240" w:lineRule="auto"/>\r\n'
        '      </w:pPr>\r\n'
        '    </w:pPrDefault>\r\n'
        '  </w:docDefaults>\r\n'
        '</w:styles>';
    final stylesBytes = utf8.encode(stylesXml);
    archive.addFile(ArchiveFile('word/styles.xml', stylesBytes.length, stylesBytes));

    // 5. word/document.xml (Content)
    final documentXml = _buildDocumentXml(
      items: items,
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      grandTotal: grandTotal,
      invoiceNumber: invoiceNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      customerLocation: customerLocation,
      gstNumber: gstNumber,
      doctorName: doctorName,
      paymentMethod: paymentMethod,
      shopSettings: shopSettings,
      billingDate: billingDate,
    );
    final documentBytes = utf8.encode(documentXml);
    archive.addFile(ArchiveFile('word/document.xml', documentBytes.length, documentBytes));

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData ?? []);
  }

  static String _escapeXml(String? val) {
    if (val == null) return '';
    return val
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString().replaceAll(',', '')) ?? 0.0;
  }

  static String _buildDocumentXml({
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
    final String shopName = _escapeXml(shopSettings?['shop_name'] ?? 'MANJU MEDICAL STORES & DIGITAL CLINIC');
    final String address = _escapeXml(shopSettings?['address'] ?? '');
    final String phone = _escapeXml(shopSettings?['phone'] ?? '');
    final String email = _escapeXml(shopSettings?['email'] ?? '');
    final String shopGstNo = _escapeXml(shopSettings?['gst_number'] ?? '');
    final String drugLicence = _escapeXml(shopSettings?['drug_licence'] ?? '');

    final String dateStr = billingDate != null
        ? DateFormat('dd-MM-yyyy HH:mm').format(billingDate)
        : DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());

    double roundedTotal = grandTotal.roundToDouble();
    double roundOff = roundedTotal - grandTotal;

    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\r\n');
    buffer.write('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">\r\n');
    buffer.write('  <w:body>\r\n');

    // Title / Shop Header
    buffer.write('    <w:p>\r\n');
    buffer.write('      <w:pPr><w:jc w:val="center"/><w:spacing w:after="40"/></w:pPr>\r\n');
    buffer.write('      <w:r><w:rPr><w:b/><w:sz w:val="32"/><w:color w:val="166534"/></w:rPr><w:t>$shopName</w:t></w:r>\r\n');
    buffer.write('    </w:p>\r\n');

    if (address.isNotEmpty) {
      buffer.write('    <w:p>\r\n');
      buffer.write('      <w:pPr><w:jc w:val="center"/><w:spacing w:after="20"/></w:pPr>\r\n');
      buffer.write('      <w:r><w:rPr><w:sz w:val="18"/><w:color w:val="475569"/></w:rPr><w:t>$address</w:t></w:r>\r\n');
      buffer.write('    </w:p>\r\n');
    }

    final contactLine = [
      if (phone.isNotEmpty) 'Phone: $phone',
      if (email.isNotEmpty) 'Email: $email',
      if (shopGstNo.isNotEmpty) 'GSTIN: $shopGstNo',
      if (drugLicence.isNotEmpty) 'D.L. No: $drugLicence',
    ].join(' | ');

    if (contactLine.isNotEmpty) {
      buffer.write('    <w:p>\r\n');
      buffer.write('      <w:pPr><w:jc w:val="center"/><w:spacing w:after="100"/></w:pPr>\r\n');
      buffer.write('      <w:r><w:rPr><w:sz w:val="16"/><w:color w:val="475569"/></w:rPr><w:t>${_escapeXml(contactLine)}</w:t></w:r>\r\n');
      buffer.write('    </w:p>\r\n');
    }

    // TAX INVOICE Header
    buffer.write('    <w:p>\r\n');
    buffer.write('      <w:pPr><w:jc w:val="center"/><w:spacing w:after="140"/></w:pPr>\r\n');
    buffer.write('      <w:r><w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="166534"/></w:rPr><w:t>TAX INVOICE</w:t></w:r>\r\n');
    buffer.write('    </w:p>\r\n');

    // Customer & Invoice Details Table (Total width 9500 dxa: Col 1 = 5500 dxa, Col 2 = 4000 dxa)
    buffer.write('    <w:tbl>\r\n');
    buffer.write('      <w:tblPr>\r\n');
    buffer.write('        <w:tblW w:w="9500" w:type="dxa"/>\r\n');
    buffer.write('        <w:tblLayout w:type="fixed"/>\r\n');
    buffer.write('        <w:tblBorders>\r\n');
    buffer.write('          <w:top w:val="single" w:sz="4" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:bottom w:val="single" w:sz="4" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:left w:val="none"/>\r\n');
    buffer.write('          <w:right w:val="none"/>\r\n');
    buffer.write('          <w:insideH w:val="none"/>\r\n');
    buffer.write('          <w:insideV w:val="none"/>\r\n');
    buffer.write('        </w:tblBorders>\r\n');
    buffer.write('      </w:tblPr>\r\n');
    buffer.write('      <w:tblGrid>\r\n');
    buffer.write('        <w:gridCol w:w="5500"/>\r\n');
    buffer.write('        <w:gridCol w:w="4000"/>\r\n');
    buffer.write('      </w:tblGrid>\r\n');
    buffer.write('      <w:tr>\r\n');
    buffer.write('        <w:tc>\r\n');
    buffer.write('          <w:tcPr><w:tcW w:w="5500" w:type="dxa"/></w:tcPr>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>Billed To: ${_escapeXml(customerName)}</w:t></w:r></w:p>\r\n');
    if (customerPhone != null && customerPhone.isNotEmpty) {
      buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Phone: ${_escapeXml(customerPhone)}</w:t></w:r></w:p>\r\n');
    }
    if (customerLocation != null && customerLocation.isNotEmpty) {
      buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Location: ${_escapeXml(customerLocation)}</w:t></w:r></w:p>\r\n');
    }
    if (gstNumber != null && gstNumber.isNotEmpty) {
      buffer.write('          <w:p><w:r><w:rPr><w:b/><w:sz w:val="16"/></w:rPr><w:t>GSTIN: ${_escapeXml(gstNumber)}</w:t></w:r></w:p>\r\n');
    }
    buffer.write('        </w:tc>\r\n');
    buffer.write('        <w:tc>\r\n');
    buffer.write('          <w:tcPr><w:tcW w:w="4000" w:type="dxa"/></w:tcPr>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>Invoice No: ${_escapeXml(invoiceNumber)}</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Date: $dateStr</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Referred By: ${_escapeXml(doctorName ?? 'Walk-in')}</w:t></w:r></w:p>\r\n');
    buffer.write('        </w:tc>\r\n');
    buffer.write('      </w:tr>\r\n');
    buffer.write('    </w:tbl>\r\n');
    buffer.write('    <w:p><w:pPr><w:spacing w:after="160"/></w:pPr></w:p>\r\n');

    // Column widths in dxa (Sum = 9500 dxa)
    const colWidths = [500, 2600, 1100, 1000, 800, 700, 900, 600, 600, 700];

    // Main Items Table
    buffer.write('    <w:tbl>\r\n');
    buffer.write('      <w:tblPr>\r\n');
    buffer.write('        <w:tblW w:w="9500" w:type="dxa"/>\r\n');
    buffer.write('        <w:tblLayout w:type="fixed"/>\r\n');
    buffer.write('        <w:tblBorders>\r\n');
    buffer.write('          <w:top w:val="single" w:sz="6" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:left w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>\r\n');
    buffer.write('          <w:bottom w:val="single" w:sz="6" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:right w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>\r\n');
    buffer.write('          <w:insideH w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>\r\n');
    buffer.write('          <w:insideV w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>\r\n');
    buffer.write('        </w:tblBorders>\r\n');
    buffer.write('      </w:tblPr>\r\n');
    buffer.write('      <w:tblGrid>\r\n');
    for (final w in colWidths) {
      buffer.write('        <w:gridCol w:w="$w"/>\r\n');
    }
    buffer.write('      </w:tblGrid>\r\n');

    // Header row
    buffer.write('      <w:tr>\r\n');
    buffer.write(_buildTableHeaderCell('S.No', colWidths[0], 'center'));
    buffer.write(_buildTableHeaderCell('Item Name', colWidths[1], 'left'));
    buffer.write(_buildTableHeaderCell('Batch', colWidths[2], 'center'));
    buffer.write(_buildTableHeaderCell('Expiry', colWidths[3], 'center'));
    buffer.write(_buildTableHeaderCell('HSN', colWidths[4], 'center'));
    buffer.write(_buildTableHeaderCell('Qty', colWidths[5], 'center'));
    buffer.write(_buildTableHeaderCell('MRP', colWidths[6], 'right'));
    buffer.write(_buildTableHeaderCell('Disc%', colWidths[7], 'right'));
    buffer.write(_buildTableHeaderCell('GST%', colWidths[8], 'right'));
    buffer.write(_buildTableHeaderCell('Total', colWidths[9], 'right'));
    buffer.write('      </w:tr>\r\n');

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final String name = _escapeXml(item['name']?.toString().split(' - Item')[0] ?? '');
      final String batch = _escapeXml(item['batch']?.toString() ?? '-');
      final String expiry = _escapeXml(item['expiry']?.toString() ?? '-');
      final String hsn = _escapeXml(item['hsn']?.toString() ?? '-');
      final String qtyStr = FormatUtils.formatQty(item);
      final double mrp = _parseDouble(item['mrp']);
      final String disc = '${item['discount']?.toString() ?? '0'}%';
      final double cgst = _parseDouble(item['cgst']);
      final double sgst = _parseDouble(item['sgst']);
      final String gstTotal = '${(cgst + sgst).toStringAsFixed(0)}%';
      final double total = _parseDouble(item['total']);

      buffer.write('      <w:tr>\r\n');
      buffer.write(_buildTableCell('${i + 1}', colWidths[0], 'center'));
      buffer.write(_buildTableCell(name, colWidths[1], 'left'));
      buffer.write(_buildTableCell(batch, colWidths[2], 'center'));
      buffer.write(_buildTableCell(expiry, colWidths[3], 'center'));
      buffer.write(_buildTableCell(hsn, colWidths[4], 'center'));
      buffer.write(_buildTableCell(qtyStr, colWidths[5], 'center'));
      buffer.write(_buildTableCell(mrp.toStringAsFixed(2), colWidths[6], 'right'));
      buffer.write(_buildTableCell(disc, colWidths[7], 'right'));
      buffer.write(_buildTableCell(gstTotal, colWidths[8], 'right'));
      buffer.write(_buildTableCell(total.toStringAsFixed(2), colWidths[9], 'right', isBold: true));
      buffer.write('      </w:tr>\r\n');
    }
    buffer.write('    </w:tbl>\r\n');

    // Spacing
    buffer.write('    <w:p><w:pPr><w:spacing w:after="140"/></w:pPr></w:p>\r\n');

    // Totals Table (Total width 9500 dxa: Col 1 = 5500 dxa, Col 2 = 4000 dxa)
    buffer.write('    <w:tbl>\r\n');
    buffer.write('      <w:tblPr>\r\n');
    buffer.write('        <w:tblW w:w="9500" w:type="dxa"/>\r\n');
    buffer.write('        <w:tblLayout w:type="fixed"/>\r\n');
    buffer.write('        <w:tblBorders>\r\n');
    buffer.write('          <w:top w:val="single" w:sz="6" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:bottom w:val="single" w:sz="6" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:left w:val="none"/>\r\n');
    buffer.write('          <w:right w:val="none"/>\r\n');
    buffer.write('          <w:insideH w:val="none"/>\r\n');
    buffer.write('          <w:insideV w:val="none"/>\r\n');
    buffer.write('        </w:tblBorders>\r\n');
    buffer.write('      </w:tblPr>\r\n');
    buffer.write('      <w:tblGrid>\r\n');
    buffer.write('        <w:gridCol w:w="5500"/>\r\n');
    buffer.write('        <w:gridCol w:w="4000"/>\r\n');
    buffer.write('      </w:tblGrid>\r\n');
    buffer.write('      <w:tr>\r\n');
    buffer.write('        <w:tc>\r\n');
    buffer.write('          <w:tcPr><w:tcW w:w="5500" w:type="dxa"/></w:tcPr>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="166534"/></w:rPr><w:t>Payment Details</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Payment Method: ${_escapeXml(paymentMethod ?? 'CASH')}</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>CGST: Rs. ${(tax / 2).toStringAsFixed(2)} | SGST: Rs. ${(tax / 2).toStringAsFixed(2)}</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="16"/><w:color w:val="64748B"/></w:rPr><w:t>Thank you for your business!</w:t></w:r></w:p>\r\n');
    buffer.write('        </w:tc>\r\n');
    buffer.write('        <w:tc>\r\n');
    buffer.write('          <w:tcPr><w:tcW w:w="4000" w:type="dxa"/></w:tcPr>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Taxable Amount: Rs. ${subtotal.toStringAsFixed(2)}</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Discount: Rs. ${discount.toStringAsFixed(2)}</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Total Tax (GST): Rs. ${tax.toStringAsFixed(2)}</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Round Off: Rs. ${roundOff.toStringAsFixed(2)}</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="166534"/></w:rPr><w:t>Grand Total: Rs. ${roundedTotal.toStringAsFixed(2)}</w:t></w:r></w:p>\r\n');
    buffer.write('        </w:tc>\r\n');
    buffer.write('      </w:tr>\r\n');
    buffer.write('    </w:tbl>\r\n');

    // Section Properties (A4 Portrait, 11906 x 16838 dxa with 1000 dxa safe margins on left and right)
    buffer.write('    <w:sectPr>\r\n');
    buffer.write('      <w:pgSz w:w="11906" w:h="16838"/>\r\n');
    buffer.write('      <w:pgMar w:top="1000" w:right="1200" w:bottom="1000" w:left="1200" w:header="720" w:footer="720" w:gutter="0"/>\r\n');
    buffer.write('    </w:sectPr>\r\n');
    buffer.write('  </w:body>\r\n');
    buffer.write('</w:document>\r\n');

    return buffer.toString();
  }

  static String _buildTableHeaderCell(String text, int widthDxa, String align) {
    return '        <w:tc>\r\n'
        '          <w:tcPr>\r\n'
        '            <w:tcW w:w="$widthDxa" w:type="dxa"/>\r\n'
        '            <w:shd w:val="clear" w:color="auto" w:fill="166534"/>\r\n'
        '          </w:tcPr>\r\n'
        '          <w:p>\r\n'
        '            <w:pPr><w:jc w:val="$align"/></w:pPr>\r\n'
        '            <w:r><w:rPr><w:b/><w:sz w:val="16"/><w:color w:val="FFFFFF"/></w:rPr><w:t>${_escapeXml(text)}</w:t></w:r>\r\n'
        '          </w:p>\r\n'
        '        </w:tc>\r\n';
  }

  static String _buildTableCell(String text, int widthDxa, String align, {bool isBold = false}) {
    return '        <w:tc>\r\n'
        '          <w:tcPr>\r\n'
        '            <w:tcW w:w="$widthDxa" w:type="dxa"/>\r\n'
        '          </w:tcPr>\r\n'
        '          <w:p>\r\n'
        '            <w:pPr><w:jc w:val="$align"/></w:pPr>\r\n'
        '            <w:r>\r\n'
        '              <w:rPr>\r\n'
        '                ${isBold ? '<w:b/>' : ''}\r\n'
        '                <w:sz w:val="16"/>\r\n'
        '              </w:rPr>\r\n'
        '              <w:t>${_escapeXml(text)}</w:t>\r\n'
        '            </w:r>\r\n'
        '          </w:p>\r\n'
        '        </w:tc>\r\n';
  }
}
