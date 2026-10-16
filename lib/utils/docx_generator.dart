import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:manju_medical/utils/format_utils.dart';

/// Generates valid, clean Microsoft Word (.docx) documents replicating the exact
/// A5 Landscape Bill layout (Headers, Customer Box, Product Table, Bank Details,
/// GST Breakdown, Totals Box, Terms & Conditions, and Signatory).
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
        '        <w:sz w:val="16"/>\r\n'
        '        <w:szCs w:val="16"/>\r\n'
        '      </w:rPr>\r\n'
        '    </w:rPrDefault>\r\n'
        '    <w:pPrDefault>\r\n'
        '      <w:pPr>\r\n'
        '        <w:spacing w:after="0" w:line="220" w:lineRule="auto"/>\r\n'
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
    final String tagline = _escapeXml(shopSettings?['tagline'] ?? '');
    final String address = _escapeXml(shopSettings?['address'] ?? '');
    final String phone = _escapeXml(shopSettings?['phone'] ?? '');
    final String email = _escapeXml(shopSettings?['email'] ?? '');
    final String shopGstNo = _escapeXml(shopSettings?['gst_number'] ?? '');
    final String drugLicence = _escapeXml(shopSettings?['drug_licence'] ?? '');

    final String bankName = _escapeXml(shopSettings?['bank_name'] ?? 'NA');
    final String branchName = _escapeXml(shopSettings?['branch_name'] ?? 'NA');
    final String acHolder = _escapeXml(shopSettings?['ac_holder_name'] ?? 'NA');
    final String acNumber = _escapeXml(shopSettings?['ac_number'] ?? 'NA');
    final String ifsc = _escapeXml(shopSettings?['ifsc_code'] ?? 'NA');

    final String term1 = _escapeXml(shopSettings?['terms_1'] ?? '1. Medicines once sold will not be taken back.');
    final String term2 = _escapeXml(shopSettings?['terms_2'] ?? '2. Store in cool and dry place.');
    final String term3 = _escapeXml(shopSettings?['terms_3'] ?? '');

    final String dateStr = billingDate != null
        ? DateFormat('dd-MM-yyyy HH:mm').format(billingDate)
        : DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());

    double roundedTotal = grandTotal.roundToDouble();
    double roundOff = roundedTotal - grandTotal;

    // A5 Landscape printable width in DXA:
    // Page: 11906 (height in portrait, width in landscape) = 16838 width in DXA
    // Left/Right margin: 500 dxa each (~9mm) -> Usable width = 15838 dxa. Let's use 15800 dxa.
    const int totalWidth = 15800;

    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\r\n');
    buffer.write('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">\r\n');
    buffer.write('  <w:body>\r\n');

    // ==========================================
    // 1. TOP HEADER (Shop on Left, TAX INVOICE on Right)
    // ==========================================
    buffer.write('    <w:tbl>\r\n');
    buffer.write('      <w:tblPr>\r\n');
    buffer.write('        <w:tblW w:w="$totalWidth" w:type="dxa"/>\r\n');
    buffer.write('        <w:tblLayout w:type="fixed"/>\r\n');
    buffer.write('        <w:tblBorders>\r\n');
    buffer.write('          <w:top w:val="none"/>\r\n');
    buffer.write('          <w:bottom w:val="none"/>\r\n');
    buffer.write('          <w:left w:val="none"/>\r\n');
    buffer.write('          <w:right w:val="none"/>\r\n');
    buffer.write('          <w:insideH w:val="none"/>\r\n');
    buffer.write('          <w:insideV w:val="none"/>\r\n');
    buffer.write('        </w:tblBorders>\r\n');
    buffer.write('      </w:tblPr>\r\n');
    buffer.write('      <w:tblGrid>\r\n');
    buffer.write('        <w:gridCol w:w="11000"/>\r\n');
    buffer.write('        <w:gridCol w:w="4800"/>\r\n');
    buffer.write('      </w:tblGrid>\r\n');
    buffer.write('      <w:tr>\r\n');
    // Left column: Shop info
    buffer.write('        <w:tc>\r\n');
    buffer.write('          <w:tcPr><w:tcW w:w="11000" w:type="dxa"/></w:tcPr>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="166534"/></w:rPr><w:t>$shopName</w:t></w:r></w:p>\r\n');
    if (tagline.isNotEmpty) {
      buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="14"/><w:color w:val="64748B"/></w:rPr><w:t>$tagline</w:t></w:r></w:p>\r\n');
    }
    if (address.isNotEmpty) {
      buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="15"/></w:rPr><w:t>$address</w:t></w:r></w:p>\r\n');
    }
    final contactParts = [
      if (phone.isNotEmpty) 'Phone: $phone',
      if (email.isNotEmpty) 'Email: $email',
    ].join(' | ');
    if (contactParts.isNotEmpty) {
      buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="15"/></w:rPr><w:t>$contactParts</w:t></w:r></w:p>\r\n');
    }
    final regParts = [
      if (shopGstNo.isNotEmpty) 'GSTIN: $shopGstNo',
      if (drugLicence.isNotEmpty) 'D.L. No.: $drugLicence',
    ].join(' | ');
    if (regParts.isNotEmpty) {
      buffer.write('          <w:p><w:r><w:rPr><w:b/><w:sz w:val="15"/></w:rPr><w:t>$regParts</w:t></w:r></w:p>\r\n');
    }
    buffer.write('        </w:tc>\r\n');
    // Right column: Tax Invoice info
    buffer.write('        <w:tc>\r\n');
    buffer.write('          <w:tcPr><w:tcW w:w="4800" w:type="dxa"/></w:tcPr>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="20"/><w:color w:val="166534"/></w:rPr><w:t>TAX INVOICE</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="16"/></w:rPr><w:t>Invoice No: ${_escapeXml(invoiceNumber)}</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="15"/></w:rPr><w:t>Date: $dateStr</w:t></w:r></w:p>\r\n');
    buffer.write('        </w:tc>\r\n');
    buffer.write('      </w:tr>\r\n');
    buffer.write('    </w:tbl>\r\n');

    // Divider line
    buffer.write('    <w:p><w:pPr><w:pBdr><w:bottom w:val="single" w:sz="6" w:space="1" w:color="166534"/></w:pBdr><w:spacing w:after="40"/></w:pPr></w:p>\r\n');

    // ==========================================
    // 2. BILLED TO & REFERRED BY
    // ==========================================
    buffer.write('    <w:tbl>\r\n');
    buffer.write('      <w:tblPr>\r\n');
    buffer.write('        <w:tblW w:w="$totalWidth" w:type="dxa"/>\r\n');
    buffer.write('        <w:tblLayout w:type="fixed"/>\r\n');
    buffer.write('        <w:tblBorders>\r\n');
    buffer.write('          <w:top w:val="none"/><w:bottom w:val="none"/><w:left w:val="none"/><w:right w:val="none"/><w:insideH w:val="none"/><w:insideV w:val="none"/>\r\n');
    buffer.write('        </w:tblBorders>\r\n');
    buffer.write('      </w:tblPr>\r\n');
    buffer.write('      <w:tblGrid>\r\n');
    buffer.write('        <w:gridCol w:w="11000"/>\r\n');
    buffer.write('        <w:gridCol w:w="4800"/>\r\n');
    buffer.write('      </w:tblGrid>\r\n');
    buffer.write('      <w:tr>\r\n');
    buffer.write('        <w:tc>\r\n');
    buffer.write('          <w:tcPr><w:tcW w:w="11000" w:type="dxa"/></w:tcPr>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="13"/><w:color w:val="64748B"/></w:rPr><w:t>Billed To:</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:b/><w:sz w:val="17"/></w:rPr><w:t>${_escapeXml(customerName)}</w:t></w:r></w:p>\r\n');
    if (customerPhone != null && customerPhone.isNotEmpty) {
      buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="14"/></w:rPr><w:t>Phone: ${_escapeXml(customerPhone)}</w:t></w:r></w:p>\r\n');
    }
    if (customerLocation != null && customerLocation.isNotEmpty) {
      buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="14"/></w:rPr><w:t>Location: ${_escapeXml(customerLocation)}</w:t></w:r></w:p>\r\n');
    }
    if (gstNumber != null && gstNumber.isNotEmpty) {
      buffer.write('          <w:p><w:r><w:rPr><w:b/><w:sz w:val="14"/></w:rPr><w:t>GSTIN: ${_escapeXml(gstNumber)}</w:t></w:r></w:p>\r\n');
    }
    buffer.write('        </w:tc>\r\n');
    buffer.write('        <w:tc>\r\n');
    buffer.write('          <w:tcPr><w:tcW w:w="4800" w:type="dxa"/></w:tcPr>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="13"/><w:color w:val="64748B"/></w:rPr><w:t>Referred By:</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="17"/></w:rPr><w:t>${_escapeXml(doctorName ?? 'Walk-in')}</w:t></w:r></w:p>\r\n');
    buffer.write('        </w:tc>\r\n');
    buffer.write('      </w:tr>\r\n');
    buffer.write('    </w:tbl>\r\n');

    buffer.write('    <w:p><w:pPr><w:spacing w:after="80"/></w:pPr></w:p>\r\n');

    // ==========================================
    // 3. MAIN PRODUCT TABLE (11 columns matching A5 Landscape PDF)
    // S.No(700) Item Name(4600) Batch(1600) Expiry(1500) HSN(1100) Qty(1000) MRP(1100) Disc%(1000) CGST%(1000) SGST%(1000) Total(1200) = 15800 dxa
    // ==========================================
    const colWidths = [700, 4600, 1600, 1500, 1100, 1000, 1100, 1000, 1000, 1000, 1200];

    buffer.write('    <w:tbl>\r\n');
    buffer.write('      <w:tblPr>\r\n');
    buffer.write('        <w:tblW w:w="$totalWidth" w:type="dxa"/>\r\n');
    buffer.write('        <w:tblLayout w:type="fixed"/>\r\n');
    buffer.write('        <w:tblBorders>\r\n');
    buffer.write('          <w:top w:val="single" w:sz="4" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:left w:val="single" w:sz="4" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:bottom w:val="single" w:sz="4" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:right w:val="single" w:sz="4" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:insideH w:val="single" w:sz="4" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:insideV w:val="single" w:sz="4" w:space="0" w:color="166534"/>\r\n');
    buffer.write('        </w:tblBorders>\r\n');
    buffer.write('      </w:tblPr>\r\n');
    buffer.write('      <w:tblGrid>\r\n');
    for (final w in colWidths) {
      buffer.write('        <w:gridCol w:w="$w"/>\r\n');
    }
    buffer.write('      </w:tblGrid>\r\n');

    // Header row (Green background with White text)
    buffer.write('      <w:tr>\r\n');
    buffer.write(_buildTableHeaderCell('S.No', colWidths[0], 'center'));
    buffer.write(_buildTableHeaderCell('Item Name', colWidths[1], 'center'));
    buffer.write(_buildTableHeaderCell('Batch', colWidths[2], 'center'));
    buffer.write(_buildTableHeaderCell('Expiry', colWidths[3], 'center'));
    buffer.write(_buildTableHeaderCell('HSN', colWidths[4], 'center'));
    buffer.write(_buildTableHeaderCell('Qty', colWidths[5], 'center'));
    buffer.write(_buildTableHeaderCell('MRP', colWidths[6], 'center'));
    buffer.write(_buildTableHeaderCell('Disc%', colWidths[7], 'center'));
    buffer.write(_buildTableHeaderCell('CGST%', colWidths[8], 'center'));
    buffer.write(_buildTableHeaderCell('SGST%', colWidths[9], 'center'));
    buffer.write(_buildTableHeaderCell('Total', colWidths[10], 'center'));
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
      final String cgst = '${item['cgst']?.toString() ?? '0'}%';
      final String sgst = '${item['sgst']?.toString() ?? '0'}%';
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
      buffer.write(_buildTableCell(cgst, colWidths[8], 'right'));
      buffer.write(_buildTableCell(sgst, colWidths[9], 'right'));
      buffer.write(_buildTableCell(total.toStringAsFixed(2), colWidths[10], 'right'));
      buffer.write('      </w:tr>\r\n');
    }
    buffer.write('    </w:tbl>\r\n');

    buffer.write('    <w:p><w:pPr><w:spacing w:after="80"/></w:pPr></w:p>\r\n');

    // ==========================================
    // 4. TOTALS & SUMMARY BOX (4 Columns matching PDF: Bank Details, QR Box, GST Summary, Totals)
    // 4400 + 2000 + 4400 + 5000 = 15800 dxa
    // ==========================================
    buffer.write('    <w:tbl>\r\n');
    buffer.write('      <w:tblPr>\r\n');
    buffer.write('        <w:tblW w:w="$totalWidth" w:type="dxa"/>\r\n');
    buffer.write('        <w:tblLayout w:type="fixed"/>\r\n');
    buffer.write('        <w:tblBorders>\r\n');
    buffer.write('          <w:top w:val="single" w:sz="6" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:left w:val="single" w:sz="6" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:bottom w:val="single" w:sz="6" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:right w:val="single" w:sz="6" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:insideH w:val="single" w:sz="4" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:insideV w:val="single" w:sz="4" w:space="0" w:color="166534"/>\r\n');
    buffer.write('        </w:tblBorders>\r\n');
    buffer.write('      </w:tblPr>\r\n');
    buffer.write('      <w:tblGrid>\r\n');
    buffer.write('        <w:gridCol w:w="4400"/>\r\n');
    buffer.write('        <w:gridCol w:w="2000"/>\r\n');
    buffer.write('        <w:gridCol w:w="4400"/>\r\n');
    buffer.write('        <w:gridCol w:w="5000"/>\r\n');
    buffer.write('      </w:tblGrid>\r\n');
    buffer.write('      <w:tr>\r\n');

    // Col 1: Bank Details
    buffer.write('        <w:tc>\r\n');
    buffer.write('          <w:tcPr><w:tcW w:w="4400" w:type="dxa"/><w:tcMar><w:top w:w="60" w:type="dxa"/><w:left w:w="80" w:type="dxa"/><w:bottom w:w="60" w:type="dxa"/><w:right w:w="80" w:type="dxa"/></w:tcMar></w:tcPr>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:b/><w:sz w:val="16"/><w:color w:val="166534"/></w:rPr><w:t>Bank Details</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="14"/></w:rPr><w:t>Bank: $bankName</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="14"/></w:rPr><w:t>Branch: $branchName</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="14"/></w:rPr><w:t>A/C Name: $acHolder</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="14"/></w:rPr><w:t>A/C No: $acNumber</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="14"/></w:rPr><w:t>IFSC: $ifsc</w:t></w:r></w:p>\r\n');
    buffer.write('        </w:tc>\r\n');

    // Col 2: UPI / QR Code placeholder
    buffer.write('        <w:tc>\r\n');
    buffer.write('          <w:tcPr><w:tcW w:w="2000" w:type="dxa"/><w:vAlign w:val="center"/><w:tcMar><w:top w:w="60" w:type="dxa"/><w:left w:w="60" w:type="dxa"/><w:bottom w:w="60" w:type="dxa"/><w:right w:w="60" w:type="dxa"/></w:tcMar></w:tcPr>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="14"/><w:color w:val="166534"/></w:rPr><w:t>SCAN &amp; PAY</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:sz w:val="13"/><w:color w:val="64748B"/></w:rPr><w:t>UPI Payment</w:t></w:r></w:p>\r\n');
    buffer.write('        </w:tc>\r\n');

    // Col 3: GST Summary
    buffer.write('        <w:tc>\r\n');
    buffer.write('          <w:tcPr><w:tcW w:w="4400" w:type="dxa"/><w:tcMar><w:top w:w="60" w:type="dxa"/><w:left w:w="80" w:type="dxa"/><w:bottom w:w="60" w:type="dxa"/><w:right w:w="80" w:type="dxa"/></w:tcMar></w:tcPr>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:b/><w:sz w:val="16"/><w:color w:val="166534"/></w:rPr><w:t>GST Summary</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="14"/></w:rPr><w:t>CGST: Rs. ${(tax / 2).toStringAsFixed(2)}</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="14"/></w:rPr><w:t>SGST: Rs. ${(tax / 2).toStringAsFixed(2)}</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:spacing w:before="60"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="14"/></w:rPr><w:t>GST Total: Rs. ${tax.toStringAsFixed(2)}</w:t></w:r></w:p>\r\n');
    buffer.write('        </w:tc>\r\n');

    // Col 4: Totals & Grand Total
    buffer.write('        <w:tc>\r\n');
    buffer.write('          <w:tcPr><w:tcW w:w="5000" w:type="dxa"/><w:tcMar><w:top w:w="60" w:type="dxa"/><w:left w:w="80" w:type="dxa"/><w:bottom w:w="60" w:type="dxa"/><w:right w:w="80" w:type="dxa"/></w:tcMar></w:tcPr>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="14"/></w:rPr><w:t>Taxable: Rs. ${subtotal.toStringAsFixed(2)}</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="14"/></w:rPr><w:t>Discount: Rs. ${discount.toStringAsFixed(2)}</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="14"/></w:rPr><w:t>Tax (GST): Rs. ${tax.toStringAsFixed(2)}</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="14"/></w:rPr><w:t>Payment Mode: ${_escapeXml(paymentMethod ?? 'CASH')}</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="14"/></w:rPr><w:t>Grand Total: Rs. ${grandTotal.toStringAsFixed(2)}</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:sz w:val="14"/></w:rPr><w:t>Round Off: Rs. ${roundOff.toStringAsFixed(2)}</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/><w:pBdr><w:top w:val="single" w:sz="6" w:space="1" w:color="166534"/></w:pBdr></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="17"/><w:color w:val="166534"/></w:rPr><w:t>Rounded Total: Rs. ${roundedTotal.toStringAsFixed(2)}</w:t></w:r></w:p>\r\n');
    buffer.write('        </w:tc>\r\n');

    buffer.write('      </w:tr>\r\n');
    buffer.write('    </w:tbl>\r\n');

    buffer.write('    <w:p><w:pPr><w:spacing w:after="80"/></w:pPr></w:p>\r\n');

    // ==========================================
    // 5. TERMS & CONDITIONS AND AUTHORIZED SIGNATORY (Matching A5 PDF bottom box)
    // 11000 + 4800 = 15800 dxa
    // ==========================================
    buffer.write('    <w:tbl>\r\n');
    buffer.write('      <w:tblPr>\r\n');
    buffer.write('        <w:tblW w:w="$totalWidth" w:type="dxa"/>\r\n');
    buffer.write('        <w:tblLayout w:type="fixed"/>\r\n');
    buffer.write('        <w:tblBorders>\r\n');
    buffer.write('          <w:top w:val="single" w:sz="6" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:left w:val="single" w:sz="6" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:bottom w:val="single" w:sz="6" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:right w:val="single" w:sz="6" w:space="0" w:color="166534"/>\r\n');
    buffer.write('          <w:insideH w:val="none"/>\r\n');
    buffer.write('          <w:insideV w:val="single" w:sz="4" w:space="0" w:color="166534"/>\r\n');
    buffer.write('        </w:tblBorders>\r\n');
    buffer.write('      </w:tblPr>\r\n');
    buffer.write('      <w:tblGrid>\r\n');
    buffer.write('        <w:gridCol w:w="11000"/>\r\n');
    buffer.write('        <w:gridCol w:w="4800"/>\r\n');
    buffer.write('      </w:tblGrid>\r\n');
    buffer.write('      <w:tr>\r\n');
    // Left: Terms
    buffer.write('        <w:tc>\r\n');
    buffer.write('          <w:tcPr><w:tcW w:w="11000" w:type="dxa"/><w:tcMar><w:top w:w="60" w:type="dxa"/><w:left w:w="80" w:type="dxa"/><w:bottom w:w="60" w:type="dxa"/><w:right w:w="80" w:type="dxa"/></w:tcMar></w:tcPr>\r\n');
    buffer.write('          <w:p><w:r><w:rPr><w:b/><w:sz w:val="15"/><w:color w:val="166534"/></w:rPr><w:t>Terms &amp; Conditions</w:t></w:r></w:p>\r\n');
    if (term1.isNotEmpty) {
      buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="13"/></w:rPr><w:t>$term1</w:t></w:r></w:p>\r\n');
    }
    if (term2.isNotEmpty) {
      buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="13"/></w:rPr><w:t>$term2</w:t></w:r></w:p>\r\n');
    }
    if (term3.isNotEmpty) {
      buffer.write('          <w:p><w:r><w:rPr><w:sz w:val="13"/></w:rPr><w:t>$term3</w:t></w:r></w:p>\r\n');
    }
    buffer.write('        </w:tc>\r\n');
    // Right: Signatory
    buffer.write('        <w:tc>\r\n');
    buffer.write('          <w:tcPr><w:tcW w:w="4800" w:type="dxa"/><w:vAlign w:val="bottom"/><w:tcMar><w:top w:w="60" w:type="dxa"/><w:left w:w="80" w:type="dxa"/><w:bottom w:w="60" w:type="dxa"/><w:right w:w="80" w:type="dxa"/></w:tcMar></w:tcPr>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="14"/><w:color w:val="166534"/></w:rPr><w:t>For $shopName</w:t></w:r></w:p>\r\n');
    buffer.write('          <w:p><w:pPr><w:jc w:val="right"/><w:spacing w:before="240"/></w:pPr><w:r><w:rPr><w:sz w:val="14"/></w:rPr><w:t>Authorized Signatory</w:t></w:r></w:p>\r\n');
    buffer.write('        </w:tc>\r\n');
    buffer.write('      </w:tr>\r\n');
    buffer.write('    </w:tbl>\r\n');

    // ==========================================
    // 6. SECTION PROPERTIES: A5 Landscape (16838 x 11906 DXA)
    // ==========================================
    buffer.write('    <w:sectPr>\r\n');
    buffer.write('      <w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/>\r\n');
    buffer.write('      <w:pgMar w:top="500" w:right="519" w:bottom="500" w:left="519" w:header="360" w:footer="360" w:gutter="0"/>\r\n');
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
        '            <w:tcMar><w:top w:w="60" w:type="dxa"/><w:bottom w:w="60" w:type="dxa"/><w:left w:w="40" w:type="dxa"/><w:right w:w="40" w:type="dxa"/></w:tcMar>\r\n'
        '          </w:tcPr>\r\n'
        '          <w:p>\r\n'
        '            <w:pPr><w:jc w:val="$align"/></w:pPr>\r\n'
        '            <w:r><w:rPr><w:b/><w:sz w:val="14"/><w:color w:val="FFFFFF"/></w:rPr><w:t>${_escapeXml(text)}</w:t></w:r>\r\n'
        '          </w:p>\r\n'
        '        </w:tc>\r\n';
  }

  static String _buildTableCell(String text, int widthDxa, String align) {
    return '        <w:tc>\r\n'
        '          <w:tcPr>\r\n'
        '            <w:tcW w:w="$widthDxa" w:type="dxa"/>\r\n'
        '            <w:tcMar><w:top w:w="40" w:type="dxa"/><w:bottom w:w="40" w:type="dxa"/><w:left w:w="40" w:type="dxa"/><w:right w:w="40" w:type="dxa"/></w:tcMar>\r\n'
        '          </w:tcPr>\r\n'
        '          <w:p>\r\n'
        '            <w:pPr><w:jc w:val="$align"/></w:pPr>\r\n'
        '            <w:r>\r\n'
        '              <w:rPr>\r\n'
        '                <w:sz w:val="14"/>\r\n'
        '              </w:rPr>\r\n'
        '              <w:t>${_escapeXml(text)}</w:t>\r\n'
        '            </w:r>\r\n'
        '          </w:p>\r\n'
        '        </w:tc>\r\n';
  }
}
