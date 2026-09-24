import 'package:flutter/material.dart';
import '../../../../themes/app_colors.dart';

import 'package:printing/printing.dart';
import '../../../../utils/pdf_generator.dart';
import '../../../../models/counter_models.dart';

void showViewBillDialog(BuildContext context, SavedBill bill) {
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bill View - ${bill.invoiceNo}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                      doctorName: bill.doctorName,
                      format: 'A4',
                    );
                  },
                  allowSharing: true,
                  allowPrinting: true,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
