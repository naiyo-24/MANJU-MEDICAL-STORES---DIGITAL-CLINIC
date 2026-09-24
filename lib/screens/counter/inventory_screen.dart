import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/counter_providers.dart';
import 'package:go_router/go_router.dart';
import '../../services/inventory_service.dart';
import '../../services/export_service.dart';
import 'widgets/inventory/inventory_row.dart';
import '../../widgets/custom_date_range_picker.dart';
import 'package:intl/intl.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedDateFilter = 'All Time';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData([String? query]) async {
    ref.read(inventoryProvider.notifier).loadInventory(
      searchQuery: query ?? _searchController.text,
      startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
      endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => CustomDateRangePicker(
        initialRange: _startDate != null && _endDate != null
            ? DateTimeRange(start: _startDate!, end: _endDate!)
            : null,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedDateFilter = 'Custom Range';
      });
      _fetchData();
    }
  }

  void _onDateFilterChanged(String filter) {
    setState(() {
      _selectedDateFilter = filter;
      final now = DateTime.now();
      switch (filter) {
        case 'Today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = _startDate;
          break;
        case 'This Week':
          _startDate = now.subtract(Duration(days: now.weekday - 1));
          _endDate = now;
          break;
        case 'This Month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case 'This Year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
          break;
        case 'All Time':
          _startDate = null;
          _endDate = null;
          break;
      }
    });
    if (filter != 'Custom Range') {
      _fetchData();
    } else {
      _selectDateRange();
    }
  }

  void _exportData(String format) async {
    final currentState = ref.read(inventoryProvider);
    final data = currentState.value?.map((m) => m.toMap()).toList() ?? [];
    final filename = 'inventory_export_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    try {
      if (format == 'CSV') {
        await ExportService.exportToCSV(data, filename);
      } else if (format == 'Excel') {
        await ExportService.exportToExcel(data, filename);
      } else if (format == 'PDF') {
        await ExportService.exportToPDF(data, filename);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported as $format successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export: $e'), backgroundColor: Colors.red));
      }
    }
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

  Widget _buildConditionalWrapper(bool isShort, Widget child) {
    return isShort ? SizedBox(height: 500, child: child) : Expanded(child: child);
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);
    return Container(
      color: const Color(0xFFF8FAFC),
      child: LayoutBuilder(builder: (context, screenConstraints) {
        bool isScreenShort = screenConstraints.maxHeight < 500;
        Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Top Header
          Container(
            padding: const EdgeInsets.all(32.0),
            color: Colors.white,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
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
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
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
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Color(0xFF64748B), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: (value) => _fetchData(value),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search inventory by name or brand...',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Date Filter Dropdown
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDateFilter,
                          icon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748B)),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                          onChanged: (value) {
                            if (value != null) _onDateFilterChanged(value);
                          },
                          items: ['All Time', 'Today', 'This Week', 'This Month', 'This Year', 'Custom Range']
                              .map((filter) => DropdownMenuItem(value: filter, child: Padding(padding: const EdgeInsets.only(right: 8.0), child: Text(filter))))
                              .toList(),
                        ),
                      ),
                    ),
                    // Export Buttons
                    PopupMenuButton<String>(
                      onSelected: _exportData,
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.download, color: Color(0xFF64748B), size: 18),
                            SizedBox(width: 8),
                            Text('Export', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'CSV', child: Text('Export as CSV')),
                        const PopupMenuItem(value: 'Excel', child: Text('Export as Excel')),
                        const PopupMenuItem(value: 'PDF', child: Text('Export as PDF')),
                      ],
                    ),
                    IconButton(
                      onPressed: () => _fetchData(),
                      icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
                      tooltip: 'Refresh',
                    ),
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
          ),

          // List Content
          _buildConditionalWrapper(
            isScreenShort,
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 1000,
                      maxWidth: constraints.maxWidth > 1000 ? constraints.maxWidth : 1000,
                    ),
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
                        child: LayoutBuilder(builder: (context, tableConstraints) {
                          Widget tableColumn = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Table Header
                              Container(
                                color: const Color(0xFFF1F5F9),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                child: const Row(
                                  children: [
                                    Expanded(flex: 3, child: Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                                    Expanded(flex: 2, child: Text('Added/Updated', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
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
                                child: inventoryAsync.when(
                                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E))),
                                error: (err, stack) => Center(child: Text(err.toString(), style: const TextStyle(color: Colors.red))),
                                data: (medicines) {
                                  if (medicines.isEmpty) {
                                    return const Center(child: Text('No inventory items found.'));
                                  }
                                  return ListView.separated(
                                        itemCount: medicines.length,
                                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                        itemBuilder: (context, index) {
                                          final medicine = medicines[index];
                                          // Simple status logic based on stock
return InventoryRowWidget(
                                            medicine: medicine,
                                            onEdit: () => _showEditMedicineDialog(medicine),
                                            onDelete: () => _confirmDeleteMedicine(medicine.id),
                                          );
},
                                      );
                                }),
                      ),
                    ],
                  );
                  
                  if (tableConstraints.maxHeight < 150) {
                    return SingleChildScrollView(
                      child: SizedBox(
                        height: 400,
                        child: tableColumn,
                      ),
                    );
                  }
                  return tableColumn;
                }),
                ),
              ),
            ),
          );
        }),
      ),
    ),
        ],
      );
      
      return isScreenShort ? SingleChildScrollView(child: content) : content;
      }),
    );
  }
}
