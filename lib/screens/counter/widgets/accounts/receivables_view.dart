import 'package:flutter/material.dart';
import '../../../../services/accounting_extended_service.dart';

class ReceivablesView extends StatefulWidget {
  const ReceivablesView({super.key});

  @override
  State<ReceivablesView> createState() => _ReceivablesViewState();
}

class _ReceivablesViewState extends State<ReceivablesView> {
  bool _isLoading = true;
  List<dynamic> _receivables = [];
  double _totalReceivables = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await AccountingExtendedService.getReceivables();
    if (mounted) {
      setState(() {
        _receivables = data['receivables'] ?? [];
        _totalReceivables = data['total_receivables']?.toDouble() ?? 0.0;
        _isLoading = false;
      });
    }
  }

  String _fmt(double amt) => '₹${amt.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFFF8FAFC),
          child: Row(
            children: const [
              Expanded(
                flex: 3,
                child: Text(
                  'Customer Name',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Amount Owed',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  'Action',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        _receivables.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No outstanding receivables!',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _receivables.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final item = _receivables[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFFE0F2FE),
                                child: Text(
                                  (item['entity_name']?.toString().isNotEmpty ==
                                          true)
                                      ? item['entity_name']
                                            .toString()[0]
                                            .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Color(0xFF0369A1),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item['entity_name']?.toString() ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _fmt(item['amount_owed']?.toDouble() ?? 0.0),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFFB91C1C),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Payment Collection dialog coming soon!',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.download,
                                size: 16,
                                color: Color(0xFF166534),
                              ),
                              label: const Text(
                                'Receive',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF166534),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFDCFCE7),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
              const Text(
                'Total Receivables: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                _fmt(_totalReceivables),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
