import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/export_service.dart';
import '../../providers/counter_providers.dart';

class ShopManagementScreen extends ConsumerStatefulWidget {
  const ShopManagementScreen({super.key});

  @override
  ConsumerState<ShopManagementScreen> createState() =>
      _ShopManagementScreenState();
}

class _ShopManagementScreenState extends ConsumerState<ShopManagementScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'All Status';
  String _selectedCity = 'All Cities';
  // ignore: unused_field
  final bool _isLoading = true;
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

  List<Map<String, dynamic>> _getFilteredShops(
    List<Map<String, dynamic>> shops,
  ) {
    var filtered = shops.where((shop) {
      final matchesSearch =
          shop['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          shop['code'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          shop['location'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      final matchesStatus =
          _selectedStatus == 'All Status' || shop['status'] == _selectedStatus;
      final matchesCity =
          _selectedCity == 'All Cities' || shop['city'] == _selectedCity;
      return matchesSearch && matchesStatus && matchesCity;
    }).toList();

    filtered.sort((a, b) {
      var valA = (a[_sortField] ?? '').toString().toLowerCase();
      var valB = (b[_sortField] ?? '').toString().toLowerCase();
      return _sortAscending ? valA.compareTo(valB) : valB.compareTo(valA);
    });

    return filtered;
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> shop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Shop'),
        content: Text('Are you sure you want to delete ${shop['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(shopProvider.notifier).deleteShop(shop['id']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shop deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete shop: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog({Map<String, dynamic>? shop}) {
    final isEditing = shop != null;
    final nameController = TextEditingController(
      text: isEditing ? shop['name'] : '',
    );
    final codeController = TextEditingController(
      text: isEditing ? shop['code'] : '',
    );
    final locationController = TextEditingController(
      text: isEditing ? shop['location'] : '',
    );
    final cityController = TextEditingController(
      text: isEditing ? shop['city'] : '',
    );
    final contactController = TextEditingController(
      text: isEditing ? shop['contact'] : '',
    );
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
              title: Text(
                isEditing ? 'Edit Shop' : 'Add New Shop',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1E293B),
                ),
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDialogField(
                              'Shop Name',
                              nameController,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDialogField(
                              'Shop Code',
                              codeController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDialogField(
                              'Location',
                              locationController,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDialogField('City', cityController),
                          ),
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
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: status,
                                      isExpanded: true,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 16,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF1E293B),
                                      ),
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
                            data: ThemeData(
                              unselectedWidgetColor: const Color(0xFF94A3B8),
                            ),
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
                          const Text(
                            'Set as Main Shop (Primary)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (!isEditing) {
                        await ref
                            .read(shopProvider.notifier)
                            .addShop(
                              name: nameController.text,
                              code: codeController.text,
                              address: locationController.text,
                              city: cityController.text,
                              contactNumber: contactController.text,
                              status: status,
                              isPrimary: isPrimary,
                            );

                        if (mounted) {
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Shop added successfully!'),
                            ),
                          );
                        }
                      } else {
                        // Call updateShop in shopProvider
                        await ref
                            .read(shopProvider.notifier)
                            .updateShop(
                              id: shop!['id'],
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Shop updated successfully!'),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save shop: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Add Shop',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogField(
    String label,
    TextEditingController controller, {
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
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
              counterText:
                  '', // hide the default char counter if maxLength is used
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    Color bgColor,
    Color iconColor,
    IconData icon,
    VoidCallback onTap, {
    bool isDesktop = true,
  }) {
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
                          Text(
                            value,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: iconColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
    return isDesktop
        ? Expanded(child: card)
        : SizedBox(width: 250, child: card);
  }

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(shopProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: shopsAsync.when(
        data: (shops) {
          final filteredShops = _getFilteredShops(shops);
          final cities = _getDynamicCities(shops);

          return Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Shop Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            ref.invalidate(shopProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Shop list refreshed!'), duration: Duration(seconds: 1)),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh Shops',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            foregroundColor: const Color(0xFF166534),
                          ),
                        ),
                        if (shops.isEmpty) ...[
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showAddEditDialog(),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Shop', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats
                Row(
                  children: [
                    _buildStatCard(
                      shops.length.toString(),
                      'Total Branches',
                      const Color(0xFFE8F5E9),
                      const Color(0xFF22C55E),
                      Icons.storefront,
                      () {},
                      isDesktop: !isMobile,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      shops.where((s) => s['status'] == 'Active').length.toString(),
                      'Active',
                      const Color(0xFFEFF6FF),
                      const Color(0xFF3B82F6),
                      Icons.check_circle_outline,
                      () {},
                      isDesktop: !isMobile,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      shops.where((s) => s['status'] == 'Inactive').length.toString(),
                      'Inactive',
                      const Color(0xFFFEF2F2),
                      const Color(0xFFEF4444),
                      Icons.cancel_outlined,
                      () {},
                      isDesktop: !isMobile,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Filters
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
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
                            onChanged: (val) {
                              setState(() => _searchQuery = val);
                            },
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Search shops by name, code or location...',
                              hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                              prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildDropdownFilter(
                        'Status',
                        ['All Status', 'Active', 'Inactive'],
                        _selectedStatus,
                        (val) => setState(() => _selectedStatus = val!),
                      ),
                      const SizedBox(width: 16),
                      _buildDropdownFilter(
                        'City',
                        cities,
                        _selectedCity,
                        (val) => setState(() => _selectedCity = val!),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                           ExportService.exportToCSV(
                            filteredShops,
                            'shops_export.csv'
                          );
                        },
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Export', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E293B),
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Table
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildSortableHeader('Shop Details', 'name', 2),
                              _buildSortableHeader('Location', 'location', 2),
                              _buildSortableHeader('Contact', 'contact', 1),
                              _buildSortableHeader('Status', 'status', 1),
                              const SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),

                        // Table Body
                        Expanded(
                          child: filteredShops.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No shops found',
                                    style: TextStyle(color: Color(0xFF94A3B8)),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: filteredShops.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                  itemBuilder: (context, index) {
                                    final shop = filteredShops[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      shop['name'],
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF1E293B),
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    if (shop['isPrimary'] == true) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFFEF3C7),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: const Text(
                                                          'MAIN',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFFD97706),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Code: ${shop['code']}',
                                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  shop['location'],
                                                  style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  shop['city'],
                                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              shop['contact']?.toString() ?? 'N/A',
                                              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: shop['status'] == 'Active'
                                                      ? const Color(0xFFDCFCE7)
                                                      : const Color(0xFFFEE2E2),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  shop['status'] ?? 'Unknown',
                                                  style: TextStyle(
                                                    color: shop['status'] == 'Active'
                                                        ? const Color(0xFF166534)
                                                        : const Color(0xFF991B1B),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 100,
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  onPressed: () => _showAddEditDialog(shop: shop),
                                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                                  color: const Color(0xFF3B82F6),
                                                  tooltip: 'Edit Shop',
                                                ),
                                                IconButton(
                                                  onPressed: () => _showDeleteDialog(context, shop),
                                                  icon: const Icon(Icons.delete_outline, size: 18),
                                                  color: Colors.red,
                                                  tooltip: 'Delete Shop',
                                                ),
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
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 650,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.2),
                                blurRadius: 50,
                                spreadRadius: 15,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.hub,
                            size: 64,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'Multi-Branch Management',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'We are designing a powerful new way for you to manage multiple\npharmacy branches from a single unified dashboard.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF475569),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Soon, you will be able to designate a Main Branch, link Primary Branches, and\nsynchronize inventory, billing, and patient records seamlessly across all your locations.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.architecture,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Feature currently on the drawing board',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E))),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildSortableHeader(String title, String field, int flex) {
    bool isSorted = _sortField == field;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () {
          setState(() {
            if (_sortField == field) {
              _sortAscending = !_sortAscending;
            } else {
              _sortField = field;
              _sortAscending = true;
            }
          });
        },
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
            if (isSorted) ...[
              const SizedBox(width: 4),
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: const Color(0xFF22C55E),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildDropdownFilter(
    String hint,
    List<String> items,
    String value,
    Function(String?) onChanged,
  ) {
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
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF64748B),
              size: 18,
            ),
            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
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
        border: Border.all(
          color: isActive ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 18, color: const Color(0xFF64748B))
            : Text(
                text!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
