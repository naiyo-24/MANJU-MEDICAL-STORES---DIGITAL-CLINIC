import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm_models.dart';
import '../../services/crm_data_service.dart';
import '../../providers/crm_providers.dart';

class CrmAppointmentsScreen extends ConsumerStatefulWidget {
  const CrmAppointmentsScreen({super.key});

  @override
  ConsumerState<CrmAppointmentsScreen> createState() => _CrmAppointmentsScreenState();
}

class _CrmAppointmentsScreenState extends ConsumerState<CrmAppointmentsScreen> {
  List<CrmAppointment> _appointments = [];
  CrmAppointment? _selectedAppointment;
  bool _isLoading = true;
  String _activeTab = 'All Appointments';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await ref.read(crmAppointmentsProvider.notifier).loadAppointments();
    setState(() {
      _isLoading = false;
    });
  }

  void _selectAppointment(CrmAppointment appointment) {
    setState(() {
      _selectedAppointment = appointment;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(crmAppointmentsProvider);
    _appointments = appointmentsAsync.value ?? [];
    if (_appointments.isNotEmpty && _selectedAppointment == null) {
      _selectedAppointment = _appointments.length > 1 ? _appointments[1] : _appointments.first;
    }

    if (appointmentsAsync.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildStatsRow(context),
                        const SizedBox(height: 24),
                        Expanded(
                          child: LayoutBuilder(builder: (context, constraints) {
                            bool isDesktop = constraints.maxWidth > 1000;
                            return isDesktop 
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 3, child: _buildLeftPane()),
                                    const SizedBox(width: 24),
                                    SizedBox(width: 350, child: _buildRightPane()),
                                  ],
                                )
                              : SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 600,
                                        child: _buildLeftPane()
                                      ),
                                      const SizedBox(height: 24),
                                      _buildRightPane(),
                                    ],
                                  ),
                                );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_month, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Appointment Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  SizedBox(height: 4),
                  Text('Schedule, manage and track doctor appointments', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Book New Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.calendar_today, size: 18),
                label: const Text('Appointment Calendar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8B5CF6),
                  side: const BorderSide(color: Color(0xFF8B5CF6)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 800;
    return isDesktop 
      ? Row(
          children: [
            Expanded(child: _buildStatCard('Today\'s Appointments', '86', Icons.calendar_today, const Color(0xFF8B5CF6), '+12%', true)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Completed', '72', Icons.people, const Color(0xFF22C55E), '+18%', true)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Scheduled', '10', Icons.access_time, const Color(0xFF3B82F6), null, null)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Cancelled', '4', Icons.close, const Color(0xFFEF4444), '-8%', false)),
          ],
        )
      : SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(width: 250, child: _buildStatCard('Today\'s Appointments', '86', Icons.calendar_today, const Color(0xFF8B5CF6), '+12%', true)),
              const SizedBox(width: 16),
              SizedBox(width: 250, child: _buildStatCard('Completed', '72', Icons.people, const Color(0xFF22C55E), '+18%', true)),
              const SizedBox(width: 16),
              SizedBox(width: 250, child: _buildStatCard('Scheduled', '10', Icons.access_time, const Color(0xFF3B82F6), null, null)),
              const SizedBox(width: 16),
              SizedBox(width: 250, child: _buildStatCard('Cancelled', '4', Icons.close, const Color(0xFFEF4444), '-8%', false)),
            ],
          ),
        );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String? trend, bool? isPositive) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
          if (trend != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(isPositive! ? Icons.arrow_upward : Icons.arrow_downward, color: isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444), size: 14),
                    const SizedBox(width: 4),
                    Text(trend, style: TextStyle(color: isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('vs yesterday', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLeftPane() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          // Tabs
          Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab('All Appointments (86)'),
                  _buildTab('Scheduled (10)'),
                  _buildTab('In Consultation (6)'),
                  _buildTab('Completed (72)'),
                  _buildTab('Cancelled (4)'),
                  _buildTab('Rescheduled (2)'),
                ],
              ),
            ),
          ),
          // Action Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Container(
                      width: 250,
                      height: 40,
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                      child: const TextField(decoration: InputDecoration(hintText: 'Search...', prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10))),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(width: 150, child: _buildDropdown('09 Sep 2026', Icons.calendar_today)),
                    const SizedBox(width: 12),
                    SizedBox(width: 150, child: _buildDropdown('All Doctors', null)),
                    const SizedBox(width: 12),
                    SizedBox(width: 150, child: _buildDropdown('All Status', null)),
                    const SizedBox(width: 12),
                    TextButton(onPressed: () {}, child: const Text('Reset', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600))),
                  ],
                ),
              );
            }),
          ),
          // Table Section
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 1000,
                    maxWidth: constraints.maxWidth > 1000 ? constraints.maxWidth : 1000,
                  ),
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: const Color(0xFFF8FAFC),
                        child: Row(
                          children: [
                            const SizedBox(width: 32, child: Icon(Icons.check_box_outline_blank, color: Color(0xFFCBD5E1), size: 18)),
                            const SizedBox(width: 32, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                            Expanded(flex: 1, child: const Text('Time', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                            Expanded(flex: 2, child: const Text('Patient Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                            Expanded(flex: 1, child: const Text('Age / Gender', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                            Expanded(flex: 1, child: const Text('Doctor', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                            Expanded(flex: 2, child: const Text('Type', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                            Expanded(flex: 1, child: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                            const SizedBox(width: 100, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      // Table Body
                      Expanded(
                        child: ListView.separated(
                          itemCount: _appointments.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (context, index) {
                            final apt = _appointments[index];
                            final isSelected = _selectedAppointment?.id == apt.id;
                            
                            return InkWell(
                              onTap: () => _selectAppointment(apt),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                color: isSelected ? const Color(0xFFF3E8FF).withOpacity(0.3) : Colors.transparent,
                                child: Row(
                                  children: [
                                    const SizedBox(width: 32, child: Icon(Icons.check_box_outline_blank, color: Color(0xFFCBD5E1), size: 18)),
                                    SizedBox(width: 32, child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
                                    Expanded(flex: 1, child: Text(apt.time, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500, fontSize: 13))),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                                            child: Text(apt.patientName.substring(0, 2).toUpperCase(), style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(apt.patientName, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    Expanded(flex: 1, child: Text('${apt.patientAge} / ${apt.patientGender}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
                                    Expanded(flex: 1, child: Text(apt.doctorName, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13))),
                                    Expanded(flex: 2, child: Text(apt.appointmentType, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
                                    Expanded(flex: 1, child: _buildStatusPill(apt.status)),
                                    SizedBox(
                                      width: 100,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.visibility_outlined, size: 18, color: const Color(0xFF3B82F6)),
                                          const SizedBox(width: 8),
                                          Icon(Icons.edit_outlined, size: 18, color: const Color(0xFF8B5CF6)),
                                          const SizedBox(width: 8),
                                          Icon(Icons.more_vert, size: 18, color: const Color(0xFF94A3B8)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          // Pagination
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Showing 1 to 10 of 86 appointments', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                Row(
                  children: [
                    _buildPageBtn(Icons.chevron_left, false),
                    _buildPageBtn('1', true),
                    _buildPageBtn('2', false),
                    _buildPageBtn('3', false),
                    _buildPageBtn('4', false),
                    _buildPageBtn('5', false),
                    _buildPageBtn('...', false),
                    _buildPageBtn('9', false),
                    _buildPageBtn(Icons.chevron_right, false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPane() {
    if (_selectedAppointment == null) {
      return Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: const Center(child: Text('Select an appointment to view details', style: TextStyle(color: Color(0xFF94A3B8)))),
      );
    }

    final apt = _selectedAppointment!;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Calendar Widget
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.chevron_left, color: Color(0xFF64748B), size: 20),
                    const Text('September 2026', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                    const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCalendarGrid(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Appointment Details Card
          Container(
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
                    const Text('Appointment Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B5CF6),
                        side: const BorderSide(color: Color(0xFF8B5CF6)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFF472B6),
                      child: Text(apt.patientName.substring(0, 2).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(apt.patientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              const SizedBox(width: 8),
                              _buildStatusPill(apt.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 12, color: Color(0xFF8B5CF6)),
                              const SizedBox(width: 4),
                              Text(apt.patientPhone, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.email, size: 12, color: Color(0xFF8B5CF6)),
                              const SizedBox(width: 4),
                              Text(apt.patientEmail, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: Color(0xFF8B5CF6)),
                              const SizedBox(width: 4),
                              Text(apt.location, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Appointment ID', apt.id),
                _buildDetailRow('Date & Time', '${apt.date}, ${apt.time}'),
                _buildDetailRow('Doctor', '${apt.doctorName} (MBBS, MD)'),
                _buildDetailRow('Appointment Type', apt.appointmentType),
                _buildDetailRow('Consultation Fee', apt.consultationFee),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Expanded(flex: 2, child: Text('Payment Status', style: TextStyle(color: Color(0xFF64748B), fontSize: 13))),
                      Expanded(flex: 3, child: Align(alignment: Alignment.centerLeft, child: _buildStatusPill(apt.paymentStatus))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Notes', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                const SizedBox(height: 4),
                Text(apt.notes.isNotEmpty ? apt.notes : 'No additional notes provided.', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.video_call, size: 18),
                    label: const Text('Start Consultation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.access_time, 'Reschedule', const Color(0xFF1E293B)),
                    _buildActionButton(Icons.close, 'Cancel', const Color(0xFF1E293B)),
                    _buildActionButton(Icons.print, 'Print Slip', const Color(0xFF1E293B)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildCalendarGrid() {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    // Dummy calendar grid for Sep 2026
    final dates = [
      '30', '31', '1', '2', '3', '4', '5',
      '6', '7', '8', '9', '10', '11', '12',
      '13', '14', '15', '16', '17', '18', '19',
      '20', '21', '22', '23', '24', '25', '26',
      '27', '28', '29', '30', '1', '2', '3',
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.map((d) => SizedBox(width: 30, child: Center(child: Text(d, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold))))).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final date = dates[index];
            final isCurrentMonth = index > 1 && index < 32;
            final isSelected = date == '9' && isCurrentMonth;
            
            return Container(
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  date,
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isCurrentMonth ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildTab(String title) {
    final isSelected = _activeTab == title.split(' (')[0];
    return InkWell(
      onTap: () => setState(() => _activeTab = title.split(' (')[0]),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: const Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
              ],
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            ],
          ),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Active':
      case 'Completed':
      case 'Paid (UPI)':
      case 'Paid (Card)':
      case 'Paid (Cash)':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF16A34A);
        break;
      case 'Scheduled':
      case 'In Consultation':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF2563EB);
        break;
      case 'Waiting':
      case 'Pending':
        bgColor = const Color(0xFFFEF9C3);
        textColor = const Color(0xFFCA8A04);
        break;
      case 'Follow Up':
        bgColor = const Color(0xFFFFEDD5);
        textColor = const Color(0xFFEA580C);
        break;
      case 'Cancelled':
      case 'Refunded':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: textColor),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPageBtn(dynamic content, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF8B5CF6) : Colors.white,
        border: Border.all(color: isActive ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: content is IconData
            ? Icon(content, size: 16, color: const Color(0xFF64748B))
            : Text(content.toString(), style: TextStyle(color: isActive ? Colors.white : const Color(0xFF64748B), fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
