import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/counter_providers.dart';
import '../../themes/app_colors.dart';

import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_pagination.dart';
import '../../services/customer_service.dart';

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
      skipLoadingOnReload: true,
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (allCustomers) {
        if (_selectedCustomer != null) {
          final updatedCust = allCustomers
              .where((c) => c['full_id'] == _selectedCustomer!['full_id'])
              .firstOrNull;
          if (updatedCust != null && updatedCust != _selectedCustomer) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedCustomer = updatedCust);
            });
          }
        }

        final filteredCustomers = allCustomers.where((c) {
          final matchesSearch =
              c['name'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              c['phone'].toString().contains(_searchQuery) ||
              c['id'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
          final matchesStatus =
              _selectedStatus == 'All Status' || c['status'] == _selectedStatus;
          final matchesCity =
              _selectedCity == 'All Cities' || c['city'] == _selectedCity;
          return matchesSearch && matchesStatus && matchesCity;
        }).toList();

        final totalRecords = filteredCustomers.length;
        final totalPages = (totalRecords / _itemsPerPage).ceil() == 0
            ? 1
            : (totalRecords / _itemsPerPage).ceil();
        final startIdx = (_currentPage - 1) * _itemsPerPage;
        final endIdx = (startIdx + _itemsPerPage > totalRecords)
            ? totalRecords
            : startIdx + _itemsPerPage;
        final pagedCustomers = filteredCustomers.isNotEmpty
            ? filteredCustomers.sublist(startIdx, endIdx)
            : <Map<String, dynamic>>[];

        return Container(
          color: Theme.of(context).colorScheme.surface, // Light gray background
          child: ListView(
            padding: EdgeInsets.all(24.0),
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark, // Dark Green
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customers',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Manage your customers, view purchase history and build better relationships',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () =>
                            ref.read(customerProvider.notifier).loadCustomers(),
                        icon: Icon(
                          Icons.refresh,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        tooltip: 'Refresh',
                      ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => showAddCustomerDialog(
                          context,
                          () => ref
                              .read(customerProvider.notifier)
                              .loadCustomers(),
                        ),
                        icon: Icon(Icons.add, size: 18),
                        label: Text('Add Customer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Summary Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isDesktop = constraints.maxWidth > 800;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(
                          width: isDesktop
                              ? (constraints.maxWidth - 48) / 4
                              : 250,
                          child: CustomerStatCard(
                            title: 'Total Customers',
                            value: '${allCustomers.length}',
                            icon: Icons.people,
                            bgColor: AppColors.primaryLight,
                            iconColor: AppColors.primaryDark,
                          ),
                        ),
                        SizedBox(width: 16),
                        SizedBox(
                          width: isDesktop
                              ? (constraints.maxWidth - 48) / 4
                              : 250,
                          child: CustomerStatCard(
                            title: 'Active Customers',
                            value: '${allCustomers.where((c) => c['status'] == 'Active').length}',
                            icon: Icons.check_circle_outline,
                            bgColor: AppColors.infoLight,
                            iconColor: AppColors.info,
                          ),
                        ),
                        SizedBox(width: 16),
                        SizedBox(
                          width: isDesktop
                              ? (constraints.maxWidth - 48) / 4
                              : 250,
                          child: CustomerStatCard(
                            title: 'New This Month',
                            value: '${allCustomers.where((c) {
                              if (c['raw_created_at'] == null) return false;
                              try {
                                final dt = DateTime.parse(c['raw_created_at']).toLocal();
                                final now = DateTime.now();
                                return dt.month == now.month && dt.year == now.year;
                              } catch(e) { return false; }
                            }).length}',
                            icon: Icons.person_add_alt_1,
                            bgColor: AppColors.warningLight,
                            iconColor: AppColors.warning,
                          ),
                        ),
                        SizedBox(width: 16),
                        SizedBox(
                          width: isDesktop
                              ? (constraints.maxWidth - 48) / 4
                              : 250,
                          child: CustomerStatCard(
                            title: 'Loyal Customers',
                            value: '${allCustomers.where((c) => (c['bills'] ?? 0) >= 10).length}',
                            icon: Icons.star,
                            bgColor: AppColors.secondaryLight,
                            iconColor: AppColors.secondary,
                            subtitle: '(10+ purchases)',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 24),

              // Main Content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Table Area
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Filter Bar
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Container(
                                  width: constraints.maxWidth > 800
                                      ? constraints.maxWidth
                                      : 800,
                                  padding: EdgeInsets.all(16.0),
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
                                            hintText:
                                                'Search by name, phone, customer ID...',
                                            prefixIcon: Icon(
                                              Icons.search,
                                              size: 20,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Theme.of(context).dividerColor,
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 0,
                                                  horizontal: 16,
                                                ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        flex: 1,
                                        child: DropdownButtonFormField<String>(
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Theme.of(context).dividerColor,
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 0,
                                                  horizontal: 12,
                                                ),
                                          ),
                                          initialValue: _selectedStatus,
                                          items:
                                              [
                                                    'All Status',
                                                    ...allCustomers
                                                        .map(
                                                          (e) => e['status']
                                                              .toString(),
                                                        )
                                                        .toSet(),
                                                  ]
                                                  .map(
                                                    (s) => DropdownMenuItem(
                                                      value: s,
                                                      child: Text(
                                                        s,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                          onChanged: (val) => setState(() {
                                            _selectedStatus = val!;
                                            _currentPage = 1;
                                          }),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        flex: 1,
                                        child: DropdownButtonFormField<String>(
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Theme.of(context).dividerColor,
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 0,
                                                  horizontal: 12,
                                                ),
                                          ),
                                          initialValue: _selectedCity,
                                          items:
                                              [
                                                    'All Cities',
                                                    ...allCustomers
                                                        .map(
                                                          (e) => e['city']
                                                              .toString(),
                                                        )
                                                        .toSet(),
                                                  ]
                                                  .map(
                                                    (s) => DropdownMenuItem(
                                                      value: s,
                                                      child: Text(
                                                        s,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                          onChanged: (val) => setState(() {
                                            _selectedCity = val!;
                                            _currentPage = 1;
                                          }),
                                        ),
                                      ),
                                      SizedBox(width: 12),
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
                                        icon: Icon(
                                          Icons.refresh,
                                          size: 18,
                                        ),
                                        label: Text('Reset'),
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: 1000,
                                    maxWidth: constraints.maxWidth > 1000
                                        ? constraints.maxWidth
                                        : 1000,
                                  ),
                                  child: Column(
                                    children: [
                                      // Table Header
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Theme.of(context).dividerColor,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 40,
                                              child: Text(
                                                '#',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color:
                                                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                'Customer Name',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color:
                                                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Phone',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color:
                                                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'City',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color:
                                                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Total Purchases',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color:
                                                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Last Purchase',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color:
                                                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Status',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color:
                                                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 120,
                                              child: Text(
                                                'Action',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color:
                                                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Table Body
                                      pagedCustomers.isEmpty
                                          ? Padding(
                                              padding: EdgeInsets.all(32),
                                              child: Center(
                                                child: Text(
                                                  'No customers found',
                                                  style: TextStyle(
                                                    color:
                                                        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount: pagedCustomers.length,
                                              itemBuilder: (context, index) {
                                                final customer =
                                                    pagedCustomers[index];
                                                return _buildCustomerRow(
                                                  customer,
                                                  index,
                                                );
                                              },
                                            ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Pagination
                          if (totalRecords > 0)
                            Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Showing ${startIdx + 1} to $endIdx of $totalRecords customers',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                  CustomPagination(
                                    currentPage: _currentPage,
                                    totalPages: totalPages,
                                    onPageChanged: (page) =>
                                        setState(() => _currentPage = page),
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
                    SizedBox(width: 24),
                    SizedBox(
                      width: 320,
                      child: _buildCustomerDetailsPanel(_selectedCustomer!),
                    ),
                  ],
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
          _activeCustomerTab =
              0; // Reset to History tab when new customer selected
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _getAvatarColor(customer['initials']),
                    child: Text(
                      customer['initials'],
                      style: TextStyle(
                        color: _getAvatarTextColor(customer['initials']),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        customer['id'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                customer['phone'],
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                customer['city'],
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹ ${customer['totalPurchases'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${customer['bills']} bills',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                customer['lastPurchase'],
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildStatusChip(customer['status']),
              ),
            ),
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCustomer = customer;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'View',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _deleteCustomer(customer['full_id']),
                    icon: Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Delete Customer',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCustomer(String customerId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Customer'),
          content: Text('Are you sure you want to delete this customer? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await CustomerService.deleteCustomer(customerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer deleted successfully')),
          );
          if (_selectedCustomer?['full_id'] == customerId) {
            setState(() {
              _selectedCustomer = null;
            });
          }
          ref.read(customerProvider.notifier).loadCustomers();
        }
      } catch (e) {
        if (mounted) {
          final errorMessage = e.toString().replaceAll('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    }
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: textColor),
          ),
          SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () => showEditCustomerDialog(
                        context,
                        customer,
                        () =>
                            ref.read(customerProvider.notifier).loadCustomers(),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppColors.info,
                      ),
                    ),
                    SizedBox(width: 16),
                    InkWell(
                      onTap: () => setState(() => _selectedCustomer = null),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),

          // Profile Info
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _getAvatarColor(customer['initials']),
                      child: Text(
                        customer['initials'],
                        style: TextStyle(
                          color: _getAvatarTextColor(customer['initials']),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            customer['id'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(customer['status']),
                  ],
                ),
                SizedBox(height: 24),
                _buildContactRow(Icons.phone, customer['phone']),
                SizedBox(height: 12),
                _buildContactRow(Icons.email, customer['email']),
                SizedBox(height: 12),
                _buildContactRow(Icons.location_on, customer['city']),
                SizedBox(height: 12),
                _buildContactRow(
                  Icons.calendar_today,
                  'Member since ${customer['memberSince']}',
                ),

                SizedBox(height: 24),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                SizedBox(height: 24),

                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStat('${customer['bills']}', 'Total Bills'),
                    _buildMiniStat(
                      '₹ ${customer['totalPurchases'].toStringAsFixed(2)}',
                      'Total Purchase',
                    ),
                    _buildMiniStat(customer['lastPurchase'], 'Last Purchase'),
                  ],
                ),

                SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.go('/counter/billing');
                        },
                        icon: Icon(Icons.receipt_long, size: 16),
                        label: Text('New Bill'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Message sent to ${customer['phone']}',
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                          color: AppColors.primaryDark,
                        ),
                        label: Text(
                          'Send Message',
                          style: TextStyle(color: AppColors.primaryDark),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primaryDark),
                          padding: EdgeInsets.symmetric(vertical: 12),
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

          // Tabs
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeCustomerTab = 0),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeCustomerTab == 0
                                ? AppColors.primaryDark
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Purchase History',
                          style: TextStyle(
                            color: _activeCustomerTab == 0
                                ? AppColors.primaryDark
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: _activeCustomerTab == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeCustomerTab = 1),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeCustomerTab == 1
                                ? AppColors.primaryDark
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Notes',
                          style: TextStyle(
                            color: _activeCustomerTab == 1
                                ? AppColors.primaryDark
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: _activeCustomerTab == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          _activeCustomerTab == 0
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 500,
                          maxWidth: constraints.maxWidth > 500
                              ? constraints.maxWidth
                              : 500,
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              color: Theme.of(context).colorScheme.surface,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Date',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Bill No',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Amount',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 40),
                                ],
                              ),
                            ),
                            if (customer['bills'] > 0)
                              ...((customer['history'] as List).map((h) {
                                String dateStrRaw = h['date'].toString();
                                if (!dateStrRaw.endsWith('Z')) {
                                  dateStrRaw += 'Z';
                                }
                                final date = DateTime.tryParse(
                                  dateStrRaw,
                                )?.toLocal();
                                final dateStr = date != null
                                    ? DateFormat('dd MMM yyyy').format(date)
                                    : h['date'].toString();
                                final amt =
                                    (h['amount'] as num?)?.toDouble() ?? 0.0;
                                return InkWell(
                                  onTap: () {
                                    final dt = date ?? DateTime.now();
                                    final itemsList =
                                        (h['items_detail'] as List?)
                                            ?.map(
                                              (i) =>
                                                  Map<String, dynamic>.from(i),
                                            )
                                            .toList() ??
                                        [];
                                    double calculatedSubtotal = 0.0;
                                    for (var i in itemsList) {
                                      calculatedSubtotal +=
                                          ((i['price'] as num?)?.toDouble() ??
                                              0.0) *
                                          ((i['qty'] as num?)?.toInt() ?? 1);
                                    }
                                    double grandTotalVal =
                                        (h['amount'] as num?)?.toDouble() ??
                                        0.0;
                                    double calculatedDiscount =
                                        calculatedSubtotal > grandTotalVal
                                        ? calculatedSubtotal - grandTotalVal
                                        : 0.0;

                                    final bill = SavedBill(
                                      id: h['id'].toString(),
                                      invoiceNo: h['bill_no'].toString(),
                                      customerName:
                                          h['customer_name']?.isEmpty ?? true
                                          ? 'Walk-in'
                                          : h['customer_name'],
                                      customerPhone:
                                          h['customer_phone']?.toString() ?? '',
                                      doctorName: '',
                                      subtotal: calculatedSubtotal > 0
                                          ? calculatedSubtotal
                                          : grandTotalVal,
                                      discount: calculatedDiscount,
                                      tax: 0.0,
                                      grandTotal: grandTotalVal,
                                      items: itemsList,
                                      createdAt: dt,
                                    );
                                    showViewBillDialog(context, bill, ref.read(settingsProvider).value ?? {});
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            dateStr,
                                            style: TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            h['bill_no']?.toString() ?? 'N/A',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '₹ ${amt.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 40,
                                          child: Icon(
                                            Icons.chevron_right,
                                            size: 16,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList())
                            else
                              Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(
                                  child: Text(
                                    'No purchases found',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No notes available for this customer.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

          // View All Button
          Padding(
            padding: EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              onPressed: () {
                context.go('/counter/history');
              },
              icon: Icon(
                Icons.history,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              label: Text(
                'View All Purchases',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildHistoryRow(String date, String billNo, String amount) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(date, style: TextStyle(fontSize: 11)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              billNo,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 40,
            child: InkWell(
              onTap: () {},
              child: Row(
                children: [
                  Icon(
                    Icons.visibility,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  SizedBox(width: 2),
                  Text(
                    'View',
                    style: TextStyle(
                      fontSize: 9,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
