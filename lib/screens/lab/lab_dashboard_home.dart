import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LabDashboardHome extends StatefulWidget {
  const LabDashboardHome({super.key});

  @override
  State<LabDashboardHome> createState() => _LabDashboardHomeState();
}

class _LabDashboardHomeState extends State<LabDashboardHome> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // Default to last 7 days
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFEA580C),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  String _formatDateRange() {
    if (_selectedDateRange == null) return 'Select Date Range';
    final formatter = DateFormat('dd MMM yyyy');
    return '${formatter.format(_selectedDateRange!.start)} - ${formatter.format(_selectedDateRange!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 16,
            spacing: 16,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      SizedBox(height: 4),
                      Text('Overview of your laboratory operations', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: _pickDateRange,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Color(0xFFEA580C)),
                      const SizedBox(width: 8),
                      Text(_formatDateRange(), style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Stat Cards
          LayoutBuilder(builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 800;
            if (isDesktop) {
              return Row(
                children: [
                  Expanded(child: _buildStatCard('Total Bookings', '256', '+12%', Icons.people_alt, const Color(0xFFFFF7ED), const Color(0xFFEA580C))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Samples Collected', '198', '+8%', Icons.science, const Color(0xFFEFF6FF), const Color(0xFF2563EB))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Reports Generated', '176', '+18%', Icons.description, const Color(0xFFF3E8FF), const Color(0xFF9333EA))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Reports Delivered', '142', '+20%', Icons.check_circle, const Color(0xFFDCFCE7), const Color(0xFF16A34A))),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildStatCard('Total Bookings', '256', '+12%', Icons.people_alt, const Color(0xFFFFF7ED), const Color(0xFFEA580C)),
                  const SizedBox(height: 16),
                  _buildStatCard('Samples Collected', '198', '+8%', Icons.science, const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
                  const SizedBox(height: 16),
                  _buildStatCard('Reports Generated', '176', '+18%', Icons.description, const Color(0xFFF3E8FF), const Color(0xFF9333EA)),
                  const SizedBox(height: 16),
                  _buildStatCard('Reports Delivered', '142', '+20%', Icons.check_circle, const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
                ],
              );
            }
          }),
          
          const SizedBox(height: 24),
          
          // Placeholder for Charts and Trends
          LayoutBuilder(builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 800;
            Widget leftCol = Column(
                  children: [
                    _buildCardWrapper(
                      title: 'Booking & Report Trend',
                      action: 'Last 7 Days',
                      height: 300,
                      child: const Center(child: Text('Chart Placeholder', style: TextStyle(color: Colors.grey))),
                    ),
                    const SizedBox(height: 24),
                    _buildCardWrapper(
                      title: 'Recent Bookings',
                      action: 'View All',
                      height: 300,
                      child: const Center(child: Text('Table Placeholder', style: TextStyle(color: Colors.grey))),
                    ),
                  ],
                );
            Widget rightCol = Column(
                  children: [
                    _buildCardWrapper(
                      title: 'Test Status',
                      height: 250,
                      child: const Center(child: Text('Donut Chart Placeholder', style: TextStyle(color: Colors.grey))),
                    ),
                    const SizedBox(height: 24),
                    _buildCardWrapper(
                      title: 'Recent Activities',
                      action: 'View All',
                      height: 350,
                      child: const Center(child: Text('Timeline Placeholder', style: TextStyle(color: Colors.grey))),
                    ),
                  ],
                );

            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: leftCol),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: rightCol),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  leftCol,
                  const SizedBox(height: 24),
                  rightCol,
                ],
              );
            }
          }),
          
          const SizedBox(height: 24),
          
          // Quick Actions
          const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 800;
            if (isDesktop) {
              return Row(
                children: [
                  Expanded(child: _buildQuickAction('New Booking', Icons.calendar_today, const Color(0xFFEA580C))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildQuickAction('Add Test', Icons.science, const Color(0xFFEA580C))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildQuickAction('Upload Report', Icons.upload_file, const Color(0xFFEA580C))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildQuickAction('Invoice', Icons.receipt_long, const Color(0xFFEA580C))),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildQuickAction('New Booking', Icons.calendar_today, const Color(0xFFEA580C)),
                  const SizedBox(height: 16),
                  _buildQuickAction('Add Test', Icons.science, const Color(0xFFEA580C)),
                  const SizedBox(height: 16),
                  _buildQuickAction('Upload Report', Icons.upload_file, const Color(0xFFEA580C)),
                  const SizedBox(height: 16),
                  _buildQuickAction('Invoice', Icons.receipt_long, const Color(0xFFEA580C)),
                ],
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String trend, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(Icons.arrow_upward, size: 12, color: Color(0xFF22C55E)),
                    const SizedBox(width: 4),
                    Text('$trend vs last week', style: const TextStyle(fontSize: 12, color: Color(0xFF22C55E), fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWrapper({required String title, String? action, required double height, required Widget child}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: const Color(0xFFEA580C), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.analytics, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                  ],
                ),
              ),
              if (action != null)
                Text(action, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
