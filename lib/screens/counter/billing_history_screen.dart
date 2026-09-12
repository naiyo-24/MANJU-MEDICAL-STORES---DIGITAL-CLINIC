import 'package:flutter/material.dart';
import '../../services/billing_history_service.dart';
import 'package:intl/intl.dart';

class BillingHistoryScreen extends StatefulWidget {
  const BillingHistoryScreen({super.key});

  @override
  State<BillingHistoryScreen> createState() => _BillingHistoryScreenState();
}

class _BillingHistoryScreenState extends State<BillingHistoryScreen> {
  List<SavedBill> _bills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final bills = await BillingHistoryService.getBillingHistory();
      if (mounted) {
        setState(() {
          _bills = bills;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading history: $e')));
      }
    }
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Paid',
        style: TextStyle(color: Color(0xFF166534), fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Billing History', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bills.isEmpty
              ? const Center(child: Text('No billing history found.', style: TextStyle(color: Color(0xFF64748B))))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bills.length,
                  itemBuilder: (context, index) {
                    final bill = _bills[index];
                    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(bill.createdAt);
                    
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(bill.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                                  const SizedBox(height: 4),
                                  Text(dateStr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${bill.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF166534))),
                                const SizedBox(height: 4),
                                _buildStatusChip(),
                              ],
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Customer: ${bill.customerName.isEmpty ? 'Walk-in' : bill.customerName} • Items: ${bill.items.length}',
                            style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                          ),
                        ),
                        children: [
                          const Divider(height: 1),
                          Container(
                            color: const Color(0xFFF1F5F9),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Item Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                const SizedBox(height: 8),
                                ...bill.items.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text('${item['name']} (x${item['qty']})', style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                                        ),
                                        Text('₹${(item['total'] as num).toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 13)),
                                      ],
                                    ),
                                  );
                                }),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                    Text('₹${bill.subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Discount', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                    Text('- ₹${bill.discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Tax (GST)', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                    Text('₹${bill.tax.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14)),
                                    Text('₹${bill.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF166534), fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
