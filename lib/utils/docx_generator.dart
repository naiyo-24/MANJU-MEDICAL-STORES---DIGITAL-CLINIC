import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:manju_medical/utils/format_utils.dart';

/// Generates valid Microsoft Word (.docx) documents for invoices.
/// A .docx file is an OpenXML ZIP archive containing standardized XML files.
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
    const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';
    archive.addFile(ArchiveFile('[Content_Types].xml', utf8.encode(contentTypesXml).length, utf8.encode(contentTypesXml)));

    // 2. _rels/.rels
    const rootRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('_rels/.rels', utf8.encode(rootRelsXml).length, utf8.encode(rootRelsXml)));

    // 3. word/_rels/document.xml.rels
    const docRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('word/_rels/document.xml.rels', utf8.encode(docRelsXml).length, utf8.encode(docRelsXml)));

    // 4. word/styles.xml
    const stylesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>
        <w:sz w:val="20"/>
        <w:szCs w:val="20"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr>
        <w:spacing w:after="80" w:line="240" w:lineRule="auto"/>
      </w:pPr>
    </w:pPrDefault>
  </w:docDefaults>
</w:styles>''';
    archive.addFile(ArchiveFile('word/styles.xml', utf8.encode(stylesXml).length, utf8.encode(stylesXml)));

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
    archive.addFile(ArchiveFile('word/document.xml', utf8.encode(documentXml).length, utf8.encode(documentXml)));

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
    final String shopName = _escapeXml(shopSettings?['shop_name'] ?? 'MANJU MEDICAL STORES &amp; DIGITAL CLINIC');
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
    buffer.write('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
''');

    // Title / Shop Header
    buffer.write('''
    <w:p>
      <w:pPr><w:jc w:val="center"/><w:spacing w:after="40"/></w:pPr>
      <w:r><w:rPr><w:b/><w:sz w:val="32"/><w:color w:val="166534"/></w:rPr><w:t>$shopName</w:t></w:r>
    </w:p>
''');

    if (address.isNotEmpty) {
      buffer.write('''
    <w:p>
      <w:pPr><w:jc w:val="center"/><w:spacing w:after="20"/></w:pPr>
      <w:r><w:rPr><w:sz w:val="18"/><w:color w:val="475569"/></w:rPr><w:t>$address</w:t></w:r>
    </w:p>
''');
    }

    final contactLine = [
      if (phone.isNotEmpty) 'Phone: $phone',
      if (email.isNotEmpty) 'Email: $email',
      if (shopGstNo.isNotEmpty) 'GSTIN: $shopGstNo',
      if (drugLicence.isNotEmpty) 'D.L. No: $drugLicence',
    ].join(' | ');

    if (contactLine.isNotEmpty) {
      buffer.write('''
    <w:p>
      <w:pPr><w:jc w:val="center"/><w:spacing w:after="120"/></w:pPr>
      <w:r><w:rPr><w:sz w:val="16"/><w:color w:val="475569"/></w:rPr><w:t>${_escapeXml(contactLine)}</w:t></w:r>
    </w:p>
''');
    }

    // Invoice Subheader (TAX INVOICE)
    buffer.write('''
    <w:p>
      <w:pPr><w:jc w:val="center"/><w:spacing w:after="160"/></w:pPr>
      <w:r><w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="166534"/></w:rPr><w:t>TAX INVOICE</w:t></w:r>
    </w:p>
''');

    // Customer & Invoice Details Table (2 columns)
    buffer.write('''
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="9600" w:type="dxa"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="4" w:space="0" w:color="166534"/>
          <w:bottom w:val="single" w:sz="4" w:space="0" w:color="166534"/>
          <w:left w:val="none"/>
          <w:right w:val="none"/>
          <w:insideH w:val="none"/>
          <w:insideV w:val="none"/>
        </w:tblBorders>
      </w:tblPr>
      <w:tr>
        <w:tc>
          <w:tcPr><w:tcW w:w="5400" w:type="dxa"/></w:tcPr>
          <w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>Billed To: ${_escapeXml(customerName)}</w:t></w:r></w:p>
          ${customerPhone != null && customerPhone.isNotEmpty ? '<w:p><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Phone: ${_escapeXml(customerPhone)}</w:t></w:r></w:p>' : ''}
          ${customerLocation != null && customerLocation.isNotEmpty ? '<w:p><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Location: ${_escapeXml(customerLocation)}</w:t></w:r></w:p>' : ''}
          ${gstNumber != null && gstNumber.isNotEmpty ? '<w:p><w:r><w:rPr><w:b/><w:sz w:val="16"/></w:rPr><w:t>GSTIN: ${_escapeXml(gstNumber)}</w:t></w:r></w:p>' : ''}
        </w:tc>
        <w:tc>
          <w:tcPr><w:tcW w:w="4200" w:type="dxa"/></w:tcPr>
          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="18"/></w:rPr><w:t>Invoice No: ${_escapeXml(invoiceNumber)}</w:t></w:r></w:p>
          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Date: $dateStr</w:t></w:r></w:p>
          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Referred By: ${_escapeXml(doctorName ?? 'Walk-in')}</w:t></w:r></w:p>
        </w:tc>
      </w:tr>
    </w:tbl>
    <w:p><w:pPr><w:spacing w:after="160"/></w:pPr></w:p>
''');

    // Main Items Table
    buffer.write('''
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="9600" w:type="dxa"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="6" w:space="0" w:color="166534"/>
          <w:left w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>
          <w:bottom w:val="single" w:sz="6" w:space="0" w:color="166534"/>
          <w:right w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>
          <w:insideH w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>
          <w:insideV w:val="single" w:sz="4" w:space="0" w:color="CBD5E1"/>
        </w:tblBorders>
      </w:tblPr>
      <w:tr>
        ${_buildTableHeaderCell('S.No', 600, 'center')}
        ${_buildTableHeaderCell('Item Name', 2800, 'left')}
        ${_buildTableHeaderCell('Batch', 1000, 'center')}
        ${_buildTableHeaderCell('Expiry', 1000, 'center')}
        ${_buildTableHeaderCell('HSN', 800, 'center')}
        ${_buildTableHeaderCell('Qty', 700, 'center')}
        ${_buildTableHeaderCell('MRP', 800, 'right')}
        ${_buildTableHeaderCell('Disc%', 600, 'right')}
        ${_buildTableHeaderCell('GST%', 600, 'right')}
        ${_buildTableHeaderCell('Total', 1100, 'right')}
      </w:tr>
''');

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

      buffer.write('''
      <w:tr>
        ${_buildTableCell('${i + 1}', 600, 'center')}
        ${_buildTableCell(name, 2800, 'left')}
        ${_buildTableCell(batch, 1000, 'center')}
        ${_buildTableCell(expiry, 1000, 'center')}
        ${_buildTableCell(hsn, 800, 'center')}
        ${_buildTableCell(qtyStr, 700, 'center')}
        ${_buildTableCell(mrp.toStringAsFixed(2), 800, 'right')}
        ${_buildTableCell(disc, 600, 'right')}
        ${_buildTableCell(gstTotal, 600, 'right')}
        ${_buildTableCell(total.toStringAsFixed(2), 1100, 'right', isBold: true)}
      </w:tr>
''');
    }
    buffer.write('    </w:tbl>\n');

    // Spacing
    buffer.write('    <w:p><w:pPr><w:spacing w:after="160"/></w:pPr></w:p>\n');

    // Totals Table (Right Aligned or 2-column)
    buffer.write('''
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="9600" w:type="dxa"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="6" w:space="0" w:color="166534"/>
          <w:bottom w:val="single" w:sz="6" w:space="0" w:color="166534"/>
          <w:left w:val="none"/>
          <w:right w:val="none"/>
          <w:insideH w:val="none"/>
          <w:insideV w:val="none"/>
        </w:tblBorders>
      </w:tblPr>
      <w:tr>
        <w:tc>
          <w:tcPr><w:tcW w:w="5600" w:type="dxa"/></w:tcPr>
          <w:p><w:r><w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="166534"/></w:rPr><w:t>Payment Details</w:t></w:r></w:p>
          <w:p><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Payment Method: ${_escapeXml(paymentMethod ?? 'CASH')}</w:t></w:r></w:p>
          <w:p><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>CGST: Rs. ${(tax / 2).toStringAsFixed(2)} | SGST: Rs. ${(tax / 2).toStringAsFixed(2)}</w:t></w:r></w:p>
          <w:p><w:r><w:rPr><w:sz w:val="16"/><w:color w:val="64748B"/></w:rPr><w:t>Thank you for your purchase!</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:tcPr><w:tcW w:w="4000" w:type="dxa"/></w:tcPr>
          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Taxable Amount: Rs. ${subtotal.toStringAsFixed(2)}</w:t></w:r></w:p>
          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Discount: Rs. ${discount.toStringAsFixed(2)}</w:t></w:r></w:p>
          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Total Tax (GST): Rs. ${tax.toStringAsFixed(2)}</w:t></w:r></w:p>
          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:t>Round Off: Rs. ${roundOff.toStringAsFixed(2)}</w:t></w:r></w:p>
          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="166534"/></w:rPr><w:t>Grand Total: Rs. ${roundedTotal.toStringAsFixed(2)}</w:t></w:r></w:p>
        </w:tc>
      </w:tr>
    </w:tbl>
''');

    // Section Properties (Page margins)
    buffer.write('''
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720" w:header="720" w:footer="720" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>
''');

    return buffer.toString();
  }

  static String _buildTableHeaderCell(String text, int widthDxa, String align) {
    return '''
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="$widthDxa" w:type="dxa"/>
            <w:shd w:val="clear" w:color="auto" w:fill="166534"/>
          </w:tcPr>
          <w:p>
            <w:pPr><w:jc w:val="$align"/></w:pPr>
            <w:r><w:rPr><w:b/><w:sz w:val="16"/><w:color w:val="FFFFFF"/></w:rPr><w:t>${_escapeXml(text)}</w:t></w:r>
          </w:p>
        </w:tc>
''';
  }

  static String _buildTableCell(String text, int widthDxa, String align, {bool isBold = false}) {
    return '''
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="$widthDxa" w:type="dxa"/>
          </w:tcPr>
          <w:p>
            <w:pPr><w:jc w:val="$align"/></w:pPr>
            <w:r>
              <w:rPr>
                ${isBold ? '<w:b/>' : ''}
                <w:sz w:val="16"/>
              </w:rPr>
              <w:t>${_escapeXml(text)}</w:t>
            </w:r>
          </w:p>
        </w:tc>
''';
  }
}
