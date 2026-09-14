import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/inventory_service.dart';
import '../../config/api_constants.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<InventoryItem> _medicines = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData([String? query]) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final items = await InventoryService.fetchInventory(searchQuery: query);
      setState(() {
        _medicines = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _fetchData(value);
  }

  Future<void> _confirmDeleteMedicine(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text('Are you sure you want to delete this medicine? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await InventoryService.deleteMedicine(itemId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine deleted successfully!'), backgroundColor: Colors.green));
          _fetchData(_searchController.text);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _showEditMedicineDialog(InventoryItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final skuCtrl = TextEditingController(text: item.sku);
    final mfgCtrl = TextEditingController(text: item.manufacturer);
    final batchCtrl = TextEditingController(text: item.batchNumber);
    final stockCtrl = TextEditingController(text: item.stockQuantity.toString());
    final priceCtrl = TextEditingController(text: item.unitPrice.toString());
    final expiryCtrl = TextEditingController(text: item.expiryDate);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Medicine', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Medicine Name')),
              const SizedBox(height: 8),
              TextField(controller: mfgCtrl, decoration: const InputDecoration(labelText: 'Manufacturer')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Selling Price (₹)'))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock Quantity'))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: batchCtrl, decoration: const InputDecoration(labelText: 'Batch Number'))),
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
                          expiryCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
                          'unit_price': double.tryParse(priceCtrl.text) ?? 0.0,
                          'expiry_date': expiryCtrl.text,
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine updated successfully!'), backgroundColor: Colors.green));
                          _fetchData(_searchController.text);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0369A1)),
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, [String? text]) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'In Stock':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        break;
      case 'Low Stock':
        bgColor = const Color(0xFFFEF9C3);
        textColor = const Color(0xFF854D0E);
        break;
      case 'Out of Stock':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text ?? status,
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header
          Container(
            padding: const EdgeInsets.all(32.0),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        children: [
                          TextSpan(text: 'Medicine '),
                          TextSpan(text: 'Inventory', style: TextStyle(color: Color(0xFF166534))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage your medicine stock, expiry, and availability in one place.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Search Bar
                    Container(
                      width: 280,
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Color(0xFF64748B), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search inventory by name or brand...',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _fetchData(),
                        icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
                        tooltip: 'Refresh',
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/counter/inventory/upload'),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add New Medicine', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  ],
                ),
              ],
            ),
          ),

          // List Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Table Header
                      Container(
                        color: const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                            Expanded(flex: 2, child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                            Expanded(flex: 2, child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                            Expanded(flex: 2, child: Text('Price (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                            Expanded(flex: 2, child: Text('Expiry Date', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                            Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                            SizedBox(width: 40), // For action button
                          ],
                        ),
                      ),
                      
                      // Table Body
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)))
                            : _errorMessage.isNotEmpty
                                ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                                : _medicines.isEmpty
                                    ? const Center(child: Text('No inventory items found.'))
                                    : ListView.separated(
                                        itemCount: _medicines.length,
                                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                        itemBuilder: (context, index) {
                                          final medicine = _medicines[index];
                                          // Simple status logic based on stock
                                          final status = medicine.stockQuantity <= 0 ? 'Out of Stock' : (medicine.stockQuantity <= (medicine.lowStockThreshold ?? 10) ? 'Low Stock' : 'In Stock');
                                          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF1F5F9),
                                                          borderRadius: BorderRadius.circular(8),
                                                          image: medicine.imageUrl != null
                                                              ? DecorationImage(
                                                                  image: NetworkImage('${ApiConstants.baseUrl}${medicine.imageUrl}'),
                                                                  fit: BoxFit.cover,
                                                                )
                                                              : null,
                                                        ),
                                                        child: medicine.imageUrl == null
                                                            ? const Icon(Icons.medication, color: Color(0xFF94A3B8), size: 20)
                                                            : null,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(medicine.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                            const SizedBox(height: 4),
                                                            Text(medicine.manufacturer.isNotEmpty ? medicine.manufacturer : 'Unknown', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Expanded(flex: 2, child: Text('Medicine', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    medicine.stockQuantity.toString(),
                                                    style: TextStyle(
                                                      color: medicine.stockQuantity <= 0 
                                                          ? const Color(0xFFDC2626) // Red
                                                          : (medicine.stockQuantity <= (medicine.lowStockThreshold ?? 10) 
                                                              ? const Color(0xFFD97706) // Yellow/Orange
                                                              : const Color(0xFF16A34A)), // Green
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(flex: 2, child: Text('₹${medicine.unitPrice.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.bold))),
                                                Expanded(flex: 2, child: Text(medicine.expiryDate, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                                                Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: _buildStatusBadge(status, '${medicine.stockQuantity} Units'))),
                                                SizedBox(
                                                  width: 40,
                                                  child: PopupMenuButton<String>(
                                                    icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 20),
                                                    onSelected: (value) {
                                                      if (value == 'edit') {
                                                        _showEditMedicineDialog(medicine);
                                                      } else if (value == 'delete') {
                                                        _confirmDeleteMedicine(medicine.id);
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit')])),
                                                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 16), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
