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
        
        title: const Text('Delete Shop'),
        content: Text('Are you sure you want to delete ${shop['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
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
              
              surfaceTintColor: Colors.transparent,
              title: Text(
                isEditing ? 'Edit Shop' : 'Add New Shop',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface,
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
                                Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: status,
                                      isExpanded: true,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 16,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface,
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
                              unselectedWidgetColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
                          Text(
                            'Set as Main Shop (Primary)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface,
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
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                    style: TextStyle(fontWeight: FontWeight.bold),
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
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
            style: TextStyle(fontSize: 12),
            decoration: InputDecoration(
              counterText:
                  '', // hide the default char counter if maxLength is used
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
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
            color: iconColor.withValues(alpha: 0.1),
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
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
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
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
      
      body: shopsAsync.when(
        skipLoadingOnReload: true,
        data: (shops) {
          final filteredShops = _getFilteredShops(shops);
          final cities = _getDynamicCities(shops);

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Shop Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
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
                          icon: Icon(Icons.refresh),
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
                            icon: Icon(Icons.add, size: 18),
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
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: TextField(
                            onChanged: (val) {
                              setState(() => _searchQuery = val);
                            },
                            style: TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search shops by name, code or location...',
                              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                              prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 18),
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
                        icon: Icon(Icons.download, size: 16),
                        label: const Text('Export', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          elevation: 0,
                          side: BorderSide(color: Theme.of(context).dividerColor),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Table
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
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
                              SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12))),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: Theme.of(context).dividerColor),

                        // Table Body
                        filteredShops.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(48.0),
                                child: Center(
                                  child: Text(
                                    'No shops found',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredShops.length,
                                  separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(context).dividerColor),
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
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Theme.of(context).colorScheme.onSurface,
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
                                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
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
                                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  shop['city'],
                                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              shop['contact']?.toString() ?? 'N/A',
                                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
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
                                                  icon: Icon(Icons.edit_outlined, size: 18),
                                                  color: const Color(0xFF3B82F6),
                                                  tooltip: 'Edit Shop',
                                                ),
                                                // IconButton(
                                                //   onPressed: () => _showDeleteDialog(context, shop),
                                                //   icon: Icon(Icons.delete_outline, size: 18),
                                                //   color: Colors.red,
                                                //   tooltip: 'Delete Shop',
                                                // ),
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
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 650,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
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
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
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
                            size: 48,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Multi-Branch Management',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We are designing a powerful new way for you to manage multiple\npharmacy branches from a single unified dashboard.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Soon, you will be able to designate a Main Branch, link Primary Branches, and\nsynchronize inventory, billing, and patient records seamlessly across all your locations.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.architecture,
                                size: 18,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Feature currently on the drawing board',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
          ));
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E))),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: Colors.red))),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              size: 18,
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
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
          color: isActive ? const Color(0xFF22C55E) : Theme.of(context).dividerColor,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))
            : Text(
                text!,
                style: TextStyle(
                  color: Theme.of(context).cardColor,
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
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.1),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
