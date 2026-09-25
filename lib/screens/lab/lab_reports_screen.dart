import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import 'package:intl/intl.dart';
import '../../models/lab_models.dart';
import '../../services/lab_data_service.dart';

class LabReportsScreen extends StatefulWidget {
  const LabReportsScreen({super.key});

  @override
  State<LabReportsScreen> createState() => _LabReportsScreenState();
}

class _LabReportsScreenState extends State<LabReportsScreen> {
  List<LabReport> _reports = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedTab = 'All Reports';
  LabReport? _selectedReport;

  final List<String> _tabs = [
    'All Reports',
    'Pending',
    'In Processing',
    'Ready',
    'Delivered',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final reports = await LabDataService.getReports();
    setState(() {
      _reports = reports;
      if (_reports.isNotEmpty && _selectedReport == null) {
        _selectedReport = _reports.first;
      }
      _isLoading = false;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.red;
      case 'In Processing':
        return const Color(0xFFEA580C);
      case 'Ready':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
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
                          color: growth.startsWith('↗')
                              ? Colors.green
                              : (growth.startsWith('↘')
                                    ? Colors.red
                                    : const Color(0xFFEA580C)),
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

  Widget _buildActionButton(
    IconData icon,
    String label, {
    Color? color,
    Color? bgColor,
  }) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16, color: color ?? const Color(0xFF64748B)),
      label: Text(
        label,
        style: TextStyle(color: color ?? const Color(0xFF1E293B), fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor ?? Colors.white,
        foregroundColor: color ?? const Color(0xFF1E293B),
        elevation: 0,
        side: BorderSide(color: bgColor ?? const Color(0xFFE2E8F0)),
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

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    int totalReports = _reports.length;
    int pending = _reports.where((r) => r.status == 'Pending').length;
    int inProcessing = _reports
        .where((r) => r.status == 'In Processing')
        .length;
    int delivered = _reports.where((r) => r.status == 'Delivered').length;

    List<LabReport> displayedReports = _reports.where((r) {
      if (_selectedTab != 'All Reports' && r.status != _selectedTab) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return r.patientName.toLowerCase().contains(_searchQuery) ||
            r.reportId.toLowerCase().contains(_searchQuery);
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
                      Icons.description,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Reports',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'View, manage and download lab reports',
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
                label: const Text('Generate New Report'),
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
                Icons.description,
                'Total Reports',
                '128',
                Colors.red,
                '↗ 18%',
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                Icons.hourglass_empty,
                'Pending',
                '26',
                const Color(0xFFF59E0B),
                '↗ 5%',
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                Icons.settings,
                'In Processing',
                '18',
                Colors.purple,
                '→ 0%',
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                Icons.check_circle,
                'Delivered',
                '72',
                Colors.green,
                '↗ 24%',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Content Layout
          Expanded(
            child: ResponsiveSplitView(
              leftFlex: 5,
              rightFlex: 3,
              showRightPane: _selectedReport != null,
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
                      // Search & Filters
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
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
                                    color: Color(0xFF1E293B),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '01 Sep 2026 - 09 Sep 2026',
                                    style: TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildDropdown('All Status'),
                            _buildDropdown('All Tests'),
                            Container(
                              width: 250,
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
                                      'Search by patient name, report ID...',
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
                            _buildActionButton(
                              Icons.search,
                              'Search',
                              bgColor: const Color(0xFFEA580C),
                              color: Colors.white,
                            ),
                            _buildActionButton(Icons.refresh, 'Reset'),
                          ],
                        ),
                      ),

                      // Tabs & Export Row
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
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
                                String tabLabel = tab;
                                if (tab == 'All Reports') {
                                  tabLabel += ' (${_reports.length})';
                                }
                                if (tab == 'Pending') tabLabel += ' ($pending)';
                                if (tab == 'In Processing') {
                                  tabLabel += ' ($inProcessing)';
                                }
                                if (tab == 'Ready') {
                                  tabLabel +=
                                      ' (${_reports.where((r) => r.status == 'Ready').length})';
                                }
                                if (tab == 'Delivered') {
                                  tabLabel += ' ($delivered)';
                                }

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
                                      tabLabel,
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
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.download,
                                    size: 16,
                                    color: Color(0xFFEA580C),
                                  ),
                                  label: const Text(
                                    'Export (Excel)',
                                    style: TextStyle(color: Color(0xFFEA580C)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide.none,
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.print,
                                    size: 16,
                                    color: Color(0xFFEA580C),
                                  ),
                                  label: const Text(
                                    'Print List',
                                    style: TextStyle(color: Color(0xFFEA580C)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide.none,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),

                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
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
                                'Report ID',
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
                                'Tests / Package',
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
                                'Report Date',
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
                              flex: 1,
                              child: Text(
                                'Sent',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
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
                              itemCount: displayedReports.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFE2E8F0),
                                  ),
                              itemBuilder: (context, index) {
                                final report = displayedReports[index];
                                final isSelected =
                                    _selectedReport?.id == report.id;
                                final statusColor = _getStatusColor(
                                  report.status,
                                );

                                return InkWell(
                                  onTap: () =>
                                      setState(() => _selectedReport = report),
                                  child: Container(
                                    color: isSelected
                                        ? const Color(0xFFFFF7ED)
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 30,
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            report.reportId,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            report.patientName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            report.testsPackageName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF1E293B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            DateFormat(
                                              'dd MMM yyyy hh:mm a',
                                            ).format(report.reportDate),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
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
                                                      report.status,
                                                      style: TextStyle(
                                                        fontSize: 11,
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
                                          flex: 1,
                                          child: Text(
                                            report.isSent ? 'Yes' : 'No',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: report.isSent
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
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
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.visibility,
                                                    size: 14,
                                                    color: Color(0xFF1E293B),
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
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.send,
                                                    size: 14,
                                                    color: Color(0xFF1E293B),
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
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.print,
                                                    size: 14,
                                                    color: Color(0xFF1E293B),
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
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
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
                              'Showing 1 to ${displayedReports.length} of ${_reports.length} reports',
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.transparent,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '...',
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
                                    '13',
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
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
                                Icons.description,
                                color: Color(0xFFEA580C),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Report Preview',
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
                          icon: const Icon(Icons.fullscreen, size: 14),
                          label: const Text('Full Screen'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // The actual A4 mock
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: const Border(
                          left: BorderSide(color: Color(0xFFE2E8F0)),
                          right: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.medical_services,
                                  color: Color(0xFFEA580C),
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'SirfBill Bill Karo, Befikar Raho',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFEA580C),
                                      ),
                                    ),
                                    Text(
                                      '123, Main Road, Kolkata - 700001',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      'Phone: +91 98765 43210 | Email: lab@manjumedical.com',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(
                              color: Color(0xFFE2E8F0),
                              thickness: 2,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'LABORATORY TEST REPORT',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Patient details
                            if (_selectedReport != null)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _buildReportInfoRow(
                                          'Patient Name',
                                          _selectedReport!.patientName,
                                        ),
                                        _buildReportInfoRow(
                                          'Age / Gender',
                                          '${_selectedReport!.patientAge} / ${_selectedReport!.patientGender}',
                                        ),
                                        _buildReportInfoRow(
                                          'Patient ID',
                                          'P2025099001',
                                        ),
                                        _buildReportInfoRow(
                                          'Referred By',
                                          _selectedReport!.referredBy,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _buildReportInfoRow(
                                          'Sample ID',
                                          _selectedReport!.sampleId,
                                        ),
                                        _buildReportInfoRow(
                                          'Sample Type',
                                          _selectedReport!.sampleType,
                                        ),
                                        _buildReportInfoRow(
                                          'Collection Date',
                                          DateFormat(
                                            'dd MMM yyyy hh:mm a',
                                          ).format(
                                            _selectedReport!.collectionDate,
                                          ),
                                        ),
                                        _buildReportInfoRow(
                                          'Reporting Date',
                                          DateFormat(
                                            'dd MMM yyyy hh:mm a',
                                          ).format(_selectedReport!.reportDate),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFFE2E8F0)),

                            // Test Results
                            Container(
                              color: const Color(0xFFF8FAFC),
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 8,
                              ),
                              child: Row(
                                children: const [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Test Name',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Result',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Unit',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Reference Range',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            _buildResultRow(
                              'Hemoglobin (Hb)',
                              '14.2',
                              'g/dL',
                              '13.0 - 17.0',
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            _buildResultRow(
                              'Total WBC Count',
                              '7.8',
                              '10^3/µL',
                              '4.0 - 11.0',
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            _buildResultRow(
                              'RBC Count',
                              '4.9',
                              '10^6/µL',
                              '4.5 - 5.9',
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            _buildResultRow(
                              'Platelet Count',
                              '220',
                              '10^3/µL',
                              '150 - 450',
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            const SizedBox(height: 24),

                            // Comments
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Comments:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: const [
                                Text(
                                  'All parameters are within normal range.',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),

                            // Signatures
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.qr_code_2,
                                      size: 40,
                                      color: Color(0xFF1E293B),
                                    ),
                                    const Text(
                                      'Scan to verify report',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Mock signature
                                    const Text(
                                      'Banerjee',
                                      style: TextStyle(
                                        fontFamily: 'cursive',
                                        fontSize: 24,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                    const Divider(
                                      color: Color(0xFF1E293B),
                                      height: 8,
                                    ),
                                    const Text(
                                      'Dr. Anirban Sen',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const Text(
                                      'MD (Pathology)',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const Text(
                                      'Reg. No.: 12345',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'This is a computer generated report and does not require a signature.',
                              style: TextStyle(
                                fontSize: 8,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.wechat, size: 16),
                          label: const Text('Send via WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.print, size: 16),
                              label: const Text('Print (A4)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEA580C),
                                side: const BorderSide(
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Download PDF'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEA580C),
                                side: const BorderSide(
                                  color: Color(0xFFEA580C),
                                ),
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

          const SizedBox(height: 24),

          // Quick Actions Row
          Row(
            children: [
              Container(
                width: 250,
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
                      child: const Icon(Icons.description, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Quick Report Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.post_add, 'Generate Report'),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.send, 'Bulk Send Reports'),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.upload, 'Export Reports'),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.hourglass_empty, 'View Pending'),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.check_circle_outline, 'View Delivered'),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.bar_chart, 'Custom Report'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 10, color: Color(0xFF1E293B)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(
    String test,
    String result,
    String unit,
    String range,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              test,
              style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              result,
              style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              unit,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              range,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}
