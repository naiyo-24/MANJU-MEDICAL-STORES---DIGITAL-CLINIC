import 'package:flutter/material.dart';
import '../../../services/accounting_extended_service.dart';

class LedgerView extends StatefulWidget {
  const LedgerView({super.key});

  @override
  State<LedgerView> createState() => _LedgerViewState();
}

class _LedgerViewState extends State<LedgerView> {
  bool _isLoading = true;
  List<dynamic> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await AccountingExtendedService.getLedger();
    if (mounted) {
      setState(() {
        _accounts = data;
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
                Expanded(flex: 3, child: Text('Account Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Account Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Current Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
              ],
            ),
          ),
          Expanded(
            child: _accounts.isEmpty
                ? const Center(child: Text('No accounts found in ledger.', style: TextStyle(color: Color(0xFF64748B))))
                : ListView.separated(
                    itemCount: _accounts.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final acc = _accounts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet, color: Color(0xFF64748B), size: 18),
                                  const SizedBox(width: 8),
                                  Text(acc['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(acc['type'].toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                _fmt(acc['balance']?.toDouble() ?? 0.0),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                textAlign: TextAlign.right,
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
    );
  }
}
