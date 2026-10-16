import 'package:flutter/material.dart';

import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:file_saver/file_saver.dart';
import '../../../../utils/pdf_generator.dart';
import '../../../../utils/docx_generator.dart';
import '../../../../utils/excel_invoice_generator.dart';
import '../../../../models/counter_models.dart';

void showViewBillDialog(BuildContext context, SavedBill bill, Map<String, dynamic> shopSettings) {
  final effectiveSettings = (bill.shopSettings != null && bill.shopSettings!.isNotEmpty)
      ? bill.shopSettings!
      : shopSettings;

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 800,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bill View - ${bill.invoiceNo}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF166534),
                            side: const BorderSide(color: Color(0xFF166534)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.description_outlined, size: 18),
                          label: const Text('Download Word (.docx)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            try {
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
                                logoBytes: PdfGenerator.getCachedLogoBytes(),
                                qrBytes: PdfGenerator.getCachedQrBytes(),
                              );
                              await FileSaver.instance.saveFile(
                                name: 'Bill_${bill.invoiceNo}',
                                bytes: docxBytes,
                                fileExtension: 'docx',
                                mimeType: MimeType.microsoftWord,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Word document downloaded successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
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
                          },
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF166534),
                            side: const BorderSide(color: Color(0xFF166534)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.table_chart_outlined, size: 18),
                          label: const Text('Download Excel (.xlsx)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          onPressed: () async {
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
                              await FileSaver.instance.saveFile(
                                name: 'Bill_${bill.invoiceNo}',
                                bytes: excelBytes,
                                fileExtension: 'xlsx',
                                mimeType: MimeType.microsoftExcel,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Excel spreadsheet downloaded successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
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
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
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
