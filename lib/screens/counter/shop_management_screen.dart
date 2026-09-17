import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/shop_service.dart';
import '../../services/export_service.dart';
import '../../providers/counter_providers.dart';

class ShopManagementScreen extends ConsumerStatefulWidget {
  const ShopManagementScreen({super.key});

  @override
  ConsumerState<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends ConsumerState<ShopManagementScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'All Status';
  String _selectedCity = 'All Cities';
  bool _isLoading = true;
  String _sortField = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    // Riverpod's AsyncNotifierProvider will fetch automatically on first read.
  }

  List<String> _getDynamicCities(List<Map<String, dynamic>> shops) {
    final cities = shops.map((s) => s['city'].toString()).toSet().toList();
    cities.sort();
    return ['All Cities', ...cities];
  }

  List<Map<String, dynamic>> _getFilteredShops(List<Map<String, dynamic>> shops) {
    var filtered = shops.where((shop) {
      final matchesSearch = shop['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          shop['code'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          shop['location'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatus == 'All Status' || shop['status'] == _selectedStatus;
      final matchesCity = _selectedCity == 'All Cities' || shop['city'] == _selectedCity;
      return matchesSearch && matchesStatus && matchesCity;
    }).toList();

    filtered.sort((a, b) {
      var valA = (a[_sortField] ?? '').toString().toLowerCase();
      var valB = (b[_sortField] ?? '').toString().toLowerCase();
      return _sortAscending ? valA.compareTo(valB) : valB.compareTo(valA);
    });

    return filtered;
  }

  void _showAddEditDialog({Map<String, dynamic>? shop}) {
    final isEditing = shop != null;
    final nameController = TextEditingController(text: isEditing ? shop['name'] : '');
    final codeController = TextEditingController(text: isEditing ? shop['code'] : '');
    final locationController = TextEditingController(text: isEditing ? shop['location'] : '');
    final cityController = TextEditingController(text: isEditing ? shop['city'] : '');
    final contactController = TextEditingController(text: isEditing ? shop['contact'] : '');
    String status = isEditing ? shop['status'] : 'Active';
    bool isPrimary = isEditing ? shop['isPrimary'] : false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: Text(isEditing ? 'Edit Shop' : 'Add New Shop', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildDialogField('Shop Name', nameController)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDialogField('Shop Code', codeController)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildDialogField('Location', locationController)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDialogField('City', cityController)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDialogField(
                              'Contact', 
                              contactController,
                              maxLength: 10,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                const SizedBox(height: 8),
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: status,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                                      items: const [
                                        DropdownMenuItem(value: 'Active', child: Text('Active')),
                                        DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                                      ],
                                      onChanged: (v) {
                                        if (v != null) {
                                          setDialogState(() => status = v);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Theme(
                            data: ThemeData(unselectedWidgetColor: const Color(0xFF94A3B8)),
                            child: Checkbox(
                              value: isPrimary,
                              activeColor: const Color(0xFF22C55E),
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() => isPrimary = value);
                                }
                              },
                            ),
                          ),
                          const Text('Set as Main Shop (Primary)', style: TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, ),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (!isEditing) {
                        await ref.read(shopProvider.notifier).addShop(
                          name: nameController.text,
                          code: codeController.text,
                          address: locationController.text,
                          city: cityController.text,
                          contactNumber: contactController.text,
                          status: status,
                          isPrimary: isPrimary,
                        );
                        
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop added successfully!')));
                        }
                      } else {
                        // Editing is not yet supported in backend, just close
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Editing not supported by backend yet')));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save shop: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(isEditing ? 'Save Changes' : 'Add Shop', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            );
          }
        );
      },
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller, {int? maxLength, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            maxLength: maxLength,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              counterText: '', // hide the default char counter if maxLength is used
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color bgColor, Color iconColor, IconData icon, VoidCallback onTap, {bool isDesktop = true}) {
    Widget card = Material(
      color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: iconColor.withOpacity(0.5)),
              ],
            ),
            ),
          ),
        );
    return isDesktop ? Expanded(child: card) : SizedBox(width: 250, child: card);
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);

    return shopState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (shops) {
        final activeCount = shops.where((s) => s['status'] == 'Active').length;
        final inactiveCount = shops.length - activeCount;
        final citiesCount = shops.map((s) => s['city']).toSet().length;
        final _filteredShopsList = _getFilteredShops(shops);
        final _dynamicCitiesList = _getDynamicCities(shops);

        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
        // Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
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
                    child: const Icon(Icons.storefront, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Shops', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        Text('Manage your branch shops and their settings', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      final filename = 'shops_export_${DateTime.now().millisecondsSinceEpoch}';
                      try {
                        if (value == 'csv') {
                          await ExportService.exportToCSV(_filteredShopsList, filename);
                        } else if (value == 'excel') {
                          await ExportService.exportToExcel(_filteredShopsList, filename);
                        } else if (value == 'pdf') {
                          await ExportService.exportToPDF(_filteredShopsList, filename);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export successful!')));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'csv', child: Text('Export to CSV')),
                      const PopupMenuItem(value: 'excel', child: Text('Export to Excel')),
                      const PopupMenuItem(value: 'pdf', child: Text('Export to PDF')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.download, size: 18, color: Color(0xFF1E293B)),
                          SizedBox(width: 8),
                          Text('Export', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
            Row(
              children: [
                IconButton(
                  onPressed: () => ref.read(shopProvider.notifier).loadShops(),
                  icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New Shop', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Row
          LayoutBuilder(builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 800;
            return isDesktop
              ? Row(
                  children: [
                    _buildStatCard('${shops.length}', 'Total Shops', const Color(0xFFE8F5E9), const Color(0xFF22C55E), Icons.store, () {
                      setState(() {
                        _selectedStatus = 'All Status';
                        _selectedCity = 'All Cities';
                        _searchQuery = '';
                      });
                    }),
                    const SizedBox(width: 16),
                    _buildStatCard('$activeCount', 'Active Shops', const Color(0xFFE3F2FD), const Color(0xFF3B82F6), Icons.check_circle, () {
                      setState(() {
                        _selectedStatus = 'Active';
                        _selectedCity = 'All Cities';
                        _searchQuery = '';
                      });
                    }),
                    const SizedBox(width: 16),
                    _buildStatCard('$inactiveCount', 'Inactive Shop', const Color(0xFFFFF3E0), const Color(0xFFF97316), Icons.pause_circle, () {
                      setState(() {
                        _selectedStatus = 'Inactive';
                        _selectedCity = 'All Cities';
                        _searchQuery = '';
                      });
                    }),
                    const SizedBox(width: 16),
                    _buildStatCard('$citiesCount', 'Total Locations', const Color(0xFFF3E8FF), const Color(0xFFA855F7), Icons.location_on, () {
                      setState(() {
                        _selectedStatus = 'All Status';
                        _searchQuery = '';
                      });
                    }),
                  ],
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 1000),
                    child: Row(
                      children: [
                        _buildStatCard('${shops.length}', 'Total Shops', const Color(0xFFE8F5E9), const Color(0xFF22C55E), Icons.store, () {
                          setState(() {
                            _selectedStatus = 'All Status';
                            _selectedCity = 'All Cities';
                            _searchQuery = '';
                          });
                        }, isDesktop: false),
                        const SizedBox(width: 16),
                        _buildStatCard('$activeCount', 'Active Shops', const Color(0xFFE3F2FD), const Color(0xFF3B82F6), Icons.check_circle, () {
                          setState(() {
                            _selectedStatus = 'Active';
                            _selectedCity = 'All Cities';
                            _searchQuery = '';
                          });
                        }, isDesktop: false),
                        const SizedBox(width: 16),
                        _buildStatCard('$inactiveCount', 'Inactive Shop', const Color(0xFFFFF3E0), const Color(0xFFF97316), Icons.pause_circle, () {
                          setState(() {
                            _selectedStatus = 'Inactive';
                            _selectedCity = 'All Cities';
                            _searchQuery = '';
                          });
                        }, isDesktop: false),
                        const SizedBox(width: 16),
                        _buildStatCard('$citiesCount', 'Total Locations', const Color(0xFFF3E8FF), const Color(0xFFA855F7), Icons.location_on, () {
                          setState(() {
                            _selectedStatus = 'All Status';
                            _searchQuery = '';
                          });
                        }, isDesktop: false),
                      ],
                    ),
                  ),
                );
          }),
          const SizedBox(height: 24),

          // Filters Row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Search shop by name, code, location...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildDropdownFilter('All Status', ['All Status', 'Active', 'Inactive'], _selectedStatus, (val) => setState(() => _selectedStatus = val!)),
              const SizedBox(width: 16),
              _buildDropdownFilter('All Cities', _dynamicCitiesList, _selectedCity, (val) => setState(() => _selectedCity = val!)),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    if (_sortField == value) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortField = value;
                      _sortAscending = true;
                    }
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
                  const PopupMenuItem(value: 'code', child: Text('Sort by Code')),
                  const PopupMenuItem(value: 'city', child: Text('Sort by City')),
                  const PopupMenuItem(value: 'status', child: Text('Sort by Status')),
                ],
                child: OutlinedButton.icon(
                  onPressed: null, // Tap handled by PopupMenuButton
                  icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, color: const Color(0xFF1E293B), size: 16),
                  label: Text('Sort By: ${_sortField.toUpperCase()}', style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    disabledForegroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Data Table
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  LayoutBuilder(builder: (context, constraints) {
                    return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: 1000, maxWidth: constraints.maxWidth > 1000 ? constraints.maxWidth : 1000),
                          child: Column(
                            children: [
                              // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 30, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                        Expanded(flex: 3, child: Text('Shop Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                        Expanded(flex: 1, child: Text('Shop Code', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                        Expanded(flex: 2, child: Text('Location', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                        Expanded(flex: 1, child: Text('City', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                        Expanded(flex: 2, child: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                        Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                        SizedBox(width: 130, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  // Table Body
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredShopsList.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final shop = _filteredShopsList[index];
                        final isActive = shop['status'] == 'Active';
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(width: 30, child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13))),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(shop['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13)),
                                        if (shop['isPrimary'] == true) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFF22C55E), borderRadius: BorderRadius.circular(4)),
                                            child: const Text('Primary', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                     Text(shop['subtitle'] ?? 'SirfBill', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                                   ],
                                ),
                              ),
                              Expanded(flex: 1, child: Text(shop['code'], style: const TextStyle(color: Color(0xFF475569), fontSize: 13))),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Color(0xFF64748B), size: 14),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(shop['location'], style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13))),
                                  ],
                                ),
                              ),
                              Expanded(flex: 1, child: Text(shop['city'], style: const TextStyle(color: Color(0xFF475569), fontSize: 13))),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone, color: Color(0xFF64748B), size: 14),
                                    const SizedBox(width: 4),
                                    Text(shop['contact'], style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6, height: 6,
                                            decoration: BoxDecoration(color: isActive ? const Color(0xFF22C55E) : Colors.red, shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(shop['status'], style: TextStyle(color: isActive ? const Color(0xFF166534) : Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 130,
                                child: Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _showAddEditDialog(shop: shop),
                                      icon: const Icon(Icons.edit, size: 14, color: Color(0xFF1E293B)),
                                      label: const Text('Edit', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 32),
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      height: 32,
                                      width: 32,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.more_vert, size: 16, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
                  }),
                  // Pagination
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Showing 1 to ${_filteredShopsList.length} of ${shops.length} shops', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        Row(
                          children: [
                            _buildPaginationBtn(Icons.chevron_left, false),
                            const SizedBox(width: 8),
                            _buildPaginationBtn(null, true, text: '1'),
                            const SizedBox(width: 8),
                            _buildPaginationBtn(Icons.chevron_right, false),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          
          // Bottom Features Bar
          Row(
            children: [
              _buildFeatureInfo(Icons.storefront, 'Manage Multiple Shops', 'Handle multiple branches effortlessly'),
              _buildFeatureInfo(Icons.location_on, 'Track Inventory', 'View shop-wise stock and transfer items'),
              _buildFeatureInfo(Icons.people, 'Shop-wise Billing', 'Generate separate bills for each shop'),
              _buildFeatureInfo(Icons.bar_chart, 'Better Insights', 'Get shop-wise reports and analytics'),
            ],
          ),
        ],
        );
      },
    );
  }

  Widget _buildDropdownFilter(String hint, List<String> items, String value, Function(String?) onChanged) {
    return Expanded(
      flex: 1,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 18),
            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationBtn(IconData? icon, bool isActive, {String? text}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF22C55E) : Colors.white,
        border: Border.all(color: isActive ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 18, color: const Color(0xFF64748B))
            : Text(text!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildFeatureInfo(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF22C55E), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
