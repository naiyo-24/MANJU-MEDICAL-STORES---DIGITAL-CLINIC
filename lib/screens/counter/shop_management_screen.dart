import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/shop_service.dart';
import '../../services/export_service.dart';
import 'widgets/shop/shop_summary_cards.dart';
import 'widgets/shop/shop_table.dart';

class ShopManagementScreen extends StatefulWidget {
  const ShopManagementScreen({super.key});

  @override
  State<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen> {
  List<Shop> _shops = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'All Status';
  String _selectedCity = 'All Cities';
  bool _sortAscending = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadShops();
    // Poll for realtime updates every 3 seconds silently
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadShops(silent: true);
    });
  }

  Future<void> _loadShops({bool silent = false}) async {
    try {
      final shops = await ShopService.getShops();
      if (mounted) {
        setState(() {
          _shops = shops;
          if (!silent) _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading shops: $e')));
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _exportData(String format) async {
    final exportData = _shops
        .map(
          (s) => {
            'Name': s.name,
            'Code': s.code,
            'Address': s.location,
            'City': s.city,
            'Contact': s.contact,
            'Status': s.status,
            'Primary': s.isPrimary ? 'Yes' : 'No',
          },
        )
        .toList();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'shops_$timestamp';

    try {
      if (format == 'pdf') {
        await ExportService.exportToPDF(exportData, filename);
      } else if (format == 'excel') {
        await ExportService.exportToExcel(exportData, filename);
      } else if (format == 'csv') {
        await ExportService.exportToCSV(exportData, filename);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Export successful!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  void _showEditShopDialog(Shop shop) {
    final nameCtrl = TextEditingController(text: shop.name);
    final codeCtrl = TextEditingController(text: shop.code);
    final locationCtrl = TextEditingController(text: shop.location);
    final cityCtrl = TextEditingController(text: shop.city);
    final contactCtrl = TextEditingController(text: shop.contact);
    String status = shop.status;
    bool isPrimary = shop.isPrimary;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Shop'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Shop Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(labelText: 'Shop Code'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contactCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contact Number',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: status.toLowerCase() == 'active'
                          ? 'Active'
                          : 'Inactive',
                      items: const [
                        DropdownMenuItem(
                          value: 'Active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'Inactive',
                          child: Text('Inactive'),
                        ),
                      ],
                      onChanged: (v) => setDialogState(() => status = v!),
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Is Primary Shop?'),
                      value: isPrimary,
                      onChanged: (v) => setDialogState(() => isPrimary = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ShopService.updateShop(
                        id: shop.id,
                        name: nameCtrl.text,
                        code: codeCtrl.text,
                        address: locationCtrl.text,
                        city: cityCtrl.text,
                        contactNumber: contactCtrl.text,
                        status: status,
                        isPrimary: isPrimary,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadShops();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Shop updated successfully'),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating shop: $e')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredShops = _shops.where((s) {
      final matchesSearch =
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.code.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _selectedStatus == 'All Status' ||
          s.status.toLowerCase() == _selectedStatus.toLowerCase();
      final matchesCity =
          _selectedCity == 'All Cities' ||
          s.city.toLowerCase() == _selectedCity.toLowerCase();
      return matchesSearch && matchesStatus && matchesCity;
    }).toList();

    filteredShops.sort(
      (a, b) =>
          _sortAscending ? a.name.compareTo(b.name) : b.name.compareTo(a.name),
    );

    final activeCount = _shops
        .where((s) => s.status.toLowerCase() == 'active')
        .length;
    final inactiveCount = _shops.length - activeCount;

    final allCities = [
      'All Cities',
      ..._shops.map((s) => s.city).toSet().toList(),
    ];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            SizedBox(
              width: double.infinity,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                spacing: 16,
                runSpacing: 16,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.storefront,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shops',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Manage your branch shops and their settings',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      PopupMenuButton<String>(
                        tooltip: 'Export Options',
                        onSelected: _exportData,
                        offset: const Offset(0, 50),
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'pdf',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.picture_as_pdf,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 12),
                                    Text('Export as PDF'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'excel',
                                child: Row(
                                  children: [
                                    Icon(Icons.table_view, color: Colors.green),
                                    SizedBox(width: 12),
                                    Text('Export as Excel'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'csv',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.insert_drive_file,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 12),
                                    Text('Export as CSV'),
                                  ],
                                ),
                              ),
                            ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? Colors.white24
                                  : const Color(0xFFE2E8F0),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.download,
                                size: 18,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF475569),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Export',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: Color(0xFF64748B),
                        ),
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadShops();
                        },
                      ),
                      if (_shops.isEmpty)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add New Shop'),
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Summary Cards Component
            ShopSummaryCards(
              totalShops: _shops.length,
              activeShops: activeCount,
              inactiveShops: inactiveCount,
              totalLocations: _shops.map((s) => s.city).toSet().length,
            ),
            const SizedBox(height: 32),

            // Main Content Area
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  // Toolbar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: 300,
                          child: TextField(
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText:
                                  'Search shop by name, code, location...',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFF94A3B8),
                                size: 18,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 150,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStatus,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                              items: ['All Status', 'Active', 'Inactive'].map((
                                String value,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null)
                                  setState(() => _selectedStatus = newValue);
                              },
                            ),
                          ),
                        ),
                        Container(
                          width: 150,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCity,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                              items: allCities.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null)
                                  setState(() => _selectedCity = newValue);
                              },
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              setState(() => _sortAscending = !_sortAscending),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _sortAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 16,
                                  color: const Color(0xFF475569),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Sort By: NAME',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Component
                  ShopTable(
                    shops: filteredShops,
                    isLoading: _isLoading,
                    onEdit: _showEditShopDialog,
                  ),

                  const SizedBox(height: 48),

                  // Multi-Branch Management Upcoming Feature Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 64,
                      horizontal: 24,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.15),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.hub_rounded,
                            size: 72,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'Multi-Branch Management',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'We are designing a powerful new way for you\nto manage multiple\npharmacy branches from a single unified\ndashboard.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
