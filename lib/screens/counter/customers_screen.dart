import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_pagination.dart';
import '../../services/customer_service.dart';
import '../../services/billing_service.dart';
import 'package:printing/printing.dart';
import '../../utils/pdf_generator.dart';
import '../../services/billing_history_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  Map<String, dynamic>? _selectedCustomer;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _activeCustomerTab = 0;
  List<Map<String, dynamic>> _allCustomers = [];
  String _searchQuery = '';
  String _selectedStatus = 'All Status';
  String _selectedCity = 'All Cities';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final realCustomers = await CustomerService.getCustomers();
    
    List<dynamic> historyList = [];
    try {
      final response = await BillingService.getPosHistory();
      historyList = response['history'] as List? ?? [];
    } catch (e) {
      // ignore
    }

    final List<Map<String, dynamic>> mappedRealCustomers = realCustomers.map((c) {
      final names = c.name.split(' ');
      final initials = names.length > 1 
          ? '${names[0][0]}${names[1][0]}'.toUpperCase() 
          : c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C';

      final custHistory = historyList.where((h) {
        if (c.phone.isNotEmpty && h['customer_phone'] == c.phone) return true;
        if (c.name.isNotEmpty && h['customer_name'] == c.name) return true;
        return false;
      }).toList();
      
      double totalPurchases = 0.0;
      DateTime? lastPurchaseDate;
      
      for (var h in custHistory) {
        totalPurchases += (h['amount'] as num?)?.toDouble() ?? 0.0;
        String dateStr = h['date'].toString();
        if (!dateStr.endsWith('Z')) dateStr += 'Z';
        final dt = DateTime.tryParse(dateStr)?.toLocal();
        if (dt != null) {
          if (lastPurchaseDate == null || dt.isAfter(lastPurchaseDate!)) {
            lastPurchaseDate = dt;
          }
        }
      }

      return {
        'full_id': c.id,
        'id': c.id.substring(c.id.length > 8 ? c.id.length - 8 : 0),
        'name': c.name,
        'initials': initials,
        'phone': c.phone,
        'email': c.email.isNotEmpty ? c.email : 'N/A',
        'city': c.location.isNotEmpty ? c.location : 'Local',
        'totalPurchases': totalPurchases,
        'bills': custHistory.length,
        'lastPurchase': lastPurchaseDate != null ? DateFormat('dd MMM yyyy').format(lastPurchaseDate!) : 'N/A',
        'status': c.isActive ? 'Active' : 'Inactive',
        'memberSince': c.createdAt != null ? DateFormat('MMM yyyy').format(DateTime.parse(c.createdAt!)) : 'Unknown',
        'history': custHistory,
      };
    }).toList();

    setState(() {
      _allCustomers = mappedRealCustomers;
      if (_selectedCustomer != null) {
        final updatedCust = mappedRealCustomers.where((c) => c['full_id'] == _selectedCustomer!['full_id']).firstOrNull;
        if (updatedCust != null) {
          _selectedCustomer = updatedCust;
        }
      }
    });
  }

  void _viewBill(SavedBill bill) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 800,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bill View - ${bill.invoiceNo}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PdfPreview(
                    build: (format) async {
                      return await PdfGenerator.generateBill(
                        items: bill.items,
                        subtotal: bill.subtotal,
                        discount: bill.discount,
                        tax: bill.tax,
                        grandTotal: bill.grandTotal,
                        invoiceNumber: bill.invoiceNo,
                        customerName: bill.customerName,
                        customerPhone: bill.customerPhone,
                        doctorName: bill.doctorName,
                        format: 'A4',
                      );
                    },
                    allowSharing: true,
                    allowPrinting: true,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person_add_alt_1, color: Color(0xFF166534), size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text('Add New Customer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
              const SizedBox(height: 24),
              _buildModernTextField(nameCtrl, 'Customer Name', Icons.person_outline),
              const SizedBox(height: 16),
              _buildModernTextField(phoneCtrl, 'Phone Number', Icons.phone_outlined, isNumber: true),
              const SizedBox(height: 16),
              _buildModernTextField(emailCtrl, 'Email Address', Icons.email_outlined),
              const SizedBox(height: 16),
              _buildModernTextField(locationCtrl, 'Location/City', Icons.location_on_outlined),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, ),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
                        return;
                      }
                      final newCust = Customer(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text,
                        phone: phoneCtrl.text,
                        email: emailCtrl.text,
                        location: locationCtrl.text,
                        isActive: true, // Defaults to true when adding
                      );
                      await CustomerService.saveCustomer(newCust);
                      if (context.mounted) {
                        Navigator.pop(context, );
                        _loadCustomers();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer Added Successfully!')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF166534),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save Customer', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditCustomerDialog(Map<String, dynamic> customerMap) {
    final nameCtrl = TextEditingController(text: customerMap['name']);
    final phoneCtrl = TextEditingController(text: customerMap['phone']);
    final emailCtrl = TextEditingController(text: customerMap['email'] == 'N/A' ? '' : customerMap['email']);
    final locationCtrl = TextEditingController(text: customerMap['city'] == 'Local' ? '' : customerMap['city']);
    bool isActive = customerMap['status'] == 'Active';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.edit_outlined, color: Color(0xFF0369A1), size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Text('Edit Customer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 24),
                _buildModernTextField(nameCtrl, 'Customer Name', Icons.person_outline),
                const SizedBox(height: 16),
                _buildModernTextField(phoneCtrl, 'Phone Number', Icons.phone_outlined, isNumber: true),
                const SizedBox(height: 16),
                _buildModernTextField(emailCtrl, 'Email Address', Icons.email_outlined),
                const SizedBox(height: 16),
                _buildModernTextField(locationCtrl, 'Location/City', Icons.location_on_outlined),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Active Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Switch(
                      value: isActive,
                      onChanged: (val) {
                        setDialogState(() {
                          isActive = val;
                        });
                      },
                      activeColor: const Color(0xFF0369A1),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
                          return;
                        }
                        final updatedCust = Customer(
                          id: customerMap['full_id'] ?? customerMap['id'], // We need the full UUID to update
                          name: nameCtrl.text,
                          phone: phoneCtrl.text,
                          email: emailCtrl.text,
                          location: locationCtrl.text,
                          isActive: isActive,
                        );
                        try {
                          await CustomerService.updateCustomer(updatedCust);
                        if (context.mounted) {
                          Navigator.pop(context);
                          _loadCustomers();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer Updated Successfully!')));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0369A1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5)),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final filteredCustomers = _allCustomers.where((c) {
      final matchesSearch = c['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            c['phone'].toString().contains(_searchQuery) ||
                            c['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatus == 'All Status' || c['status'] == _selectedStatus;
      final matchesCity = _selectedCity == 'All Cities' || c['city'] == _selectedCity;
      return matchesSearch && matchesStatus && matchesCity;
    }).toList();

    final totalRecords = filteredCustomers.length;
    final totalPages = (totalRecords / _itemsPerPage).ceil() == 0 ? 1 : (totalRecords / _itemsPerPage).ceil();
    final startIdx = (_currentPage - 1) * _itemsPerPage;
    final endIdx = (startIdx + _itemsPerPage > totalRecords) ? totalRecords : startIdx + _itemsPerPage;
    final pagedCustomers = filteredCustomers.isNotEmpty ? filteredCustomers.sublist(startIdx, endIdx) : <Map<String, dynamic>>[];

    return Container(
      color: const Color(0xFFF8FAFC), // Light gray background
      child: ListView(
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
                      color: const Color(0xFF166534), // Dark Green
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.people, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Customers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 4),
                        Text('Manage your customers, view purchase history and build better relationships', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            Row(
              children: [
                IconButton(
                  onPressed: () => _loadCustomers(),
                  icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showAddCustomerDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF166534),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            ],
          ),
          const SizedBox(height: 24),

          // Summary Cards
          LayoutBuilder(builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 800;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(width: isDesktop ? (constraints.maxWidth - 48) / 4 : 250, child: _buildStatCard('Total Customers', '${_allCustomers.length}', Icons.people, const Color(0xFFDCFCE7), const Color(0xFF166534))),
                  const SizedBox(width: 16),
                  SizedBox(width: isDesktop ? (constraints.maxWidth - 48) / 4 : 250, child: _buildStatCard('Active Customers', '${_allCustomers.length}', Icons.check_circle_outline, const Color(0xFFE0F2FE), const Color(0xFF0369A1))),
                  const SizedBox(width: 16),
                  SizedBox(width: isDesktop ? (constraints.maxWidth - 48) / 4 : 250, child: _buildStatCard('New This Month', '0', Icons.person_add_alt_1, const Color(0xFFFFEDD5), const Color(0xFFC2410C))),
                  const SizedBox(width: 16),
                  SizedBox(width: isDesktop ? (constraints.maxWidth - 48) / 4 : 250, child: _buildStatCard('Loyal Customers', '0', Icons.star, const Color(0xFFF3E8FF), const Color(0xFF7E22CE), subtitle: '(10+ purchases)')),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),

          // Main Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Table Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Filter Bar
                        LayoutBuilder(builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              width: constraints.maxWidth > 800 ? constraints.maxWidth : 800,
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: (val) => setState(() {
                                    _searchQuery = val;
                                    _currentPage = 1;
                                  }),
                                  decoration: InputDecoration(
                                    hintText: 'Search by name, phone, customer ID...',
                                    prefixIcon: const Icon(Icons.search, size: 20),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                  ),
                                  value: _selectedStatus,
                                  items: ['All Status', ..._allCustomers.map((e) => e['status'].toString()).toSet()]
                                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14))))
                                      .toList(),
                                  onChanged: (val) => setState(() {
                                    _selectedStatus = val!;
                                    _currentPage = 1;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                  ),
                                  value: _selectedCity,
                                  items: ['All Cities', ..._allCustomers.map((e) => e['city'].toString()).toSet()]
                                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14))))
                                      .toList(),
                                  onChanged: (val) => setState(() {
                                    _selectedCity = val!;
                                    _currentPage = 1;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _searchCtrl.clear();
                                    _searchQuery = '';
                                    _selectedStatus = 'All Status';
                                    _selectedCity = 'All Cities';
                                    _currentPage = 1;
                                  });
                                },
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Reset'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                                ],
                              ),
                            ),
                          );
                        }),
                        
                        LayoutBuilder(builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: 1000, maxWidth: constraints.maxWidth > 1000 ? constraints.maxWidth : 1000),
                              child: Column(
                                children: [
                                  // Table Header
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: const BoxDecoration(
                                        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 40, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)))),
                                          Expanded(flex: 3, child: const Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)))),
                                          Expanded(flex: 2, child: const Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)))),
                                          Expanded(flex: 2, child: const Text('City', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)))),
                                          Expanded(flex: 2, child: const Text('Total Purchases', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)))),
                                          Expanded(flex: 2, child: const Text('Last Purchase', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)))),
                                          Expanded(flex: 2, child: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)))),
                                          const SizedBox(width: 80, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)))),
                                        ],
                                      ),
                                    ),
                                    
                                    // Table Body
                                    pagedCustomers.isEmpty
                                      ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No customers found', style: TextStyle(color: Color(0xFF64748B)))))
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: pagedCustomers.length,
                                          itemBuilder: (context, index) {
                                            final customer = pagedCustomers[index];
                                            return _buildCustomerRow(customer, index);
                                          },
                                        ),
                                ],
                              ),
                            ),
                          );
                        }),
                        
                        // Pagination
                        if (totalRecords > 0) Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Showing ${startIdx + 1} to $endIdx of $totalRecords customers', style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                              CustomPagination(
                                currentPage: _currentPage,
                                totalPages: totalPages,
                                onPageChanged: (page) => setState(() => _currentPage = page),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Right Details Panel
                if (_selectedCustomer != null) ...[
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 320,
                    child: _buildCustomerDetailsPanel(_selectedCustomer!),
                  )
                ]
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color bgColor, Color iconColor, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ]
            ],
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildCustomerRow(Map<String, dynamic> customer, int index) {
    final isSelected = _selectedCustomer?['id'] == customer['id'];
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCustomer = customer;
          _activeCustomerTab = 0; // Reset to History tab when new customer selected
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            SizedBox(width: 40, child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _getAvatarColor(customer['initials']),
                    child: Text(customer['initials'], style: TextStyle(color: _getAvatarTextColor(customer['initials']), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(customer['id'], style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(customer['phone'], style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
            Expanded(flex: 2, child: Text(customer['city'], style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('₹ ${customer['totalPurchases'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${customer['bills']} bills', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(customer['lastPurchase'], style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
            Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: _buildStatusChip(customer['status']))),
            SizedBox(
              width: 80,
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCustomer = customer;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.visibility, size: 14, color: Color(0xFF1E293B)),
                        SizedBox(width: 4),
                        Text('View', style: TextStyle(fontSize: 11, color: Color(0xFF1E293B))),
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

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    if (status == 'Active') {
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF166534);
    } else if (status == 'Inactive') {
      bgColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFF991B1B);
    } else {
      bgColor = const Color(0xFFF3E8FF);
      textColor = const Color(0xFF7E22CE);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: textColor)),
          const SizedBox(width: 6),
          Text(status, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getAvatarColor(String initials) {
    if (initials == 'RD') return const Color(0xFFF3E8FF);
    if (initials == 'PS') return const Color(0xFFE0F2FE);
    if (initials == 'AM') return const Color(0xFFFFEDD5);
    if (initials == 'KM') return const Color(0xFFFEE2E2);
    return const Color(0xFFDCFCE7);
  }

  Color _getAvatarTextColor(String initials) {
    if (initials == 'RD') return const Color(0xFF7E22CE);
    if (initials == 'PS') return const Color(0xFF0369A1);
    if (initials == 'AM') return const Color(0xFFC2410C);
    if (initials == 'KM') return const Color(0xFF991B1B);
    return const Color(0xFF166534);
  }

  Widget _buildCustomerDetailsPanel(Map<String, dynamic> customer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _showEditCustomerDialog(customer),
                      child: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF0369A1)),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => setState(() => _selectedCustomer = null),
                      child: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          
          // Profile Info
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _getAvatarColor(customer['initials']),
                      child: Text(customer['initials'], style: TextStyle(color: _getAvatarTextColor(customer['initials']), fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(customer['id'], style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    _buildStatusChip(customer['status']),
                  ],
                ),
                const SizedBox(height: 24),
                _buildContactRow(Icons.phone, customer['phone']),
                const SizedBox(height: 12),
                _buildContactRow(Icons.email, customer['email']),
                const SizedBox(height: 12),
                _buildContactRow(Icons.location_on, customer['city']),
                const SizedBox(height: 12),
                _buildContactRow(Icons.calendar_today, 'Member since ${customer['memberSince']}'),
                
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 24),
                
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStat('${customer['bills']}', 'Total Bills'),
                    _buildMiniStat('₹ ${customer['totalPurchases'].toStringAsFixed(2)}', 'Total Purchase'),
                    _buildMiniStat(customer['lastPurchase'], 'Last Purchase'),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.go('/counter/billing');
                        },
                        icon: const Icon(Icons.receipt_long, size: 16),
                        label: const Text('New Bill'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF166534),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message sent to ${customer['phone']}')));
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF166534)),
                        label: const Text('Send Message', style: TextStyle(color: Color(0xFF166534))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF166534)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Tabs
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeCustomerTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: _activeCustomerTab == 0 ? const Color(0xFF166534) : Colors.transparent, width: 2)),
                      ),
                      child: Center(child: Text('Purchase History', style: TextStyle(color: _activeCustomerTab == 0 ? const Color(0xFF166534) : const Color(0xFF64748B), fontWeight: _activeCustomerTab == 0 ? FontWeight.bold : FontWeight.normal, fontSize: 13))),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeCustomerTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: _activeCustomerTab == 1 ? const Color(0xFF166534) : Colors.transparent, width: 2)),
                      ),
                      child: Center(child: Text('Notes', style: TextStyle(color: _activeCustomerTab == 1 ? const Color(0xFF166534) : const Color(0xFF64748B), fontWeight: _activeCustomerTab == 1 ? FontWeight.bold : FontWeight.normal, fontSize: 13))),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content Area
          Expanded(
            child: _activeCustomerTab == 0 
                ? LayoutBuilder(builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 500,
                          maxWidth: constraints.maxWidth > 500 ? constraints.maxWidth : 500,
                        ),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: const Color(0xFFF8FAFC),
                        child: Row(
                          children: const [
                            Expanded(flex: 2, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Bill No', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            SizedBox(width: 40),
                          ],
                        ),
                      ),
                      if (customer['bills'] > 0)
                        ...((customer['history'] as List).map((h) {
                          String dateStrRaw = h['date'].toString();
                          if (!dateStrRaw.endsWith('Z')) dateStrRaw += 'Z';
                          final date = DateTime.tryParse(dateStrRaw)?.toLocal();
                          final dateStr = date != null ? DateFormat('dd MMM yyyy').format(date) : h['date'].toString();
                          final amt = (h['amount'] as num?)?.toDouble() ?? 0.0;
                          return InkWell(
                            onTap: () {
                              final dt = date ?? DateTime.now();
                              final itemsList = (h['items_detail'] as List?)?.map((i) => Map<String, dynamic>.from(i)).toList() ?? [];
                              double calculatedSubtotal = 0.0;
                              for (var i in itemsList) {
                                calculatedSubtotal += ((i['price'] as num?)?.toDouble() ?? 0.0) * ((i['qty'] as num?)?.toInt() ?? 1);
                              }
                              double grandTotalVal = (h['amount'] as num?)?.toDouble() ?? 0.0;
                              double calculatedDiscount = calculatedSubtotal > grandTotalVal ? calculatedSubtotal - grandTotalVal : 0.0;

                              final bill = SavedBill(
                                id: h['id'].toString(),
                                invoiceNo: h['bill_no'].toString(),
                                customerName: h['customer_name']?.isEmpty ?? true ? 'Walk-in' : h['customer_name'],
                                customerPhone: h['customer_phone']?.toString() ?? '',
                                doctorName: '',
                                subtotal: calculatedSubtotal > 0 ? calculatedSubtotal : grandTotalVal,
                                discount: calculatedDiscount,
                                tax: 0.0,
                                grandTotal: grandTotalVal,
                                items: itemsList,
                                createdAt: dt,
                              );
                              _viewBill(bill);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: Text(dateStr, style: const TextStyle(fontSize: 12))),
                                  Expanded(flex: 2, child: Text(h['bill_no']?.toString() ?? 'N/A', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text('₹ ${amt.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                                  const SizedBox(width: 40, child: Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8))),
                                ],
                              ),
                            ),
                          );
                        }).toList())
                      else
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'No purchases found',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            })
                : const Center(
                    child: Text('No notes available for this customer.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  ),
          ),
          
          // View All Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              onPressed: () {
                context.go('/counter/history');
              },
              icon: const Icon(Icons.history, size: 16, color: Color(0xFF1E293B)),
              label: const Text('View All Purchases', style: TextStyle(color: Color(0xFF1E293B))),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
      ],
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildHistoryRow(String date, String billNo, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(date, style: const TextStyle(fontSize: 11))),
          Expanded(flex: 2, child: Text(billNo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(amount, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          SizedBox(
            width: 40,
            child: InkWell(
              onTap: () {},
              child: Row(
                children: const [
                  Icon(Icons.visibility, size: 12, color: Color(0xFF64748B)),
                  SizedBox(width: 2),
                  Text('View', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
