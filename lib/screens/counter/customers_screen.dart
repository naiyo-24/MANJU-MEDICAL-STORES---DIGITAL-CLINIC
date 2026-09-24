import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/counter_providers.dart';
import '../../themes/app_colors.dart';

import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_pagination.dart';
import '../../services/customer_service.dart';
import '../../services/billing_history_service.dart';

import 'widgets/customers/customer_stat_card.dart';
import 'widgets/customers/view_bill_dialog.dart';
import 'widgets/customers/customer_dialogs.dart';
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  Map<String, dynamic>? _selectedCustomer;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _activeCustomerTab = 0;
  
  String _searchQuery = '';
  String _selectedStatus = 'All Status';
  String _selectedCity = 'All Cities';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerProvider.notifier).loadCustomers();
    });
  }

  



  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerProvider);
    
    return customerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (allCustomers) {
        if (_selectedCustomer != null) {
          final updatedCust = allCustomers.where((c) => c['full_id'] == _selectedCustomer!['full_id']).firstOrNull;
          if (updatedCust != null && updatedCust != _selectedCustomer) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedCustomer = updatedCust);
            });
          }
        }

    final filteredCustomers = allCustomers.where((c) {
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
      color: AppColors.background, // Light gray background
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
                      color: AppColors.primaryDark, // Dark Green
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.people, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Customers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
                  onPressed: () => ref.read(customerProvider.notifier).loadCustomers(),
                  icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => showAddCustomerDialog(context, () => ref.read(customerProvider.notifier).loadCustomers()),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
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
                  SizedBox(width: isDesktop ? (constraints.maxWidth - 48) / 4 : 250, child: CustomerStatCard(title: 'Total Customers', value: '${allCustomers.length}', icon: Icons.people, bgColor: AppColors.primaryLight, iconColor: AppColors.primaryDark)),
                  const SizedBox(width: 16),
                  SizedBox(width: isDesktop ? (constraints.maxWidth - 48) / 4 : 250, child: CustomerStatCard(title: 'Active Customers', value: '${allCustomers.length}', icon: Icons.check_circle_outline, bgColor: AppColors.infoLight, iconColor: AppColors.info)),
                  const SizedBox(width: 16),
                  SizedBox(width: isDesktop ? (constraints.maxWidth - 48) / 4 : 250, child: CustomerStatCard(title: 'New This Month', value: '0', icon: Icons.person_add_alt_1, bgColor: AppColors.warningLight, iconColor: AppColors.warning)),
                  const SizedBox(width: 16),
                  SizedBox(width: isDesktop ? (constraints.maxWidth - 48) / 4 : 250, child: CustomerStatCard(title: 'Loyal Customers', value: '0', icon: Icons.star, bgColor: AppColors.secondaryLight, iconColor: AppColors.secondary, subtitle: '(10+ purchases)')),
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
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
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
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                  ),
                                  initialValue: _selectedStatus,
                                  items: ['All Status', ...allCustomers.map((e) => e['status'].toString()).toSet()]
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
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                  ),
                                  initialValue: _selectedCity,
                                  items: ['All Cities', ...allCustomers.map((e) => e['city'].toString()).toSet()]
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
                                        border: Border(bottom: BorderSide(color: AppColors.divider)),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 40, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                                          Expanded(flex: 3, child: const Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                                          Expanded(flex: 2, child: const Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                                          Expanded(flex: 2, child: const Text('City', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                                          Expanded(flex: 2, child: const Text('Total Purchases', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                                          Expanded(flex: 2, child: const Text('Last Purchase', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                                          Expanded(flex: 2, child: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                                          const SizedBox(width: 80, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary))),
                                        ],
                                      ),
                                    ),
                                    
                                    // Table Body
                                    pagedCustomers.isEmpty
                                      ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No customers found', style: TextStyle(color: AppColors.textSecondary))))
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
                              Text('Showing ${startIdx + 1} to $endIdx of $totalRecords customers', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
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
      },
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
          color: isSelected ? AppColors.primaryLight : Colors.white,
          border: const Border(bottom: BorderSide(color: AppColors.divider)),
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
                      Text(customer['id'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(customer['phone'], style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
            Expanded(flex: 2, child: Text(customer['city'], style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('₹ ${customer['totalPurchases'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${customer['bills']} bills', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(customer['lastPurchase'], style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
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
                        Icon(Icons.visibility, size: 14, color: AppColors.textPrimary),
                        SizedBox(width: 4),
                        Text('View', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
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
      bgColor = AppColors.primaryLight;
      textColor = AppColors.primaryDark;
    } else if (status == 'Inactive') {
      bgColor = AppColors.errorLight;
      textColor = AppColors.error;
    } else {
      bgColor = AppColors.secondaryLight;
      textColor = AppColors.secondary;
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
    if (initials == 'RD') return AppColors.secondaryLight;
    if (initials == 'PS') return AppColors.infoLight;
    if (initials == 'AM') return AppColors.warningLight;
    if (initials == 'KM') return AppColors.errorLight;
    return AppColors.primaryLight;
  }

  Color _getAvatarTextColor(String initials) {
    if (initials == 'RD') return AppColors.secondary;
    if (initials == 'PS') return AppColors.info;
    if (initials == 'AM') return AppColors.warning;
    if (initials == 'KM') return AppColors.error;
    return AppColors.primaryDark;
  }

  Widget _buildCustomerDetailsPanel(Map<String, dynamic> customer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
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
                      onTap: () => showEditCustomerDialog(context, customer, () => ref.read(customerProvider.notifier).loadCustomers()),
                      child: const Icon(Icons.edit_outlined, size: 20, color: AppColors.info),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => setState(() => _selectedCustomer = null),
                      child: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          
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
                          Text(customer['id'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                const Divider(height: 1, color: AppColors.divider),
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
                          backgroundColor: AppColors.primaryDark,
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
                        icon: const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.primaryDark),
                        label: const Text('Send Message', style: TextStyle(color: AppColors.primaryDark)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryDark),
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
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeCustomerTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: _activeCustomerTab == 0 ? AppColors.primaryDark : Colors.transparent, width: 2)),
                      ),
                      child: Center(child: Text('Purchase History', style: TextStyle(color: _activeCustomerTab == 0 ? AppColors.primaryDark : AppColors.textSecondary, fontWeight: _activeCustomerTab == 0 ? FontWeight.bold : FontWeight.normal, fontSize: 13))),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeCustomerTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: _activeCustomerTab == 1 ? AppColors.primaryDark : Colors.transparent, width: 2)),
                      ),
                      child: Center(child: Text('Notes', style: TextStyle(color: _activeCustomerTab == 1 ? AppColors.primaryDark : AppColors.textSecondary, fontWeight: _activeCustomerTab == 1 ? FontWeight.bold : FontWeight.normal, fontSize: 13))),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content Area
          _activeCustomerTab == 0 
              ? LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 500,
                        maxWidth: constraints.maxWidth > 500 ? constraints.maxWidth : 500,
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: AppColors.background,
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
                              showViewBillDialog(context, bill);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: Text(dateStr, style: const TextStyle(fontSize: 12))),
                                  Expanded(flex: 2, child: Text(h['bill_no']?.toString() ?? 'N/A', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text('₹ ${amt.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                                  const SizedBox(width: 40, child: Icon(Icons.chevron_right, size: 16, color: AppColors.textHint)),
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
                              style: TextStyle(color: AppColors.textHint, fontSize: 13),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            })
              : const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No notes available for this customer.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                ),
          
          // View All Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              onPressed: () {
                context.go('/counter/history');
              },
              icon: const Icon(Icons.history, size: 16, color: AppColors.textPrimary),
              label: const Text('View All Purchases', style: TextStyle(color: AppColors.textPrimary)),
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
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildHistoryRow(String date, String billNo, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
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
                  Icon(Icons.visibility, size: 12, color: AppColors.textSecondary),
                  SizedBox(width: 2),
                  Text('View', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
