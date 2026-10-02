import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/counter_models.dart';
import '../../../../widgets/rack_dropdown.dart';
import '../../../../widgets/category_dropdown.dart';
import '../../../../widgets/distributor_dropdown.dart';
import '../../../../services/inventory_service.dart';

class InventoryDialogs {
  static void showEditMedicineDialog(BuildContext context, WidgetRef ref, InventoryItem item, Function onSuccess) {
    final nameCtrl = TextEditingController(text: item.name);
    final skuCtrl = TextEditingController(text: item.sku);
    final mfgCtrl = TextEditingController(text: item.manufacturer);
    final batchCtrl = TextEditingController(text: item.batchNumber);
    final stockCtrl = TextEditingController(
      text: item.stockQuantity.toString(),
    );
    final packSizeCtrl = TextEditingController(
      text: item.packSize?.toString() ?? '1',
    );
    final looseStockCtrl = TextEditingController(
      text: item.looseStock.toString(),
    );
    final lowStockCtrl = TextEditingController(
      text: item.lowStockThreshold?.toString() ?? '10',
    );
    final buyingPriceCtrl = TextEditingController(
      text: item.buyingPrice.toString(),
    );
    final priceCtrl = TextEditingController(text: item.unitPrice.toString());
    final gstCtrl = TextEditingController(text: item.gst?.toString() ?? '0');
    final discountCtrl = TextEditingController(text: item.discount?.toString() ?? '0');
    final hsnCtrl = TextEditingController(text: item.hsnCode ?? '');
    final expiryCtrl = TextEditingController(text: item.expiryDate ?? '');
    String? selectedRackId = item.rackId;
    String? selectedCategoryId = item.categoryId;
    String? selectedDistributorId = item.distributorId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Medicine',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Medicine Name',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: skuCtrl,
                      decoration: const InputDecoration(
                        labelText: 'SKU / Brand',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: mfgCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Manufacturer',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: hsnCtrl,
                      decoration: const InputDecoration(labelText: 'HSN Code'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: buyingPriceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Buying Price (₹)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price (₹)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: gstCtrl,
                      decoration: const InputDecoration(labelText: 'GST (%)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: stockCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Stock (Packs)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: looseStockCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Loose Pieces',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: packSizeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pieces per Pack',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: lowStockCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Low Stock Alert At',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: batchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Batch Number',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: expiryCtrl,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          expiryCtrl.text =
                              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: discountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Discount (%)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RackDropdown(
                      selectedRackId: selectedRackId,
                      onChanged: (value) {
                        setState(() {
                          selectedRackId = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CategoryDropdown(
                      selectedCategoryId: selectedCategoryId,
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryId = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DistributorDropdown(
                      selectedDistributorId: selectedDistributorId,
                      onChanged: (value) {
                        setState(() {
                          selectedDistributorId = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await InventoryService.updateMedicine(item.id, {
                          'name': nameCtrl.text,
                          'sku': skuCtrl.text,
                          'manufacturer': mfgCtrl.text,
                          'batch_number': batchCtrl.text,
                          'stock_quantity': int.tryParse(stockCtrl.text) ?? 0,
                          'loose_stock': int.tryParse(looseStockCtrl.text) ?? 0,
                          'pack_size': int.tryParse(packSizeCtrl.text) ?? 1,
                          'low_stock_threshold':
                              int.tryParse(lowStockCtrl.text) ?? 10,
                          'buying_price':
                              double.tryParse(buyingPriceCtrl.text) ?? 0.0,
                          'unit_price': double.tryParse(priceCtrl.text) ?? 0.0,
                          'gst': double.tryParse(gstCtrl.text) ?? 0.0,
                          'discount': double.tryParse(discountCtrl.text) ?? 0.0,
                          'rack_id': selectedRackId,
                          'category_id': selectedCategoryId,
                          'distributor_id': selectedDistributorId,
                          'hsn_code': hsnCtrl.text,
                          'expiry_date': expiryCtrl.text,
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Medicine updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          onSuccess();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0369A1),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
