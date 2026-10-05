import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'widgets/inventory/inventory_dialogs.dart';
import '../../providers/counter_providers.dart';
import 'package:go_router/go_router.dart';
import '../../services/inventory_service.dart';
import '../../services/export_service.dart';
import 'widgets/inventory/inventory_row.dart';
import '../../services/rack_service.dart';
import '../../services/category_service.dart';
import '../../widgets/custom_date_range_picker.dart';
import 'package:intl/intl.dart';
import '../../widgets/rack_dropdown.dart';
import '../../widgets/category_dropdown.dart';
import '../../widgets/distributor_dropdown.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  late LinkedScrollControllerGroup _controllers;
  late ScrollController _headController;
  late ScrollController _bodyController;

  String _selectedDateFilter = 'All Time';
  DateTime? _startDate;
  DateTime? _endDate;

  String _sortColumn = 'Added/Updated';
  bool _sortAscending = false;

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  Widget _buildSortableHeader(String title, int flex) {
    return InkWell(
      onTap: () => _onSort(title),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569),
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          if (_sortColumn == title)
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: const Color(0xFF22C55E),
            )
          else
            const Icon(Icons.unfold_more, size: 14, color: Colors.black26),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controllers = LinkedScrollControllerGroup();
    _headController = _controllers.addAndGet();
    _bodyController = _controllers.addAndGet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData([String? query]) async {
    ref
        .read(inventoryProvider.notifier)
        .loadInventory(
          searchQuery: query ?? _searchController.text,
          startDate: _startDate != null
              ? DateFormat('yyyy-MM-dd').format(_startDate!)
              : null,
          endDate: _endDate != null
              ? DateFormat('yyyy-MM-dd').format(_endDate!)
              : null,
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
    final racks = ref.read(rackProvider).value ?? [];
    final categories = ref.read(categoryProvider).value ?? [];

    final data =
        currentState.value?.map((m) {
          final rackName = racks
              .firstWhere(
                (r) => r.id == m.rackId,
                orElse: () => Rack(id: '', rackNumber: 'N/A'),
              )
              .rackNumber;
          final categoryName = categories
              .firstWhere(
                (c) => c.id == m.categoryId,
                orElse: () => Category(id: '', name: 'N/A'),
              )
              .name;

          return {
            'Name': m.name,
            'SKU': m.sku,
            'Batch': m.batchNumber,
            'Stock': m.stockQuantity,
            'Loose Stock': m.looseStock,
            'Pack Size': m.packSize ?? 'N/A',
            'Buying Price (₹)': m.buyingPrice,
            'Unit Price (₹)': m.unitPrice,
            'GST (%)': m.gst ?? 0,
            'Discount (%)': m.discount ?? 0,
            'Manufacturer': m.manufacturer,
            'Expiry': m.expiryDate,
            'Rack': rackName,
            'Category': categoryName,
            'Distributor': m.distributor ?? 'N/A',
            'HSN Code': m.hsnCode ?? 'N/A',
          };
        }).toList() ??
        [];

    final settings = ref.read(settingsProvider).value ?? {};
    final shopDetails = {
      'name': settings['shop_name'] ?? 'MANJU MEDICAL STORES',
      'location': settings['address'],
      'contact': settings['phone'],
      'email': settings['email'],
      'gstin': settings['gst_number'],
      'logo_url': settings['logo_url'],
    };

    final filename =
        'inventory_export_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    try {
      if (format == 'CSV') {
        await ExportService.exportToCSV(data, filename);
      } else if (format == 'Excel') {
        await ExportService.exportToExcel(data, filename);
      } else if (format == 'PDF') {
        await ExportService.exportToPDF(data, filename, shopDetails);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported as $format successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteMedicine(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text(
          'Are you sure you want to delete this medicine? This action cannot be undone.',
        ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medicine deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchData(_searchController.text);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showEditMedicineDialog(InventoryItem item) {
    InventoryDialogs.showEditMedicineDialog(
      context,
      ref,
      item,
      () => _fetchData(),
    );
  }

  Widget _buildConditionalWrapper(bool isShort, Widget child) {
    return isShort
        ? SizedBox(height: 800, child: child)
        : Expanded(child: child);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _headController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final shopsAsync = ref.watch(shopProvider);
    final selectedShopId = ref.watch(selectedShopIdProvider);
    final racks = ref.watch(rackProvider).value ?? [];
    final categories = ref.watch(categoryProvider).value ?? [];
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: LayoutBuilder(
        builder: (context, screenConstraints) {
          bool isScreenShort =
              screenConstraints.maxHeight < 850 ||
              screenConstraints.maxWidth < 1000;
          final isDesktopWidth = screenConstraints.maxWidth >= 1000;
          Widget content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32.0),
                color: Colors.transparent,
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
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                            ),
                            children: [
                              TextSpan(text: 'Medicine '),
                              TextSpan(
                                text: 'Inventory',
                                style: TextStyle(color: Color(0xFF166534)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your medicine stock, expiry, and availability in one place.',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Shop Dropdown
                        shopsAsync.when(
                          data: (shops) {
                            if (shops.isEmpty) return const SizedBox();
                            return Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: (() {
                                    final id =
                                        selectedShopId ??
                                        (shops.isNotEmpty
                                            ? shops.first['id'].toString()
                                            : null);
                                    if (id != null &&
                                        shops.any(
                                          (shop) => shop['id'].toString() == id,
                                        )) {
                                      return id;
                                    }
                                    return shops.isNotEmpty
                                        ? shops.first['id'].toString()
                                        : null;
                                  })(),
                                  icon: Icon(
                                    Icons.store,
                                    size: 16,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                  onChanged: (String? newShopId) async {
                                    if (newShopId != null &&
                                        newShopId != selectedShopId) {
                                      ref
                                          .read(selectedShopIdProvider.notifier)
                                          .updateShopId(newShopId);
                                      await InventoryService.setShopId(
                                        newShopId,
                                      );
                                      ref.invalidate(rackProvider);
                                      ref.invalidate(categoryProvider);
                                      _fetchData(); // Refetch inventory for new shop
                                    }
                                  },
                                  items: shops.map((shop) {
                                    return DropdownMenuItem<String>(
                                      value: shop['id'].toString(),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: Text(
                                          shop['name'] ?? 'Unknown Shop',
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (err, stack) => IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.red),
                            tooltip: 'Retry',
                            onPressed: () => ref
                                .read(inventoryProvider.notifier)
                                .loadInventory(),
                          ),
                        ),
                        // Search Bar
                        Container(
                          width: 280,
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                    onChanged: (value) {
                                      if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
                                      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                                        _fetchData(value);
                                      });
                                    },
                                  onSubmitted: (value) => _fetchData(value),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText:
                                        'Search inventory by name or brand...',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                    ),
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
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedDateFilter,
                              icon: Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                              ),
                              onChanged: (value) {
                                if (value != null) _onDateFilterChanged(value);
                              },
                              items:
                                  [
                                        'All Time',
                                        'Today',
                                        'This Week',
                                        'This Month',
                                        'This Year',
                                        'Custom Range',
                                      ]
                                      .map(
                                        (filter) => DropdownMenuItem(
                                          value: filter,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8.0,
                                            ),
                                            child: Text(filter),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        ),
                        // Sort By Dropdown
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            final parts = value.split('|');
                            setState(() {
                              _sortColumn = parts[0];
                              _sortAscending = parts[1] == 'asc';
                            });
                          },
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sort,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Sort By',
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'Medicine Name|asc',
                              child: Text('Medicine Name (A-Z)'),
                            ),
                            const PopupMenuItem(
                              value: 'Medicine Name|desc',
                              child: Text('Medicine Name (Z-A)'),
                            ),
                            const PopupMenuItem(
                              value: 'Added/Updated|desc',
                              child: Text('Added/Updated (Newest First)'),
                            ),
                            const PopupMenuItem(
                              value: 'Added/Updated|asc',
                              child: Text('Added/Updated (Oldest First)'),
                            ),
                            const PopupMenuItem(
                              value: 'Stock|asc',
                              child: Text('Stock (Low to High)'),
                            ),
                            const PopupMenuItem(
                              value: 'Stock|desc',
                              child: Text('Stock (High to Low)'),
                            ),
                            const PopupMenuItem(
                              value: 'Price (₹)|asc',
                              child: Text('Price (Low to High)'),
                            ),
                            const PopupMenuItem(
                              value: 'Price (₹)|desc',
                              child: Text('Price (High to Low)'),
                            ),
                            const PopupMenuItem(
                              value: 'Expiry Date|asc',
                              child: Text('Expiry Date (Earliest First)'),
                            ),
                            const PopupMenuItem(
                              value: 'Expiry Date|desc',
                              child: Text('Expiry Date (Latest First)'),
                            ),
                          ],
                        ),
                        // Export Buttons
                        PopupMenuButton<String>(
                          onSelected: _exportData,
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.download,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Export',
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'CSV',
                              child: Text('Export as CSV'),
                            ),
                            const PopupMenuItem(
                              value: 'Excel',
                              child: Text('Export as Excel'),
                            ),
                            const PopupMenuItem(
                              value: 'PDF',
                              child: Text('Export as PDF'),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => _fetchData(),
                          icon: Icon(
                            Icons.refresh,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                          tooltip: 'Refresh',
                        ),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                context.go('/counter/inventory/upload'),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text(
                              'Add New Medicine',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: inventoryAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF22C55E),
                          ),
                        ),
                        error: (err, stack) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                err.toString(),
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => ref
                                    .read(inventoryProvider.notifier)
                                    .loadInventory(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                        data: (medicines) {
                          if (medicines.isEmpty) {
                            return const Center(
                              child: Text(
                                'No shop found or inventory is empty.',
                              ),
                            );
                          }

                          final sortedItems = List<InventoryItem>.from(
                            medicines,
                          );
                          sortedItems.sort((a, b) {
                            int cmp = 0;
                            switch (_sortColumn) {
                              case 'Medicine Name':
                                cmp = a.name.toLowerCase().compareTo(
                                  b.name.toLowerCase(),
                                );
                                break;
                              case 'Added/Updated':
                                final aDate = a.createdAt ?? '';
                                final bDate = b.createdAt ?? '';
                                cmp = aDate.compareTo(bDate);
                                break;
                              case 'Stock':
                                cmp = a.stockQuantity.compareTo(
                                  b.stockQuantity,
                                );
                                break;
                              case 'Price (₹)':
                                cmp = a.unitPrice.compareTo(b.unitPrice);
                                break;
                              case 'GST (%)':
                                cmp = (a.gst ?? 0).compareTo(b.gst ?? 0);
                                break;
                              case 'Expiry Date':
                                cmp = a.expiryDate.compareTo(b.expiryDate);
                                break;
                              case 'Status':
                                final aLow = a.lowStockThreshold ?? 10;
                                final bLow = b.lowStockThreshold ?? 10;
                                final aStatus = a.stockQuantity == 0
                                    ? 0
                                    : (a.stockQuantity <= aLow ? 1 : 2);
                                final bStatus = b.stockQuantity == 0
                                    ? 0
                                    : (b.stockQuantity <= bLow ? 1 : 2);
                                cmp = aStatus.compareTo(bStatus);
                                break;
                            }
                            return _sortAscending ? cmp : -cmp;
                          });

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // FIXED LEFT COLUMN
                              SizedBox(
                                width: isDesktopWidth ? 280 : 140,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      height: 48,
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : const Color(0xFFF1F5F9),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isDesktopWidth ? 24 : 8,
                                      ),
                                      child: _buildSortableHeader(
                                        'Medicine Name',
                                        1,
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.separated(
                                        controller: _headController,
                                        itemCount: sortedItems.length + 1,
                                        separatorBuilder: (context, index) =>
                                            Divider(
                                              height: 1,
                                              color: Theme.of(context).dividerColor,
                                            ),
                                        itemBuilder: (context, index) {
                                          if (index == sortedItems.length) {
                                            return const SizedBox(
                                              height: 80,
                                            ); // match right side height
                                          }
                                          final medicine = sortedItems[index];
                                          return InventoryRowLeftWidget(
                                            medicine: medicine,
                                            onTap: () =>
                                                _showEditMedicineDialog(
                                                  medicine,
                                                ),
                                            isDesktopWidth: isDesktopWidth,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // SCROLLABLE RIGHT COLUMNS
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: isDesktopWidth
                                        ? (screenConstraints.maxWidth -
                                                      64 -
                                                      280 >
                                                  1128
                                              ? screenConstraints.maxWidth -
                                                    64 -
                                                    280
                                              : 1128)
                                        : (screenConstraints.maxWidth -
                                                      64 -
                                                      140 >
                                                  1096
                                              ? screenConstraints.maxWidth -
                                                    64 -
                                                    140
                                              : 1096),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Container(
                                          height: 48,
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : const Color(0xFFF1F5F9),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isDesktopWidth ? 24 : 8,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 120,
                                                child: _buildSortableHeader(
                                                  'Category',
                                                  1,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 120,
                                                child: _buildSortableHeader(
                                                  'Added/Updated',
                                                  1,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 100,
                                                child: _buildSortableHeader(
                                                  'Stock',
                                                  1,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 80,
                                                child: _buildSortableHeader(
                                                  'Rack',
                                                  1,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 100,
                                                child: _buildSortableHeader(
                                                  'Buying Price',
                                                  1,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 100,
                                                child: _buildSortableHeader(
                                                  'Price (₹)',
                                                  1,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 80,
                                                child: _buildSortableHeader(
                                                  'GST (%)',
                                                  1,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 120,
                                                child: _buildSortableHeader(
                                                  'Distributor',
                                                  1,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 100,
                                                child: _buildSortableHeader(
                                                  'Expiry Date',
                                                  1,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 120,
                                                child: _buildSortableHeader(
                                                  'Status',
                                                  1,
                                                ),
                                              ),
                                              const SizedBox(width: 40),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: ListView.separated(
                                            controller: _bodyController,
                                            itemCount: sortedItems.length + 1,
                                            separatorBuilder:
                                                (context, index) =>
                                                    Divider(
                                                      height: 1,
                                                      color: Theme.of(context).dividerColor,
                                                    ),
                                            itemBuilder: (context, index) {
                                              if (index == sortedItems.length) {
                                                if (ref
                                                    .read(
                                                      inventoryProvider
                                                          .notifier,
                                                    )
                                                    .hasMore) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          16.0,
                                                        ),
                                                    child: Center(
                                                      child: OutlinedButton(
                                                        onPressed: () => ref
                                                            .read(
                                                              inventoryProvider
                                                                  .notifier,
                                                            )
                                                            .loadMore(),
                                                        child: const Text(
                                                          'Load More',
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return const SizedBox(
                                                  height: 80,
                                                );
                                              }

                                              final medicine =
                                                  sortedItems[index];
                                              final rackName = racks
                                                  .firstWhere(
                                                    (r) =>
                                                        r.id == medicine.rackId,
                                                    orElse: () => Rack(
                                                      id: '',
                                                      rackNumber: '-',
                                                    ),
                                                  )
                                                  .rackNumber;
                                              final categoryName = categories
                                                  .firstWhere(
                                                    (c) =>
                                                        c.id ==
                                                        medicine.categoryId,
                                                    orElse: () => Category(
                                                      id: '',
                                                      name: 'N/A',
                                                    ),
                                                  )
                                                  .name;

                                              return InventoryRowRightWidget(
                                                medicine: medicine,
                                                rackName: rackName,
                                                categoryName: categoryName,
                                                onTap: () =>
                                                    _showEditMedicineDialog(
                                                      medicine,
                                                    ),
                                                onEdit: () =>
                                                    _showEditMedicineDialog(
                                                      medicine,
                                                    ),
                                                onDelete: () =>
                                                    _confirmDeleteMedicine(
                                                      medicine.id,
                                                    ),
                                                isDesktopWidth: isDesktopWidth,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );

          return isScreenShort
              ? SingleChildScrollView(child: content)
              : content;
        },
      ),
    );
  }
}
