import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import 'package:intl/intl.dart';
import '../../models/lab_models.dart';
import '../../services/lab_data_service.dart';

class LabSampleTrackingScreen extends StatefulWidget {
  const LabSampleTrackingScreen({super.key});

  @override
  State<LabSampleTrackingScreen> createState() =>
      _LabSampleTrackingScreenState();
}

class _LabSampleTrackingScreenState extends State<LabSampleTrackingScreen> {
  List<LabBooking> _bookings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedTab = 'All Samples';
  LabBooking? _selectedBooking;

  final List<String> _tabs = [
    'All Samples',
    'Collected',
    'In Processing',
    'Ready',
    'Delivered',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final bookings = await LabDataService.getBookings();
    setState(() {
      _bookings = bookings;
      if (_bookings.isNotEmpty && _selectedBooking == null) {
        _selectedBooking = _bookings.first;
      }
      _isLoading = false;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.red;
      case 'Collected':
        return Colors.blue;
      case 'In Processing':
        return const Color(0xFFEA580C);
      case 'Ready':
        return Colors.green;
      case 'Delivered':
        return Colors.purple;
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatCard(
    IconData icon,
    String title,
    String value,
    Color color,
    String growth,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 8,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        growth,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: growth.startsWith('+')
                              ? Colors.green
                              : (growth == '→ 0%'
                                    ? const Color(0xFFEA580C)
                                    : Colors.red),
                        ),
                      ),
                    ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Color(0xFF64748B),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {Color? color}) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16, color: color ?? const Color(0xFF64748B)),
      label: Text(
        label,
        style: TextStyle(color: color ?? const Color(0xFF1E293B), fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color ?? const Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String title) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFEA580C), size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFEA580C),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(
    String title,
    String? dateStr,
    String? byStr,
    bool isCompleted,
    bool isLast,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF94A3B8),
                  fontSize: 13,
                ),
              ),
              if (dateStr != null && dateStr.isNotEmpty)
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              if (byStr != null && byStr.isNotEmpty)
                Text(
                  'by $byStr',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    int collectedToday = _bookings.where((b) => b.status == 'Collected').length;
    // ignore: unused_local_variable
    int inProcessing = _bookings
        .where((b) => b.status == 'In Processing')
        .length;
    // ignore: unused_local_variable
    int ready = _bookings.where((b) => b.status == 'Ready').length;
    // ignore: unused_local_variable
    int delivered = _bookings.where((b) => b.status == 'Delivered').length;

    List<LabBooking> displayedBookings = _bookings.where((b) {
      if (_selectedTab != 'All Samples' && b.status != _selectedTab) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return b.patientName.toLowerCase().contains(_searchQuery) ||
            b.sampleId.toLowerCase().contains(_searchQuery) ||
            b.patientPhone.contains(_searchQuery);
      }
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.science,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Sample Tracking',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Track samples from collection to report delivery',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Register New Sample'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats Row
          Row(
            children: [
              _buildStatCard(
                Icons.biotech,
                'Samples Collected Today',
                '28',
                Colors.blue,
                '↗+12%',
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                Icons.schedule,
                'In Processing',
                '14',
                const Color(0xFFEA580C),
                '→ 0%',
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                Icons.check_circle,
                'Reports Ready',
                '20',
                Colors.green,
                '↗+25%',
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                Icons.local_shipping,
                'Reports Delivered',
                '18',
                Colors.purple,
                '↗+18%',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Content Layout
          Expanded(
            child: ResponsiveSplitView(
              leftFlex: 6,
              rightFlex: 2,
              showRightPane: _selectedBooking != null,
              leftPane: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tabs & Export Row
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 16,
                          bottom: 0,
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 16,
                          spacing: 16,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _tabs.map((tab) {
                                bool isSelected = _selectedTab == tab;
                                return InkWell(
                                  onTap: () =>
                                      setState(() => _selectedTab = tab),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: isSelected
                                              ? const Color(0xFFEA580C)
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      tab,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? const Color(0xFFEA580C)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildActionButton(
                                  Icons.download,
                                  'Export',
                                  color: const Color(0xFFEA580C),
                                ),
                                _buildActionButton(
                                  Icons.print,
                                  'Print List',
                                  color: const Color(0xFFEA580C),
                                ),
                                _buildActionButton(
                                  Icons.filter_list,
                                  'Filters',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),

                      // Search & Filters
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              width:
                                  250, // Fixed width instead of Expanded for Wrap
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: TextField(
                                onChanged: (v) => setState(
                                  () => _searchQuery = v.toLowerCase(),
                                ),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Search by patient name, sample ID...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            _buildDropdown('All Status'),
                            _buildDropdown('All Tests'),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Color(0xFFEA580C),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '09 Sep 2026 - 09 Sep 2026',
                                    style: TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildActionButton(Icons.refresh, 'Reset'),
                          ],
                        ),
                      ),

                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        color: const Color(0xFFF8FAFC),
                        child: Row(
                          children: const [
                            SizedBox(
                              width: 30,
                              child: Text(
                                '#',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Sample ID',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Collection Date & Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Patient Name',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Tests',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Assigned To',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Text(
                                  'Action',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),

                      // Table Body
                      _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: displayedBookings.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFE2E8F0),
                                  ),
                              itemBuilder: (context, index) {
                                final booking = displayedBookings[index];
                                final isSelected =
                                    _selectedBooking?.id == booking.id;
                                final statusColor = _getStatusColor(
                                  booking.status,
                                );

                                return InkWell(
                                  onTap: () => setState(
                                    () => _selectedBooking = booking,
                                  ),
                                  child: Container(
                                    color: isSelected
                                        ? const Color(0xFFFFF7ED)
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 30,
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            booking.sampleId,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            DateFormat(
                                              'dd MMM yyyy hh:mm a',
                                            ).format(booking.bookingDate),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            booking.patientName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            booking.testsDescription,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF2563EB),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(
                                                    alpha: 0.1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                        color: statusColor,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      booking.status,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: statusColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            booking.assignedTo,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFE2E8F0,
                                                    ),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Icon(
                                                  Icons.visibility,
                                                  size: 14,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFE2E8F0,
                                                    ),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Icon(
                                                  Icons.more_vert,
                                                  size: 14,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                      // Pagination
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing 1 to ${displayedBookings.length} of ${_bookings.length} samples',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.chevron_left,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEA580C),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '1',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '2',
                                    style: TextStyle(color: Color(0xFF1E293B)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '3',
                                    style: TextStyle(color: Color(0xFF1E293B)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              rightPane: Column(
                children: [
                  // Sample Details Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFEA580C,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.assignment,
                                    color: Color(0xFFEA580C),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Sample Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.edit, size: 14),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEA580C),
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_selectedBooking != null) ...[
                          _buildDetailRow(
                            'Sample ID',
                            _selectedBooking!.sampleId,
                          ),
                          _buildDetailRow(
                            'Patient Name',
                            _selectedBooking!.patientName,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  width: 100,
                                  child: Text(
                                    'Phone',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        _selectedBooking!.patientPhone,
                                        style: const TextStyle(
                                          color: Color(0xFF1E293B),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.wechat,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.phone,
                                        color: Color(0xFFEA580C),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildDetailRow(
                            'Age / Gender',
                            '${_selectedBooking!.patientAge} / ${_selectedBooking!.patientGender}',
                          ),
                          _buildDetailRow(
                            'Collection Date',
                            DateFormat(
                              'dd MMM yyyy hh:mm a',
                            ).format(_selectedBooking!.bookingDate),
                          ),
                          _buildDetailRow(
                            'Tests',
                            _selectedBooking!.testsDescription,
                            color: const Color(0xFF2563EB),
                          ),
                          _buildDetailRow(
                            'Sample Type',
                            _selectedBooking!.sampleType,
                          ),
                          _buildDetailRow(
                            'Collected By',
                            _selectedBooking!.collectedBy,
                          ),
                          _buildDetailRow(
                            'Assigned To',
                            _selectedBooking!.assignedTo,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  width: 100,
                                  child: Text(
                                    'Current Status',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      _selectedBooking!.status,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            _selectedBooking!.status,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _selectedBooking!.status,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(
                                            _selectedBooking!.status,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildDetailRow(
                            'Expected Report',
                            _selectedBooking!.expectedReportDate != null
                                ? DateFormat('dd MMM yyyy hh:mm a').format(
                                    _selectedBooking!.expectedReportDate!,
                                  )
                                : '-',
                          ),
                          _buildDetailRow('Remarks', '-'),
                        ] else ...[
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'Select a sample to view details',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tracking Timeline
                  if (_selectedBooking != null)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tracking Timeline',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: ListView(
                                children: [
                                  _buildTimelineStep(
                                    'Sample Registered',
                                    DateFormat('dd MMM yyyy hh:mm a').format(
                                      _selectedBooking!.bookingDate.subtract(
                                        const Duration(minutes: 5),
                                      ),
                                    ),
                                    _selectedBooking!.collectedBy,
                                    true,
                                    false,
                                  ),
                                  _buildTimelineStep(
                                    'Sample Collected',
                                    DateFormat(
                                      'dd MMM yyyy hh:mm a',
                                    ).format(_selectedBooking!.bookingDate),
                                    _selectedBooking!.collectedBy,
                                    _selectedBooking!.status != 'Pending',
                                    false,
                                  ),
                                  _buildTimelineStep(
                                    'In Processing',
                                    _selectedBooking!.status != 'Pending' &&
                                            _selectedBooking!.status !=
                                                'Collected'
                                        ? DateFormat(
                                            'dd MMM yyyy hh:mm a',
                                          ).format(
                                            _selectedBooking!.bookingDate.add(
                                              const Duration(hours: 2),
                                            ),
                                          )
                                        : '',
                                    _selectedBooking!.assignedTo,
                                    _selectedBooking!.status != 'Pending' &&
                                        _selectedBooking!.status != 'Collected',
                                    false,
                                  ),
                                  _buildTimelineStep(
                                    'Report Ready',
                                    _selectedBooking!.status == 'Ready' ||
                                            _selectedBooking!.status ==
                                                'Delivered'
                                        ? DateFormat(
                                            'dd MMM yyyy hh:mm a',
                                          ).format(
                                            _selectedBooking!
                                                    .expectedReportDate ??
                                                DateTime.now(),
                                          )
                                        : '',
                                    _selectedBooking!.assignedTo,
                                    _selectedBooking!.status == 'Ready' ||
                                        _selectedBooking!.status == 'Delivered',
                                    false,
                                  ),
                                  _buildTimelineStep(
                                    'Report Delivered',
                                    _selectedBooking!.status == 'Delivered'
                                        ? 'Delivered successfully'
                                        : 'Pending',
                                    '',
                                    _selectedBooking!.status == 'Delivered',
                                    true,
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
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions Row
          Row(
            children: [
              Container(
                width: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.flash_on, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.edit_document, 'Register Sample'),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.qr_code_scanner, 'Scan Barcode'),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.update, 'Update Status'),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.assignment, 'Generate Report'),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.wechat, 'Send via WhatsApp'),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.print, 'Print Label'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? const Color(0xFF1E293B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
