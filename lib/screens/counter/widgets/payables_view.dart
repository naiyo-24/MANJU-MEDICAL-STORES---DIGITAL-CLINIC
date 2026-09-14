import 'package:flutter/material.dart';
import '../../../services/accounting_extended_service.dart';

class PayablesView extends StatefulWidget {
  const PayablesView({super.key});

  @override
  State<PayablesView> createState() => _PayablesViewState();
}

class _PayablesViewState extends State<PayablesView> {
  bool _isLoading = true;
  List<dynamic> _payables = [];
  double _totalPayables = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await AccountingExtendedService.getPayables();
    if (mounted) {
      setState(() {
        _payables = data['payables'] ?? [];
        _totalPayables = data['total_payables']?.toDouble() ?? 0.0;
        _isLoading = false;
      });
    }
  }

  String _fmt(double amt) => '₹${amt.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('Supplier Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Amount Owed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                SizedBox(width: 120, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
              ],
            ),
          ),
          Expanded(
            child: _payables.isEmpty
                ? const Center(child: Text('No outstanding payables!', style: TextStyle(color: Color(0xFF64748B))))
                : ListView.separated(
                    itemCount: _payables.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final item = _payables[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFFF3E8FF),
                                    child: Text(item['entity_name'].toString()[0].toUpperCase(), style: const TextStyle(color: Color(0xFF7E22CE), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(item['entity_name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(_fmt(item['amount_owed']?.toDouble() ?? 0.0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFB91C1C)), textAlign: TextAlign.right),
                            ),
                            SizedBox(
                              width: 120,
                              child: Center(
                                child: TextButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Make Payment dialog coming soon!')));
                                  },
                                  icon: const Icon(Icons.upload, size: 16, color: Color(0xFFB91C1C)),
                                  label: const Text('Pay', style: TextStyle(fontSize: 12, color: Color(0xFFB91C1C))),
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFFFEE2E2),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Total Payables: ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                Text(_fmt(_totalPayables), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
