import 'package:flutter/material.dart';

class ShopManagementScreen extends StatefulWidget {
  const ShopManagementScreen({super.key});

  @override
  State<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'All Status';
  String _selectedCity = 'All Cities';

  final List<Map<String, dynamic>> _shops = [
    {
      'id': 1,
      'name': 'Main Branch',
      'isPrimary': true,
      'subtitle': 'Manju Medical Stores',
      'code': 'SHOP001',
      'location': 'G.T. Road',
      'city': 'Kolkata',
      'contact': '+91 98765 43210',
      'status': 'Active',
    },
    {
      'id': 2,
      'name': 'Salt Lake Branch',
      'isPrimary': false,
      'subtitle': 'Manju Medical Stores',
      'code': 'SHOP002',
      'location': 'Salt Lake Sector V',
      'city': 'Kolkata',
      'contact': '+91 98765 43211',
      'status': 'Active',
    },
    {
      'id': 3,
      'name': 'Howrah Branch',
      'isPrimary': false,
      'subtitle': 'Manju Medical Stores',
      'code': 'SHOP003',
      'location': 'Howrah Station Road',
      'city': 'Howrah',
      'contact': '+91 98765 43212',
      'status': 'Inactive',
    },
  ];

  List<Map<String, dynamic>> get _filteredShops {
    return _shops.where((shop) {
      final matchesSearch = shop['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          shop['code'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          shop['location'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatus == 'All Status' || shop['status'] == _selectedStatus;
      final matchesCity = _selectedCity == 'All Cities' || shop['city'] == _selectedCity;
      return matchesSearch && matchesStatus && matchesCity;
    }).toList();
  }

  void _showAddEditDialog({Map<String, dynamic>? shop}) {
    final isEditing = shop != null;
    final nameController = TextEditingController(text: isEditing ? shop['name'] : '');
    final codeController = TextEditingController(text: isEditing ? shop['code'] : '');
    final locationController = TextEditingController(text: isEditing ? shop['location'] : '');
    final cityController = TextEditingController(text: isEditing ? shop['city'] : '');
    final contactController = TextEditingController(text: isEditing ? shop['contact'] : '');
    String status = isEditing ? shop['status'] : 'Active';

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
                          Expanded(child: _buildDialogField('Contact', contactController)),
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
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (isEditing) {
                        final index = _shops.indexWhere((s) => s['id'] == shop['id']);
                        if (index >= 0) {
                          _shops[index] = {
                            ..._shops[index],
                            'name': nameController.text,
                            'code': codeController.text,
                            'location': locationController.text,
                            'city': cityController.text,
                            'contact': contactController.text,
                            'status': status,
                          };
                        }
                      } else {
                        _shops.add({
                          'id': DateTime.now().millisecondsSinceEpoch,
                          'name': nameController.text,
                          'isPrimary': false,
                          'subtitle': 'Manju Medical Stores',
                          'code': codeController.text,
                          'location': locationController.text,
                          'city': cityController.text,
                          'contact': contactController.text,
                          'status': status,
                        });
                      }
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Shop updated successfully!' : 'Shop added successfully!')));
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

  Widget _buildDialogField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
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

  Widget _buildStatCard(String value, String label, Color bgColor, Color iconColor, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                  ],
                ),
              ],
            ),
            Icon(Icons.chevron_right, color: iconColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _shops.where((s) => s['status'] == 'Active').length;
    final inactiveCount = _shops.length - activeCount;
    final citiesCount = _shops.map((s) => s['city']).toSet().length;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Shops', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      Text('Manage your branch shops and their settings', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
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
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              _buildStatCard('${_shops.length}', 'Total Shops', const Color(0xFFE8F5E9), const Color(0xFF22C55E), Icons.store),
              const SizedBox(width: 16),
              _buildStatCard('$activeCount', 'Active Shops', const Color(0xFFE3F2FD), const Color(0xFF3B82F6), Icons.check_circle),
              const SizedBox(width: 16),
              _buildStatCard('$inactiveCount', 'Inactive Shop', const Color(0xFFFFF3E0), const Color(0xFFF97316), Icons.pause_circle),
              const SizedBox(width: 16),
              _buildStatCard('$citiesCount', 'Total Locations', const Color(0xFFF3E8FF), const Color(0xFFA855F7), Icons.location_on),
            ],
          ),
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
              _buildDropdownFilter('All Cities', ['All Cities', 'Kolkata', 'Howrah'], _selectedCity, (val) => setState(() => _selectedCity = val!)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.sort, color: Color(0xFF1E293B), size: 16),
                label: const Text('Sort By', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Data Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
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
                  Expanded(
                    child: ListView.separated(
                      itemCount: _filteredShops.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final shop = _filteredShops[index];
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
                                    const SizedBox(height: 2),
                                    Text(shop['subtitle'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
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
                  ),
                  // Pagination
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Showing 1 to ${_filteredShops.length} of ${_shops.length} shops', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
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
      ),
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
