import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CrmDashboardHome extends StatelessWidget {
  const CrmDashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildQuickActionsGrid(context),
            const SizedBox(height: 24),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF3E8FF,
        ).withValues(alpha: 0.5), // Very light purple
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Welcome Back, Lab Admin 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Manage your patients, appointments, prescriptions and more — all in one CRM.',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ],
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    'Better Care 💜',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5CF6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    'Stronger Relationships',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5CF6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Doctor graphic placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE9D5FF), width: 2),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Color(0xFF8B5CF6),
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;
        return isDesktop
            ? Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Patients',
                      '1,248',
                      Icons.people,
                      const Color(0xFF8B5CF6),
                      '12%',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Appointments',
                      '320',
                      Icons.calendar_month,
                      const Color(0xFF22C55E),
                      '18%',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Prescriptions',
                      '286',
                      Icons.edit_document,
                      const Color(0xFFEC4899),
                      '22%',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Online Orders',
                      '124',
                      Icons.shopping_cart,
                      const Color(0xFF3B82F6),
                      '15%',
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 1000),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Patients',
                          '1,248',
                          Icons.people,
                          const Color(0xFF8B5CF6),
                          '12%',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Appointments',
                          '320',
                          Icons.calendar_month,
                          const Color(0xFF22C55E),
                          '18%',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Prescriptions',
                          '286',
                          Icons.edit_document,
                          const Color(0xFFEC4899),
                          '22%',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Online Orders',
                          '124',
                          Icons.shopping_cart,
                          const Color(0xFF3B82F6),
                          '15%',
                        ),
                      ),
                    ],
                  ),
                ),
              );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String increase,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.arrow_upward,
                    color: Color(0xFF22C55E),
                    size: 14,
                  ),
                  Text(
                    increase,
                    style: const TextStyle(
                      color: Color(0xFF22C55E),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'vs last month',
                style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 1000;
        bool isTablet = constraints.maxWidth > 600;
        int crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
        double childAspectRatio = isDesktop ? 3.5 : 3.0;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildActionCard(
              context,
              'Patient Management',
              'Add, view and manage patient records',
              Icons.people,
              const Color(0xFF8B5CF6),
              '/crm/patients',
            ),
            _buildActionCard(
              context,
              'Appointment Management',
              'Schedule and manage doctor appointments',
              Icons.calendar_month,
              const Color(0xFF22C55E),
              '/crm/appointments',
            ),
            _buildActionCard(
              context,
              'Prescription Generation',
              'Create and manage digital prescriptions',
              Icons.edit_document,
              const Color(0xFFEC4899),
              '/crm/prescriptions',
            ),

            _buildActionCard(
              context,
              'Doctor Inventory',
              'Manage doctor stocks and supplies',
              Icons.medical_services,
              const Color(0xFF3B82F6),
              '/crm/doctors',
            ),
            _buildActionCard(
              context,
              'Payment Receipt',
              'Generate payment receipts (Cash/UPI/Card)',
              Icons.receipt_long,
              const Color(0xFFEAB308),
              '/crm/payment_receipt',
            ),
            _buildActionCard(
              context,
              'Payment History',
              'View all payment transactions',
              Icons.history,
              const Color(0xFF8B5CF6),
              '/crm/payment_history',
            ),

            _buildActionCard(
              context,
              'Lab Test Billing',
              'Create lab test bills from CRM',
              Icons.science,
              const Color(0xFFEF4444),
              '/crm/lab_billing',
            ),
            _buildActionCard(
              context,
              'Send to Lab',
              'Send test orders to lab and track status',
              Icons.send,
              const Color(0xFF3B82F6),
              '/crm/send_to_lab',
            ),
            _buildActionCard(
              context,
              'Order Management',
              'Manage online orders (Doctor booking & Prescription only)',
              Icons.shopping_cart,
              const Color(0xFFEC4899),
              '/crm/order_management',
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String route,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.go(route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;
        Widget appointments = _buildTableCard(
          'Today\'s Appointments',
          Icons.calendar_today,
          ['Patient Name', 'Doctor', 'Time', 'Status', 'Action'],
          [
            [
              'Rahul Das',
              'Dr. Sen',
              '10:00 AM',
              'Confirmed',
              const Color(0xFF22C55E),
            ],
            [
              'Priya Sharma',
              'Dr. Mehta',
              '11:30 AM',
              'Waiting',
              const Color(0xFFF59E0B),
            ],
            [
              'Suman Roy',
              'Dr. Iyer',
              '01:00 PM',
              'Confirmed',
              const Color(0xFF22C55E),
            ],
            [
              'Neha Patel',
              'Dr. Sen',
              '03:30 PM',
              'Waiting',
              const Color(0xFFF59E0B),
            ],
            [
              'Karan Mehta',
              'Dr. Gupta',
              '05:00 PM',
              'Confirmed',
              const Color(0xFF22C55E),
            ],
          ],
        );
        Widget orders = _buildTableCard(
          'Recent Online Orders',
          Icons.shopping_cart,
          ['Order ID', 'Type', 'Patient', 'Status', 'Action'],
          [
            [
              'ORD00123',
              'Doctor Booking',
              'Rahul Das',
              'Confirmed',
              const Color(0xFF22C55E),
            ],
            [
              'ORD00124',
              'Prescription',
              'Priya Sharma',
              'Completed',
              const Color(0xFF3B82F6),
            ],
            [
              'ORD00125',
              'Doctor Booking',
              'Suman Roy',
              'Pending',
              const Color(0xFFF59E0B),
            ],
            [
              'ORD00126',
              'Prescription',
              'Neha Patel',
              'Completed',
              const Color(0xFF3B82F6),
            ],
            [
              'ORD00127',
              'Doctor Booking',
              'Karan Mehta',
              'Confirmed',
              const Color(0xFF22C55E),
            ],
          ],
        );
        Widget revenue = _buildRevenueCard();

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: appointments),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: orders),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: revenue),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              appointments,
              const SizedBox(height: 16),
              orders,
              const SizedBox(height: 16),
              revenue,
            ],
          );
        }
      },
    );
  }

  Widget _buildTableCard(
    String title,
    IconData icon,
    List<String> headers,
    List<List<dynamic>> rows,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
              const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 800),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                  4: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                    ),
                    children: headers
                        .map(
                          (h) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              h,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  ...rows.map(
                    (row) => TableRow(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFF8FAFC)),
                        ),
                      ),
                      children: [
                        _buildTableCell(row[0]),
                        _buildTableCell(row[1]),
                        _buildTableCell(row[2]),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (row[4] as Color).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 10,
                                  color: row[4],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  row[3],
                                  style: TextStyle(
                                    color: row[4],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'View',
                            style: TextStyle(
                              color: Color(0xFF3B82F6),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12),
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.bar_chart, color: Color(0xFF1E3A8A), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Revenue Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: const [
                    Text(
                      'This Month',
                      style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Simple Bar Chart UI
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBar('Week 1', 60),
                _buildBar('Week 2', 80),
                _buildBar('Week 3', 100),
                _buildBar('Week 4', 110),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Total Revenue',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '₹ 2,48,320',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.arrow_upward,
                        color: Color(0xFF22C55E),
                        size: 14,
                      ),
                      Text(
                        '20%',
                        style: TextStyle(
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'vs last month',
                    style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFC084FC),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}
