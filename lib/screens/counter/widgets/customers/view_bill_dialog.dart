import 'package:flutter/material.dart';

import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:file_saver/file_saver.dart';
import '../../../../utils/pdf_generator.dart';
import '../../../../utils/docx_generator.dart';
import '../../../../utils/excel_invoice_generator.dart';
import '../../../../utils/file_download_helper.dart';
import '../../../../models/counter_models.dart';

void showViewBillDialog(BuildContext context, SavedBill bill, Map<String, dynamic> shopSettings) {
  final effectiveSettings = (bill.shopSettings != null && bill.shopSettings!.isNotEmpty)
      ? bill.shopSettings!
      : shopSettings;

  Future<void> handleDownloadWord() async {
    try {
      final logoBytes = await PdfGenerator.resolveLogoBytes(effectiveSettings);
      final qrBytes = await PdfGenerator.resolveQrBytes(effectiveSettings);

      final docxBytes = DocxGenerator.generateInvoiceDocx(
        items: bill.items,
        subtotal: bill.subtotal,
        discount: bill.discount,
        tax: bill.tax,
        grandTotal: bill.grandTotal,
        invoiceNumber: bill.invoiceNo,
        customerName: bill.customerName,
        customerPhone: bill.customerPhone,
        customerLocation: bill.customerLocation,
        gstNumber: bill.customerGstin,
        doctorName: bill.doctorName,
        paymentMethod: bill.paymentMode,
        shopSettings: effectiveSettings,
        billingDate: bill.createdAt,
        logoBytes: logoBytes,
        qrBytes: qrBytes,
      );
      final result = await FileDownloadHelper.saveFile(
        name: 'Bill_${bill.invoiceNo}',
        bytes: docxBytes,
        fileExtension: 'docx',
        mimeType: MimeType.microsoftWord,
        dialogTitle: 'Save Word Invoice',
      );
      if (context.mounted) {
        if (result.success) {
          final locationMsg = result.savedPath != null
              ? ' Saved to: ${result.savedPath}'
              : '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Word document downloaded successfully!$locationMsg'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save Word document: ${result.errorMessage ?? "Unknown error"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download Word document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> handleDownloadExcel() async {
    try {
      final excelBytes = ExcelInvoiceGenerator.generateInvoiceExcel(
        items: bill.items,
        subtotal: bill.subtotal,
        discount: bill.discount,
        tax: bill.tax,
        grandTotal: bill.grandTotal,
        invoiceNumber: bill.invoiceNo,
        customerName: bill.customerName,
        customerPhone: bill.customerPhone,
        customerLocation: bill.customerLocation,
        gstNumber: bill.customerGstin,
        doctorName: bill.doctorName,
        paymentMethod: bill.paymentMode,
        shopSettings: effectiveSettings,
        billingDate: bill.createdAt,
      );
      final result = await FileDownloadHelper.saveFile(
        name: 'Bill_${bill.invoiceNo}',
        bytes: excelBytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
        dialogTitle: 'Save Excel Invoice',
      );
      if (context.mounted) {
        if (result.success) {
          final locationMsg = result.savedPath != null
              ? ' Saved to: ${result.savedPath}'
              : '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Excel spreadsheet downloaded successfully!$locationMsg'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save Excel spreadsheet: ${result.errorMessage ?? "Unknown error"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download Excel spreadsheet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  showDialog(
    context: context,
    builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final isDesktop = screenWidth > 750;

      return Dialog(
        insetPadding: EdgeInsets.all(isDesktop ? 20 : 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: isDesktop ? 800 : screenWidth * 0.95,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 20 : 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bill View - ${bill.invoiceNo}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isDesktop ? 16 : 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isDesktop) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF166534),
                          side: const BorderSide(color: Color(0xFF166534)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: const Text('Download Word (.docx)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: handleDownloadWord,
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF166534),
                          side: const BorderSide(color: Color(0xFF166534)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.table_chart_outlined, size: 18),
                        label: const Text('Download Excel (.xlsx)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: handleDownloadExcel,
                      ),
                    ] else ...[
                      IconButton(
                        tooltip: 'Download Word',
                        icon: const Icon(Icons.description_outlined, color: Color(0xFF166534)),
                        onPressed: handleDownloadWord,
                      ),
                      IconButton(
                        tooltip: 'Download Excel',
                        icon: const Icon(Icons.table_chart_outlined, color: Color(0xFF166534)),
                        onPressed: handleDownloadExcel,
                      ),
                    ],
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PdfPreview(
                  build: (format) async {
                    return await PdfGenerator.generateBill(
                      items: bill.items,
                      subtotal: bill.subtotal,
                      discount: bill.discount,
                      tax: bill.tax,
                      grandTotal: bill.grandTotal,
                      invoiceNumber: bill.invoiceNo,
                      customerName: bill.customerName,
                      customerPhone: bill.customerPhone,
                      customerLocation: bill.customerLocation,
                      gstNumber: bill.customerGstin,
                      doctorName: bill.doctorName,
                      paymentMethod: bill.paymentMode,
                      shopSettings: effectiveSettings,
                      format: bill.format,
                      billingDate: bill.createdAt,
                    );
                  },
                  allowSharing: false,
                  allowPrinting: true,
                  canDebug: false,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  initialPageFormat: bill.format == 'Thermal'
                      ? const PdfPageFormat(
                          80 * PdfPageFormat.mm,
                          300 * PdfPageFormat.mm,
                        )
                      : bill.format == 'A5'
                      ? PdfPageFormat.a5.landscape
                      : PdfPageFormat.a4,
                  pageFormats: {
                    'A5 Landscape': PdfPageFormat.a5.landscape,
                    'A4': PdfPageFormat.a4,
                    'Thermal': const PdfPageFormat(80 * PdfPageFormat.mm, 300 * PdfPageFormat.mm),
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
