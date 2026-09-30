import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/counter_providers.dart';
import '../../services/purchase_service.dart';
import '../../services/inventory_service.dart';
import '../../providers/distributor_provider.dart';

class AddPurchaseBillScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> distributor;
  const AddPurchaseBillScreen({super.key, required this.distributor});

  @override
  ConsumerState<AddPurchaseBillScreen> createState() => _AddPurchaseBillScreenState();
}

class _AddPurchaseBillScreenState extends ConsumerState<AddPurchaseBillScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  final List<Map<String, dynamic>> _items = [];
  final _searchCtrl = TextEditingController();
  String _paymentStatus = 'UNPAID';
  bool _isLoading = false;
  bool _filterByDistributor = false;

  void _addItem(Map<String, dynamic> product) {
    setState(() {
      final existingIndex = _items.indexWhere((i) => i['inventory_item_id'] == product['id']);
      if (existingIndex >= 0) {
        _items[existingIndex]['quantity'] += 1;
      } else {
        _items.add({
          'inventory_item_id': product['id'],
          'name': product['name'],
          'quantity': 1,
          'buying_price': product['buying_price'] ?? 0.0,
          'selling_price': product['unit_price'] ?? 0.0,
          'batch_number': product['batch_number'] ?? '',
          'expiry_date': product['expiry_date'] ?? '',
          'hsn_code': product['hsn_code'] ?? '',
          'gst': product['gst'] ?? 0.0,
          'rack_id': product['rack_id'],
          'category_id': product['category_id'],
        });
      }
    });
  }

  void _submit() async {
    if (_items.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final shopId = await InventoryService.getShopId();
      
      // Calculate total amount
      double totalAmount = 0;
      for (var item in _items) {
        totalAmount += (item['buying_price'] as double) * (item['quantity'] as int);
      }

      final billData = {
        'shop_id': shopId,
        'distributor_id': widget.distributor['id'],
        'payment_status': _paymentStatus,
        'bill_date': DateTime.now().toIso8601String().split('T')[0],
        'total_amount': totalAmount,
        'items': _items.map((i) => {
          'inventory_item_id': i['inventory_item_id'],
          'quantity': i['quantity'],
          'unit_price': i['buying_price'],
          'selling_price': i['selling_price'],
          'batch_number': i['batch_number'],
          'expiry_date': i['expiry_date'] != '' ? i['expiry_date'] : null,
          'hsn_code': i['hsn_code'] != '' ? i['hsn_code'] : null,
          'gst': i['gst'],
          'rack_id': i['rack_id'],
          'category_id': i['category_id'],
        }).toList(),
      };

      await _purchaseService.createPurchaseBill(billData);
      
      ref.invalidate(inventoryProvider); // Refresh stock
      ref.invalidate(purchaseBillsProvider); // Refresh dashboard KPIs
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase Bill created & stock updated!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddMedicineDialog() {
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final mfgCtrl = TextEditingController();
    final bpCtrl = TextEditingController();
    final spCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');
    final packSizeCtrl = TextEditingController(text: '1');
    final gstCtrl = TextEditingController(text: '0');
    final discountCtrl = TextEditingController(text: '0');
    final batchCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final hsnCtrl = TextEditingController();
    
    String? selectedRackId;
    String? selectedCategoryId;
    bool isSaving = false;
    
    final rList = ref.read(rackProvider).value ?? [];
    final cList = ref.read(categoryProvider).value ?? [];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Medicine to Inventory'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 600,
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(width: 280, child: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Medicine Name *', border: OutlineInputBorder()))),
                  SizedBox(width: 280, child: TextField(controller: mfgCtrl, decoration: const InputDecoration(labelText: 'Manufacturer', border: OutlineInputBorder()))),
                  SizedBox(width: 280, child: TextField(controller: bpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Buying Price (₹) *', border: OutlineInputBorder()))),
                  SizedBox(width: 280, child: TextField(controller: spCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Selling Price (MRP ₹) *', border: OutlineInputBorder()))),
                  SizedBox(width: 180, child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Initial Stock (Packs) *', border: OutlineInputBorder()))),
                  SizedBox(width: 180, child: TextField(controller: packSizeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pieces per Pack', border: OutlineInputBorder()))),
                  SizedBox(width: 180, child: TextField(controller: gstCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'GST (%)', border: OutlineInputBorder()))),
                  SizedBox(width: 180, child: TextField(controller: discountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Discount (%)', border: OutlineInputBorder()))),
                  SizedBox(width: 180, child: TextField(controller: batchCtrl, decoration: const InputDecoration(labelText: 'Batch Number', border: OutlineInputBorder()))),
                  SizedBox(width: 180, child: TextField(controller: expiryCtrl, decoration: const InputDecoration(labelText: 'Expiry Date (yyyy-mm-dd)', border: OutlineInputBorder()))),
                  SizedBox(width: 280, child: TextField(controller: hsnCtrl, decoration: const InputDecoration(labelText: 'HSN Code', border: OutlineInputBorder()))),
                  SizedBox(width: 280, child: TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'Barcode / SKU', border: OutlineInputBorder()))),
                  
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      value: selectedCategoryId,
                      items: cList.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (v) => setDialogState(() => selectedCategoryId = v),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Rack / Location', border: OutlineInputBorder()),
                      value: selectedRackId,
                      items: rList.map((r) => DropdownMenuItem(value: r.id, child: Text(r.rackNumber))).toList(),
                      onChanged: (v) => setDialogState(() => selectedRackId = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (nameCtrl.text.isEmpty || bpCtrl.text.isEmpty || spCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields *'), backgroundColor: Colors.red));
                  return;
                }
                setDialogState(() => isSaving = true);
                try {
                  final newItem = await InventoryService.addMedicine({
                    'name': nameCtrl.text,
                    'sku': skuCtrl.text.isNotEmpty ? skuCtrl.text : DateTime.now().millisecondsSinceEpoch.toString(),
                    'manufacturer': mfgCtrl.text,
                    'buying_price': double.tryParse(bpCtrl.text) ?? 0.0,
                    'unit_price': double.tryParse(spCtrl.text) ?? 0.0,
                    'stock_quantity': 0, // Set to 0 so purchase bill submission sets the correct total
                    'pack_size': int.tryParse(packSizeCtrl.text) ?? 1,
                    'gst': double.tryParse(gstCtrl.text) ?? 0.0,
                    'discount': double.tryParse(discountCtrl.text) ?? 0.0,
                    'batch_number': batchCtrl.text.isNotEmpty ? batchCtrl.text : 'BATCH-01',
                    'expiry_date': expiryCtrl.text.isNotEmpty ? expiryCtrl.text : '2030-12-31',
                    'hsn_code': hsnCtrl.text.isNotEmpty ? hsnCtrl.text : '3004',
                    'distributor_id': widget.distributor['id'],
                    'rack_id': selectedRackId,
                    'category_id': selectedCategoryId,
                  });
                  if (context.mounted) {
                    // Automatically add the created medicine to the purchase bill cart
                    final requestedQty = int.tryParse(stockCtrl.text) ?? 1;
                    setState(() {
                      _items.add({
                        'inventory_item_id': newItem['id'],
                        'name': newItem['name'],
                        'quantity': requestedQty > 0 ? requestedQty : 1,
                        'buying_price': (newItem['buying_price'] as num?)?.toDouble() ?? 0.0,
                        'selling_price': (newItem['unit_price'] as num?)?.toDouble() ?? 0.0,
                        'batch_number': newItem['batch_number'] ?? '',
                        'expiry_date': newItem['expiry_date'] ?? '',
                        'hsn_code': newItem['hsn_code'] ?? '',
                        'gst': (newItem['gst'] as num?)?.toDouble() ?? 0.0,
                        'rack_id': newItem['rack_id'],
                        'category_id': newItem['category_id'],
                      });
                    });
                    
                    ref.invalidate(inventoryProvider); // Refresh inventory search list
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine created & added to bill!'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                } finally {
                  if (context.mounted) setDialogState(() => isSaving = false);
                }
              },
              child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Medicine'),
            ),
          ],
        )
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryProvider);
    final racks = ref.watch(rackProvider);
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Purchase from ${widget.distributor['name']}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534)),
              child: _isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text('Confirm Purchase', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
      body: Row(
        children: [
          // Left: Product Search
          Expanded(
            flex: 1,
            child: Material(
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search Medicine',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddMedicineDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New Medicine'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(40),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Show only items from this distributor', style: TextStyle(fontSize: 14)),
                    value: _filterByDistributor,
                    activeColor: const Color(0xFF166534),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() => _filterByDistributor = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: inventory.when(
                      data: (items) {
                        final q = _searchCtrl.text.toLowerCase();
                        final filtered = items.where((i) {
                          final matchesSearch = i.name.toLowerCase().contains(q) || i.sku.toLowerCase().contains(q);
                          
                          final matchesDistributor = !_filterByDistributor || 
                              i.distributorId == widget.distributor['id'] ||
                              (i.distributor != null && widget.distributor['name'] != null && 
                               i.distributor!.toLowerCase() == widget.distributor['name'].toString().toLowerCase());
                               
                          return matchesSearch && matchesDistributor;
                        }).toList();
                        
                        if (filtered.isEmpty) {
                          return const Center(child: Text('No items found', style: TextStyle(color: Colors.grey)));
                        }
                        
                        return ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return ListTile(
                              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Stock: ${item.stockQuantity} | BP: ₹${item.buyingPrice}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle, color: Color(0xFF166534)),
                                onPressed: () => _addItem({
                                  'id': item.id,
                                  'name': item.name,
                                  'buying_price': item.buyingPrice,
                                  'unit_price': item.unitPrice,
                                  'batch_number': item.batchNumber,
                                  'expiry_date': item.expiryDate,
                                  'hsn_code': item.hsnCode,
                                  'gst': item.gst,
                                  'rack_id': item.rackId,
                                  'category_id': item.categoryId,
                                }),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Text('Error: $err'),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
          const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
          // Right: Bill Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Incoming Stock', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      child: ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return ListTile(
                            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Qty: '),
                                    SizedBox(
                                      width: 60,
                                      child: TextFormField(
                                        initialValue: item['quantity'].toString(),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) {
                                          setState(() {
                                            _items[index]['quantity'] = int.tryParse(v) ?? 1;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('BP: ₹'),
                                    SizedBox(
                                      width: 80,
                                      child: TextFormField(
                                        initialValue: item['buying_price'].toString(),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) {
                                          setState(() {
                                            _items[index]['buying_price'] = double.tryParse(v) ?? 0.0;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('SP: ₹'),
                                    SizedBox(
                                      width: 80,
                                      child: TextFormField(
                                        initialValue: item['selling_price'].toString(),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) {
                                          setState(() {
                                            _items[index]['selling_price'] = double.tryParse(v) ?? 0.0;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Batch: '),
                                    SizedBox(
                                      width: 100,
                                      child: TextFormField(
                                        initialValue: item['batch_number'].toString(),
                                        onChanged: (v) {
                                          setState(() {
                                            _items[index]['batch_number'] = v;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Exp: '),
                                    SizedBox(
                                      width: 100,
                                      child: TextFormField(
                                        initialValue: item['expiry_date'].toString(),
                                        decoration: const InputDecoration(hintText: 'YYYY-MM-DD'),
                                        onChanged: (v) {
                                          setState(() {
                                            _items[index]['expiry_date'] = v;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('GST %: '),
                                    SizedBox(
                                      width: 50,
                                      child: TextFormField(
                                        initialValue: item['gst'].toString(),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) {
                                          setState(() {
                                            _items[index]['gst'] = double.tryParse(v) ?? 0.0;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('HSN: '),
                                    SizedBox(
                                      width: 80,
                                      child: TextFormField(
                                        initialValue: item['hsn_code'].toString(),
                                        onChanged: (v) {
                                          setState(() {
                                            _items[index]['hsn_code'] = v;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                racks.when(
                                  data: (rList) => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Rack: '),
                                      DropdownButton<String>(
                                        value: item['rack_id'],
                                        hint: const Text('Select'),
                                        items: rList.map((r) => DropdownMenuItem(value: r.id, child: Text(r.rackNumber))).toList(),
                                        onChanged: (v) => setState(() => _items[index]['rack_id'] = v),
                                      ),
                                    ],
                                  ),
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                                categories.when(
                                  data: (cList) => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Category: '),
                                      DropdownButton<String>(
                                        value: item['category_id'],
                                        hint: const Text('Select'),
                                        items: cList.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                        onChanged: (v) => setState(() => _items[index]['category_id'] = v),
                                      ),
                                    ],
                                  ),
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _items.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Payment Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: _paymentStatus,
                        items: const [
                          DropdownMenuItem(value: 'UNPAID', child: Text('UNPAID')),
                          DropdownMenuItem(value: 'PARTIAL', child: Text('PARTIAL')),
                          DropdownMenuItem(value: 'PAID', child: Text('PAID (Deduct from Accounts)')),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _paymentStatus = v!;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
