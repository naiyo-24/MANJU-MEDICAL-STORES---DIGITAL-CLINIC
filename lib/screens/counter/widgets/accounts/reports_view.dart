import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../services/accounting_extended_service.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  bool _isLoading = true;
  double _income = 0.0;
  double _expense = 0.0;
  double _profit = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Passing null dates fetches all time, in a real app add a date picker here
    final data = await AccountingExtendedService.getPnL(null, null);
    if (mounted) {
      setState(() {
        _income = data['total_income']?.toDouble() ?? 0.0;
        _expense = data['total_expense']?.toDouble() ?? 0.0;
        _profit = data['net_profit']?.toDouble() ?? 0.0;
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
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profit & Loss Summary (All Time)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildReportCard('Total Income', _income, Icons.arrow_upward, const Color(0xFF22C55E))),
                const SizedBox(width: 16),
                Expanded(child: _buildReportCard('Total Expenses', _expense, Icons.arrow_downward, const Color(0xFFEF4444))),
                const SizedBox(width: 16),
                Expanded(child: _buildReportCard('Net Profit', _profit, Icons.account_balance, const Color(0xFF3B82F6))),
              ],
            ),
            const SizedBox(height: 48),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: _income == 0 && _expense == 0
                    ? Center(
                        child: Text(
                          'No financial data available for charts yet.',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (_income > _expense ? _income : _expense) * 1.2,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    switch (value.toInt()) {
                                      case 0:
                                        return const Padding(
                                          padding: EdgeInsets.only(top: 8.0),
                                          child: Text('Income', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                        );
                                      case 1:
                                        return const Padding(
                                          padding: EdgeInsets.only(top: 8.0),
                                          child: Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                        );
                                      default:
                                        return const Text('');
                                    }
                                  },
                                  reservedSize: 40,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '₹${value.toInt()}',
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: ((_income > _expense ? _income : _expense) / 5).clamp(1.0, double.infinity),
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: const Color(0xFFE2E8F0),
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: [
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: _income,
                                    color: const Color(0xFF22C55E),
                                    width: 60,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: _expense,
                                    color: const Color(0xFFEF4444),
                                    width: 60,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(_fmt(amount), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
