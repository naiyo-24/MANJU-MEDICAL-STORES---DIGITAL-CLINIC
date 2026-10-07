import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/counter_providers.dart';
import '../../services/purchase_service.dart';
import '../../config/api_constants.dart';
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
  final _invoiceCtrl = TextEditingController();
  String _paymentStatus = 'UNPAID';
  double _amountPaid = 0.0;
  double _globalDiscount = 0.0;

  bool _isLoading = false;
  bool _filterByDistributor = false;
  Timer? _refreshTimer;
  Timer? _searchDebounce;

  double get _subtotal {
    double total = 0;
    for (var item in _items) {
      total += (item['buying_price'] as double) * (item['quantity'] as int);
    }
    return total;
  }
  
  double get _totalGst {
    double total = 0;
    for (var item in _items) {
      double bp = (item['buying_price'] as double);
      double qty = (item['quantity'] as int).toDouble();
      double gstPercent = (item['gst'] as double?) ?? 0.0;
      double itemTotal = bp * qty;
      total += itemTotal * (gstPercent / 100);
    }
    return total;
  }
  
  double get _grandTotal {
    return _subtotal + _totalGst - _globalDiscount;
  }

  @override
  void initState() {
    super.initState();
    // Auto-generate an internal invoice number (e.g., INV-PUR-169876543)
    // The user can still edit or clear this if the supplier provided a specific invoice number.
    _invoiceCtrl.text = 'INV-PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';
    

  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _invoiceCtrl.dispose();
    super.dispose();
  }

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
      double totalAmount = _grandTotal;

      final billData = {
        'shop_id': shopId,
        'distributor_id': widget.distributor['id'],
        'invoice_no': _invoiceCtrl.text.isNotEmpty ? _invoiceCtrl.text : null,
        'payment_status': _paymentStatus,
        'bill_date': DateTime.now().toIso8601String().split('T')[0],
        'total_amount': totalAmount,
        'subtotal': _subtotal,
        'total_discount': _globalDiscount,
        'total_gst': _totalGst,
        'amount_paid': _paymentStatus == 'UNPAID' ? 0.0 : (_paymentStatus == 'PAID' ? totalAmount : _amountPaid),
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

      final response = await _purchaseService.createPurchaseBill(billData);
      final billId = response['id'];
      
      ref.invalidate(inventoryProvider); // Refresh main stock
      ref.invalidate(purchaseInventoryProvider); // Refresh purchase stock
      ref.invalidate(purchaseBillsProvider); // Refresh dashboard KPIs
      ref.invalidate(accountsProvider); // Refresh accounts
      ref.invalidate(historyProvider); // Refresh transactions history
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Purchase Success'),
            content: const Text('Purchase bill created and stock updated successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Generate Bill (PDF)'),
                onPressed: () async {
                  final url = Uri.parse('${ApiConstants.baseUrl}/api/admin/purchases/$billId/pdf');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        );
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
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final inputDec = (String label) => InputDecoration(
            labelText: label,
            filled: true,
            fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF166534), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          );
          
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: Container(
              width: 850,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF166534),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.medication_liquid, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Text('Add New Medicine', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),
                  
                  // Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: [
                          SizedBox(width: 370, child: TextField(controller: nameCtrl, decoration: inputDec('Medicine Name *'))),
                          SizedBox(width: 370, child: TextField(controller: mfgCtrl, decoration: inputDec('Manufacturer'))),
                          SizedBox(width: 370, child: TextField(controller: bpCtrl, keyboardType: TextInputType.number, decoration: inputDec('Buying Price (₹) *'))),
                          SizedBox(width: 370, child: TextField(controller: spCtrl, keyboardType: TextInputType.number, decoration: inputDec('Selling Price (MRP ₹) *'))),
                          SizedBox(width: 173, child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: inputDec('Initial Stock *'))),
                          SizedBox(width: 173, child: TextField(controller: packSizeCtrl, keyboardType: TextInputType.number, decoration: inputDec('Pieces/Pack'))),
                          SizedBox(width: 173, child: TextField(controller: gstCtrl, keyboardType: TextInputType.number, decoration: inputDec('GST (%)'))),
                          SizedBox(width: 173, child: TextField(controller: discountCtrl, keyboardType: TextInputType.number, decoration: inputDec('Discount (%)'))),
                          SizedBox(width: 173, child: TextField(controller: batchCtrl, decoration: inputDec('Batch Number'))),
                          SizedBox(width: 173, child: TextField(controller: expiryCtrl, decoration: inputDec('Expiry (yyyy-mm-dd)'))),
                          SizedBox(width: 370, child: TextField(controller: hsnCtrl, decoration: inputDec('HSN Code'))),
                          SizedBox(width: 370, child: TextField(controller: skuCtrl, decoration: inputDec('Barcode / SKU'))),
                          
                          SizedBox(
                            width: 370,
                            child: DropdownButtonFormField<String>(
                              decoration: inputDec('Category'),
                              value: selectedCategoryId,
                              items: cList.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                              onChanged: (v) => setDialogState(() => selectedCategoryId = v),
                            ),
                          ),
                          SizedBox(
                            width: 370,
                            child: DropdownButtonFormField<String>(
                              decoration: inputDec('Rack / Location'),
                              value: selectedRackId,
                              items: rList.map((r) => DropdownMenuItem(value: r.id, child: Text(r.rackNumber))).toList(),
                              onChanged: (v) => setDialogState(() => selectedRackId = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Footer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      border: Border(top: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            foregroundColor: Colors.grey.shade700,
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                        ),
                        ElevatedButton.icon(
                          icon: isSaving 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_circle_outline),
                          label: Text(isSaving ? 'Saving...' : 'Save Medicine', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF166534),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
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
                    
                    ref.invalidate(inventoryProvider); // Refresh global stock
                    ref.invalidate(purchaseInventoryProvider); // Refresh local search list
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine created & added to bill!'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                } finally {
                  if (context.mounted) setDialogState(() => isSaving = false);
                }
              },
            ),
          ],
        )
      ),
    ],
  ),
),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(purchaseInventoryProvider);
    final racks = ref.watch(rackProvider);
    final categories = ref.watch(categoryProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final searchPanel = Material(
      color: isDark ? Theme.of(context).cardColor : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search Medicine',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
                      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                        ref.read(purchaseInventoryProvider.notifier).loadInventory(
                          searchQuery: val,
                          distributorId: _filterByDistributor ? widget.distributor['id'] : null,
                        );
                      });
                      setState(() {}); 
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    ref.read(purchaseInventoryProvider.notifier).loadInventory(
                      searchQuery: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
                      distributorId: _filterByDistributor ? widget.distributor['id'] : null,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Medicine list refreshed!'), duration: Duration(seconds: 1)),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Medicines',
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50,
                    foregroundColor: isDark ? Colors.greenAccent : const Color(0xFF166534),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Show only items from this distributor', style: TextStyle(fontSize: 14)),
              value: _filterByDistributor,
              activeColor: const Color(0xFF166534),
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() => _filterByDistributor = val);
                ref.read(purchaseInventoryProvider.notifier).loadInventory(
                  searchQuery: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
                  distributorId: val ? widget.distributor['id'] : null,
                );
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
                  
                  if (filtered.isEmpty) return const Center(child: Text('No items found', style: TextStyle(color: Colors.grey)));
                  
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => ref.read(purchaseInventoryProvider.notifier).loadMore(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF166534),
                  side: const BorderSide(color: Color(0xFF166534)),
                ),
                child: const Text('Load More Medicines'),
              ),
            ),
          ],
        ),
      ),
    );

    final billPanel = Padding(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Incoming Stock', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (!isDesktop)
                Text('Items: ${_items.length}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
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
                            SizedBox(width: 60, child: TextFormField(
                              initialValue: item['quantity'].toString(),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setState(() => _items[index]['quantity'] = int.tryParse(v) ?? 1),
                            )),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('BP: ₹'),
                            SizedBox(width: 80, child: TextFormField(
                              initialValue: item['buying_price'].toString(),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setState(() => _items[index]['buying_price'] = double.tryParse(v) ?? 0.0),
                            )),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('SP: ₹'),
                            SizedBox(width: 80, child: TextFormField(
                              initialValue: item['selling_price'].toString(),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setState(() => _items[index]['selling_price'] = double.tryParse(v) ?? 0.0),
                            )),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Batch: '),
                            SizedBox(width: 100, child: TextFormField(
                              initialValue: item['batch_number'].toString(),
                              onChanged: (v) => setState(() => _items[index]['batch_number'] = v),
                            )),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Exp: '),
                            SizedBox(width: 100, child: TextFormField(
                              initialValue: item['expiry_date'].toString(),
                              decoration: const InputDecoration(hintText: 'YYYY-MM-DD'),
                              onChanged: (v) => setState(() => _items[index]['expiry_date'] = v),
                            )),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('GST %: '),
                            SizedBox(width: 50, child: TextFormField(
                              initialValue: item['gst'].toString(),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setState(() => _items[index]['gst'] = double.tryParse(v) ?? 0.0),
                            )),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('HSN: '),
                            SizedBox(width: 80, child: TextFormField(
                              initialValue: item['hsn_code'].toString(),
                              onChanged: (v) => setState(() => _items[index]['hsn_code'] = v),
                            )),
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
                      onPressed: () => setState(() => _items.removeAt(index)),
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  const Text('Subtotal: ', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 100, child: Text('₹${_subtotal.toStringAsFixed(2)}', textAlign: TextAlign.right)),
                ]),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  const Text('Total GST: ', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 100, child: Text('+ ₹${_totalGst.toStringAsFixed(2)}', textAlign: TextAlign.right)),
                ]),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  const Text('Discount: ', style: TextStyle(fontSize: 14)),
                  SizedBox(
                    width: 100, 
                    child: TextField(
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(isDense: true, prefixText: '₹'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => _globalDiscount = double.tryParse(v) ?? 0.0),
                    ),
                  ),
                ]),
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  const Text('Grand Total: ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(width: 100, child: Text('₹${_grandTotal.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Payment Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
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
                        if (_paymentStatus == 'PAID') _amountPaid = _grandTotal;
                      });
                    },
                  ),
                ],
              ),
              if (_paymentStatus == 'PARTIAL') Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Amount Paid: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      decoration: const InputDecoration(isDense: true, prefixText: '₹'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => _amountPaid = double.tryParse(v) ?? 0.0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final actionsWrap = Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _showAddMedicineDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add New Medicine'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF166534),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        SizedBox(
          width: 150,
          child: TextField(
            controller: _invoiceCtrl,
            decoration: const InputDecoration(
              hintText: 'Auto Gen',
              labelText: 'Invoice Number',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534)),
          child: _isLoading 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : const Text('Confirm Purchase', style: TextStyle(color: Colors.white)),
        ),
      ],
    );

    if (!isDesktop) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text('Purchase from ${widget.distributor['name']}', style: const TextStyle(fontSize: 16)),
            backgroundColor: isDark ? Theme.of(context).appBarTheme.backgroundColor : Colors.white,
            foregroundColor: isDark ? Colors.white : Colors.black,
            elevation: 1,
            bottom: const TabBar(
              labelColor: Color(0xFF166534),
              indicatorColor: Color(0xFF166534),
              tabs: [
                Tab(icon: Icon(Icons.search), text: 'Search'),
                Tab(icon: Icon(Icons.receipt), text: 'Bill'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              searchPanel,
              billPanel,
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : Colors.white,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: actionsWrap,
              ),
            ),
          ),
        ),
      );
    }

    // Desktop Layout
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Purchase from ${widget.distributor['name']}'),
        backgroundColor: isDark ? Theme.of(context).appBarTheme.backgroundColor : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: actionsWrap,
          )
        ],
      ),
      body: Row(
        children: [
          Expanded(flex: 1, child: searchPanel),
          const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
          Expanded(flex: 2, child: billPanel),
        ],
      ),
    );
  }
}
