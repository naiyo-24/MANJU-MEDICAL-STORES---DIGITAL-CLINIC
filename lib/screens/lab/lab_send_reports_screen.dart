import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import 'package:intl/intl.dart';
import '../../models/lab_models.dart';
import '../../services/lab_data_service.dart';

class LabSendReportsScreen extends StatefulWidget {
  const LabSendReportsScreen({super.key});

  @override
  State<LabSendReportsScreen> createState() => _LabSendReportsScreenState();
}

class _LabSendReportsScreenState extends State<LabSendReportsScreen> {
  List<LabReport> _reports = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedTab = 'Pending to Send';
  LabReport? _selectedReport;
  
  Set<String> _selectedReportIds = {};
  
  bool _sendViaWhatsApp = true;
  bool _sendViaEmail = false;
  bool _sendViaSMS = false;

  final List<String> _tabs = ['Pending to Send', 'Sent', 'Failed'];

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
      case 'Pending': return Colors.red;
      case 'In Processing': return const Color(0xFFEA580C);
      case 'Ready': return Colors.green;
      case 'Delivered': return Colors.purple;
      default: return Colors.grey;
    }
  }

  Widget _buildStatCard(IconData icon, String title, String value, Color color, String growth) {
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
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(width: 8),
                    Text(growth, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: growth.startsWith('↗') ? Colors.green : (growth.startsWith('↘') ? Colors.red : const Color(0xFFEA580C)))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8), color: Colors.white),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {Color? color, Color? bgColor}) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16, color: color ?? const Color(0xFF64748B)),
      label: Text(label, style: TextStyle(color: color ?? const Color(0xFF1E293B), fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor ?? Colors.white,
        foregroundColor: color ?? const Color(0xFF1E293B),
        elevation: 0,
        side: BorderSide(color: bgColor == null ? const Color(0xFFE2E8F0) : bgColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFEA580C).withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: const Color(0xFFEA580C), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxRow(String label, IconData icon, Color iconColor, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFEA580C),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    int pendingToSend = _reports.where((r) => r.status == 'Ready' && !r.isSent).length;
    int sent = _reports.where((r) => r.isSent).length;

    List<LabReport> displayedReports = _reports.where((r) {
      if (_selectedTab == 'Pending to Send' && (r.status != 'Ready' || r.isSent)) return false;
      if (_selectedTab == 'Sent' && !r.isSent) return false;
      if (_selectedTab == 'Failed') return false; // Mock zero failed
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
                    decoration: BoxDecoration(color: const Color(0xFFEA580C), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.send, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Send Reports', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      SizedBox(height: 4),
                      Text('Deliver lab reports to patients via WhatsApp, Email or SMS', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Send Multiple Reports'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats Row
          Row(
            children: [
              _buildStatCard(Icons.wechat, 'Sent via WhatsApp', '48', Colors.green, '↗ 18%'),
              const SizedBox(width: 16),
              _buildStatCard(Icons.email, 'Sent via Email', '36', Colors.red, '↗ 12%'),
              const SizedBox(width: 16),
              _buildStatCard(Icons.sms, 'Sent via SMS', '12', Colors.blue, '↗ 8%'),
              const SizedBox(width: 16),
              _buildStatCard(Icons.history_toggle_off, 'Delivery Failed', '6', const Color(0xFFF59E0B), '↘ 2%'),
            ],
          ),
          const SizedBox(height: 24),

          // Main Content Layout
          Expanded(
            child: ResponsiveSplitView(
              leftFlex: 6,
              rightFlex: 3,
              showRightPane: _selectedReport != null,
              leftPane: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tabs & Export Row
                        Padding(
                          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: _tabs.map((tab) {
                                  bool isSelected = _selectedTab == tab;
                                  String tabLabel = tab;
                                  if (tab == 'Pending to Send') tabLabel += ' ($pendingToSend)';
                                  if (tab == 'Sent') tabLabel += ' ($sent)';
                                  if (tab == 'Failed') tabLabel += ' (6)';

                                  return InkWell(
                                    onTap: () => setState(() => _selectedTab = tab),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border(bottom: BorderSide(color: isSelected ? const Color(0xFFEA580C) : Colors.transparent, width: 2)),
                                      ),
                                      child: Text(tabLabel, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF64748B))),
                                    ),
                                  );
                                }).toList(),
                              ),
                              Row(
                                children: [
                                  _buildDropdown('All Tests'),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.calendar_today, size: 16, color: Color(0xFFEA580C)),
                                        SizedBox(width: 8),
                                        Text('01 Sep 2026 - 09 Sep 2026', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildActionButton(Icons.filter_list, 'Filters'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),

                        // Search & Action Row
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                                  child: TextField(
                                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                                    decoration: const InputDecoration(
                                      hintText: 'Search by patient name, booking ID, sample ID...',
                                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                      prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Row(
                                        children: [
                                          Icon(Icons.people, size: 16, color: Color(0xFF1E293B)),
                                          SizedBox(width: 8),
                                          Text('Select Patients', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                      Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _selectedReportIds.isEmpty ? null : () {},
                                icon: const Icon(Icons.send, size: 16),
                                label: Text('Send Reports (${_selectedReportIds.length})'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE2E8F0), // Disabled color style per screenshot
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                                  disabledForegroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: const Color(0xFFF8FAFC),
                          child: Row(
                            children: [
                              const SizedBox(width: 30, child: Icon(Icons.check_box_outline_blank, size: 18, color: Color(0xFF94A3B8))),
                              const SizedBox(width: 30, child: Text('#', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              const Expanded(flex: 2, child: Text('Booking ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              const Expanded(flex: 2, child: Text('Patient Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              const Expanded(flex: 3, child: Text('Phone / Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              const Expanded(flex: 2, child: Text('Tests', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              const Expanded(flex: 2, child: Text('Report Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              const Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              const Expanded(flex: 1, child: Center(child: Text('Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))))),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        
                        // Table Body
                        Expanded(
                          child: _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C))) : ListView.separated(
                            itemCount: displayedReports.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            itemBuilder: (context, index) {
                              final report = displayedReports[index];
                              final isSelected = _selectedReport?.id == report.id;
                              final isChecked = _selectedReportIds.contains(report.id);
                              // We force 'Ready' for the mock view as per the screenshot
                              final displayStatus = 'Ready'; 
                              final statusColor = Colors.green;

                              return InkWell(
                                onTap: () => setState(() => _selectedReport = report),
                                child: Container(
                                  color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 30, 
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (isChecked) _selectedReportIds.remove(report.id);
                                              else _selectedReportIds.add(report.id);
                                            });
                                          },
                                          child: Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, size: 18, color: isChecked ? const Color(0xFFEA580C) : const Color(0xFF94A3B8)),
                                        )
                                      ),
                                      SizedBox(width: 30, child: Text('${index + 1}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                                      Expanded(flex: 2, child: Text('LB0001${23 + index}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                                      Expanded(flex: 2, child: Text(report.patientName, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                                      Expanded(flex: 3, child: Text(report.patientPhone.replaceAll('+91 ', ''), style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                                      Expanded(flex: 2, child: Text(report.testsPackageName, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      Expanded(flex: 2, child: Text(DateFormat('dd MMM yyyy').format(report.reportDate), style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                                                  const SizedBox(width: 6),
                                                  Text(displayStatus, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                                            child: const Icon(Icons.visibility, size: 14, color: Color(0xFF1E293B)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // Pagination
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Showing 1 to ${displayedReports.length} of $pendingToSend reports', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                              Row(
                                children: [
                                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.chevron_left, size: 16)),
                                  const SizedBox(width: 8),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFEA580C), borderRadius: BorderRadius.circular(4)), child: const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                  const SizedBox(width: 8),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)), child: const Text('2', style: TextStyle(color: Color(0xFF1E293B)))),
                                  const SizedBox(width: 8),
                                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.chevron_right, size: 16)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                rightPane: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        // Title
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFEA580C).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.send, color: Color(0xFFEA580C), size: 18),
                              ),
                              const SizedBox(width: 12),
                              const Text('Send Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            ],
                          ),
                        ),
                        
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Selected Patient Section
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Selected Patient', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                    OutlinedButton(
                                      onPressed: () {},
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      child: const Text('Change', style: TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.pink.shade200,
                                        child: Text(_selectedReport != null ? _selectedReport!.patientName.split(' ').map((e) => e[0]).join() : 'SR', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_selectedReport?.patientName ?? 'Suman Roy', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                                            const SizedBox(height: 2),
                                            Text('${_selectedReport?.patientAge ?? '45 Years'} / ${_selectedReport?.patientGender ?? 'Male'}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                            const SizedBox(height: 8),
                                            Row(children: [const Icon(Icons.phone, size: 12, color: Color(0xFF1E3A8A)), const SizedBox(width: 6), Text(_selectedReport?.patientPhone.replaceAll('+91 ', '') ?? '9830011223', style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)))]),
                                            const SizedBox(height: 4),
                                            Row(children: [const Icon(Icons.email, size: 12, color: Color(0xFF1E3A8A)), const SizedBox(width: 6), Text('${_selectedReport?.patientName.toLowerCase().replaceAll(' ', '.') ?? 'suman.roy'}@example.com', style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)))]),
                                            const SizedBox(height: 4),
                                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [Icon(Icons.location_on, size: 12, color: Color(0xFF1E3A8A)), SizedBox(width: 6), Expanded(child: Text('45, Park Street, Kolkata - 700016', style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A))))]),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Reports to Send Section
                                const Text('Reports to Send', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Checkbox(value: true, onChanged: null, activeColor: Color(0xFFEA580C)),
                                    const Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFF64748B)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_selectedReport?.testsPackageName ?? 'Full Body Checkup', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                                          const Text('LB000123', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                        ],
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.open_in_new, size: 14),
                                      label: const Text('View'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                
                                // Send Via Section
                                const Text('Send Via', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildCheckboxRow('WhatsApp', Icons.wechat, Colors.green, _sendViaWhatsApp, (v) => setState(() => _sendViaWhatsApp = v ?? false)),
                                    const SizedBox(width: 16),
                                    _buildCheckboxRow('Email', Icons.email, Colors.red, _sendViaEmail, (v) => setState(() => _sendViaEmail = v ?? false)),
                                    const SizedBox(width: 16),
                                    _buildCheckboxRow('SMS', Icons.sms, Colors.blue, _sendViaSMS, (v) => setState(() => _sendViaSMS = v ?? false)),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                
                                // Message Section
                                const Text('Message (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                                  child: TextFormField(
                                    initialValue: 'Dear ${_selectedReport?.patientName ?? 'Suman Roy'},\nPlease find attached your lab report.\n\nRegards,\nManju Diagnostic Lab',
                                    maxLines: 4,
                                    decoration: const InputDecoration.collapsed(hintText: 'Enter your message...'),
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Attachment Section
                                const Text('Attachment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                        child: Icon(Icons.insert_drive_file, color: Colors.blue.shade400, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: const [
                                            Text('Report_LB000123.pdf', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                                            Text('245 KB', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.close, size: 16, color: Color(0xFF1E3A8A)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Send Button Footer
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Send Report', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEA580C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
          
          const SizedBox(height: 24),
          
          // Quick Actions Row
          Row(
            children: [
              _buildQuickAction(Icons.wechat, 'Quick Send', 'Send reports instantly via WhatsApp'),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.group, 'Bulk Send', 'Send multiple reports at once'),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.history, 'Track Delivery', 'View sent reports and delivery status'),
            ],
          ),
        ],
      ),
    );
  }
}
