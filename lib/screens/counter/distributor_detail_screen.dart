import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/distributor_provider.dart';
import '../../providers/counter_providers.dart';
import '../../config/api_constants.dart';
import 'package:go_router/go_router.dart';

class DistributorDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> distributor;
  const DistributorDetailScreen({super.key, required this.distributor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(distributorAnalyticsProvider(distributor['id']));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final secondaryTextColor = isDark ? Colors.grey[400] : const Color(0xFF64748B);
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(distributor['name'] ?? 'Distributor Details', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor)),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryTextColor),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(purchaseBillsProvider);
              ref.invalidate(distributorAnalyticsProvider(distributor['id']));
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: cardBorder, height: 1),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Card(
                  color: Theme.of(context).cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: cardBorder),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: isDark
                                    ? const Color(0xFF14532D).withValues(alpha: 0.3)
                                    : const Color(0xFFE8F5E9),
                                child: const Icon(Icons.business, color: Color(0xFF166534), size: 32),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      distributor['name'] ?? 'N/A',
                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryTextColor),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Contact Person: ${distributor['contact_person'] ?? 'N/A'}', style: TextStyle(color: secondaryTextColor)),
                                    const SizedBox(height: 4),
                                    Text('Phone: ${distributor['phone'] ?? 'N/A'}', style: TextStyle(color: secondaryTextColor)),
                                    const SizedBox(height: 4),
                                    Text('Email: ${distributor['email'] ?? 'N/A'}', style: TextStyle(color: secondaryTextColor)),
                                    const SizedBox(height: 4),
                                    Text('Address: ${distributor['address'] ?? 'N/A'}', style: TextStyle(color: secondaryTextColor)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'GSTIN: ${distributor['gstin'] ?? 'N/A'}',
                                      style: TextStyle(fontWeight: FontWeight.w600, color: primaryTextColor),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      context.push('/counter/distributors/purchase', extra: distributor);
                                    },
                                    icon: const Icon(Icons.add, color: Colors.white, size: 16),
                                    label: const Text('New Purchase Bill', style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B82F6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: isDark
                                        ? const Color(0xFF14532D).withValues(alpha: 0.3)
                                        : const Color(0xFFE8F5E9),
                                    child: const Icon(Icons.business, color: Color(0xFF166534), size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          distributor['name'] ?? 'N/A',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'GSTIN: ${distributor['gstin'] ?? 'N/A'}',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryTextColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Divider(color: cardBorder, height: 1),
                              const SizedBox(height: 12),
                              if (distributor['contact_person'] != null && distributor['contact_person'].toString().isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(Icons.person_outline, size: 16, color: secondaryTextColor),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('Contact: ${distributor['contact_person']}', style: TextStyle(fontSize: 13, color: secondaryTextColor))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                              Row(
                                children: [
                                  Icon(Icons.phone_outlined, size: 16, color: secondaryTextColor),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('Phone: ${distributor['phone'] ?? 'N/A'}', style: TextStyle(fontSize: 13, color: secondaryTextColor))),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.email_outlined, size: 16, color: secondaryTextColor),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('Email: ${distributor['email'] ?? 'N/A'}', style: TextStyle(fontSize: 13, color: secondaryTextColor))),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.location_on_outlined, size: 16, color: secondaryTextColor),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('Address: ${distributor['address'] ?? 'N/A'}', style: TextStyle(fontSize: 13, color: secondaryTextColor))),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.push('/counter/distributors/purchase', extra: distributor);
                                  },
                                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                                  label: const Text('New Purchase Bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Analytics Section
                Text(
                  'Sales Analytics (Top 5 Medicines)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
                ),
                const SizedBox(height: 16),
                analyticsAsync.when(
                  data: (analytics) {
                    final topItems = analytics['top_selling_medicines'] as List<dynamic>? ?? [];
                    
                    final revenueCard = Card(
                      color: isDark ? const Color(0xFF14532D).withValues(alpha: 0.25) : const Color(0xFFE8F5E9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? const Color(0xFF166534).withValues(alpha: 0.5) : const Color(0xFF86EFAC)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isDesktop ? 20.0 : 14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Revenue Generated',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
                                fontWeight: FontWeight.w600,
                                fontSize: isDesktop ? 14 : 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${analytics['total_revenue_generated'] ?? 0.0}',
                              style: TextStyle(
                                fontSize: isDesktop ? 28 : 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    final itemsSoldCard = Card(
                      color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.25) : const Color(0xFFEFF6FF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? const Color(0xFF2563EB).withValues(alpha: 0.5) : const Color(0xFFBFDBFE)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isDesktop ? 20.0 : 14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Items Sold',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF),
                                fontWeight: FontWeight.w600,
                                fontSize: isDesktop ? 14 : 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${analytics['total_items_sold'] ?? 0}',
                              style: TextStyle(
                                fontSize: isDesktop ? 28 : 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: revenueCard),
                            const SizedBox(width: 12),
                            Expanded(child: itemsSoldCard),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (topItems.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text('No sales data available for this distributor yet.', style: TextStyle(color: secondaryTextColor)),
                            ),
                          )
                        else
                          Card(
                            color: Theme.of(context).cardColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cardBorder)),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: topItems.length,
                              separatorBuilder: (context, index) => Divider(height: 1, color: cardBorder),
                              itemBuilder: (context, index) {
                                final item = topItems[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                    child: Text('${index + 1}', style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(item['name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor)),
                                  subtitle: Text('Sold: ${item['quantity_sold'] ?? 0} units', style: TextStyle(color: secondaryTextColor)),
                                  trailing: const Icon(Icons.trending_up, color: Color(0xFF166534)),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator())),
                  error: (err, stack) => Center(child: Text('Error loading analytics: $err', style: const TextStyle(color: Colors.red))),
                ),
                
                const SizedBox(height: 32),
                Text(
                  'Previous Purchase Bills',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final billsAsync = ref.watch(purchaseBillsProvider);
                    
                    return billsAsync.when(
                      skipLoadingOnReload: false,
                      data: (bills) {
                        final distBills = bills.where((b) => b['distributor_id'] == distributor['id']).toList();
                        // Sort descending by date
                        distBills.sort((a, b) {
                          final da = DateTime.tryParse(a['bill_date'] ?? '') ?? DateTime(2000);
                          final db = DateTime.tryParse(b['bill_date'] ?? '') ?? DateTime(2000);
                          return db.compareTo(da);
                        });

                        if (distBills.isEmpty) {
                          return Card(
                            color: Theme.of(context).cardColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cardBorder)),
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Text('No previous bills found for this distributor.', style: TextStyle(color: secondaryTextColor)),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: distBills.length,
                          itemBuilder: (context, index) {
                            final bill = distBills[index];
                            final dateStr = bill['bill_date'] != null 
                                ? bill['bill_date'].toString().split('T')[0] 
                                : 'Unknown Date';
                            
                            return Card(
                              color: Theme.of(context).cardColor,
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cardBorder)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                                  child: const Icon(Icons.receipt_long, color: Color(0xFF3B82F6)),
                                ),
                                title: Text('Invoice: ${bill['invoice_no'] ?? 'N/A'}', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor)),
                                subtitle: Text('Date: $dateStr • Items: ${bill['items']?.length ?? 0}', style: TextStyle(color: secondaryTextColor)),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹${bill['total_amount'] ?? 0.0}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryTextColor)),
                                    Text(
                                      bill['payment_status'] ?? 'UNPAID',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: bill['payment_status'] == 'PAID' ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  _showBillDetails(context, ref, bill);
                                },
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator())),
                      error: (err, stack) => Center(child: Text('Error loading bills: $err', style: const TextStyle(color: Colors.red))),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showBillDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> bill) {
    final items = (bill['items'] as List<dynamic>?) ?? [];
    final inventoryList = ref.read(inventoryProvider).value ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final secondaryTextColor = isDark ? Colors.grey[400] : const Color(0xFF64748B);
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    
    bool isPaying = false;
    String selectedPaymentMethod = (bill['payment_method']?.toString().toUpperCase() == 'ONLINE' ||
            bill['payment_method']?.toString().toUpperCase() == 'UPI' ||
            bill['payment_method']?.toString().toUpperCase() == 'BANK')
        ? 'ONLINE'
        : 'CASH';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isMobileDialog = MediaQuery.of(context).size.width < 600;

          return Dialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 700,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pinned Dialog Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Invoice: ${bill['invoice_no'] ?? 'N/A'}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryTextColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: bill['payment_status'] == 'PAID'
                                ? (isDark ? const Color(0xFF14532D).withValues(alpha: 0.4) : Colors.green.shade50)
                                : (isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.4) : Colors.orange.shade50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            bill['payment_status'] ?? 'UNPAID',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: bill['payment_status'] == 'PAID' ? const Color(0xFF22C55E) : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: cardBorder),

                  // Scrollable Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date: ${bill['bill_date']?.toString().split('T')[0] ?? 'N/A'}',
                            style: TextStyle(color: secondaryTextColor, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Items Purchased',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryTextColor),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: cardBorder),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              separatorBuilder: (context, index) => Divider(height: 1, color: cardBorder),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final invItem = inventoryList.where((i) => i.id == item['inventory_item_id']).firstOrNull;
                                final itemName = invItem != null ? invItem.name : 'Unknown Item (${item['inventory_item_id']})';

                                return ListTile(
                                  dense: isMobileDialog,
                                  title: Text(itemName, style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor, fontSize: 14)),
                                  subtitle: Text(
                                    'Qty: ${item['quantity']} • Batch: ${item['batch_number'] ?? 'N/A'} • Exp: ${item['expiry_date'] ?? 'N/A'}',
                                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                                  ),
                                  trailing: Text('₹${item['unit_price'] ?? 0.0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF22C55E), fontSize: 14)),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Total Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTextColor)),
                              const SizedBox(width: 12),
                              Text('₹${bill['total_amount'] ?? 0.0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: cardBorder),

                  // Responsive Pinned Action Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close', style: TextStyle(color: secondaryTextColor)),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.print, size: 16),
                          label: const Text('Generate PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            foregroundColor: primaryTextColor,
                            elevation: 0,
                          ),
                          onPressed: () async {
                            final billId = bill['id'];
                            if (billId != null) {
                              final url = Uri.parse('${ApiConstants.baseUrl}/api/admin/purchases/$billId/pdf');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            }
                          },
                        ),
                        if (bill['payment_status'] != 'PAID') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: cardBorder),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedPaymentMethod,
                                dropdownColor: Theme.of(context).cardColor,
                                style: TextStyle(color: primaryTextColor, fontSize: 13, fontWeight: FontWeight.w600),
                                items: [
                                  DropdownMenuItem(
                                    value: 'CASH',
                                    child: Text('Cash Account', style: TextStyle(color: primaryTextColor, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'ONLINE',
                                    child: Text('Bank / UPI', style: TextStyle(color: primaryTextColor, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                                onChanged: isPaying
                                    ? null
                                    : (val) {
                                        if (val != null) {
                                          setDialogState(() {
                                            selectedPaymentMethod = val;
                                          });
                                        }
                                      },
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF166534),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: isPaying
                                ? null
                                : () async {
                                    setDialogState(() {
                                      isPaying = true;
                                    });
                                    try {
                                      final svc = ref.read(purchaseServiceProvider);
                                      await svc.markBillAsPaid(
                                        bill['id'],
                                        paymentMethod: selectedPaymentMethod,
                                      );

                                      ref.invalidate(purchaseBillsProvider);
                                      ref.invalidate(distributorAnalyticsProvider(distributor['id']));
                                      ref.invalidate(accountsProvider);
                                      ref.invalidate(historyProvider);

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Bill marked as PAID via $selectedPaymentMethod!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        setDialogState(() {
                                          isPaying = false;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  },
                            child: isPaying
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Mark as Paid', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
