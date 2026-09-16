import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import 'package:intl/intl.dart';
import '../../models/lab_models.dart';
import '../../services/lab_data_service.dart';

class LabHistoryScreen extends StatefulWidget {
  const LabHistoryScreen({super.key});

  @override
  State<LabHistoryScreen> createState() => _LabHistoryScreenState();
}

class _LabHistoryScreenState extends State<LabHistoryScreen> {
  List<LabActivity> _activities = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedTab = 'All Activities';
  LabActivity? _selectedActivity;

  final List<String> _tabs = [
    'All Activities', 'Bookings', 'Samples', 'Reports', 'Communications', 'System Logs'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final activities = await LabDataService.getActivities();
    setState(() {
      _activities = activities;
      if (_activities.isNotEmpty) {
        _selectedActivity = _activities.first;
      }
      _isLoading = false;
    });
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
          Text(text, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
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

  Widget _buildActivityBadge(String type) {
    Color color;
    IconData icon;
    
    switch (type) {
      case 'Report Sent': color = Colors.green; icon = Icons.send; break;
      case 'Report Generated': color = Colors.blue; icon = Icons.description; break;
      case 'Sample Processed': color = Colors.purple; icon = Icons.science; break;
      case 'Sample Collected': color = const Color(0xFFEA580C); icon = Icons.bloodtype; break;
      case 'Booking Created': color = Colors.red; icon = Icons.calendar_today; break;
      case 'Report Delivered': color = Colors.green; icon = Icons.check_circle; break;
      case 'Status Updated': color = Colors.deepPurple; icon = Icons.update; break;
      case 'Payment Received': color = Colors.blue; icon = Icons.payment; break;
      case 'Template Used': color = const Color(0xFFEA580C); icon = Icons.file_copy; break;
      case 'Login': color = Colors.blueGrey; icon = Icons.person; break;
      default: color = Colors.grey; icon = Icons.info; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Widget? customValue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
          Expanded(child: customValue ?? Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildRelatedAction(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16, color: const Color(0xFFEA580C)),
      label: Text(label, style: const TextStyle(color: Color(0xFFEA580C), fontSize: 12, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        side: BorderSide(color: const Color(0xFFEA580C).withOpacity(0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<LabActivity> displayedActivities = _activities.where((a) {
      if (_searchQuery.isNotEmpty) {
        return a.description.toLowerCase().contains(_searchQuery) ||
               a.referenceId.toLowerCase().contains(_searchQuery) ||
               (a.patientName?.toLowerCase().contains(_searchQuery) ?? false);
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
                    child: const Icon(Icons.history, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('History', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      SizedBox(height: 4),
                      Text('View complete activity history of bookings, samples, reports and communications', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats Row
          Row(
            children: [
              _buildStatCard(Icons.assignment, 'Total Activities', '1,248', Colors.blue, '↗ 18%'),
              const SizedBox(width: 16),
              _buildStatCard(Icons.science, 'Sample Activities', '356', Colors.green, '↗ 12%'),
              const SizedBox(width: 16),
              _buildStatCard(Icons.description, 'Report Activities', '624', const Color(0xFFEA580C), '↗ 20%'),
              const SizedBox(width: 16),
              _buildStatCard(Icons.send, 'Communication Logs', '268', Colors.purple, '↗ 15%'),
            ],
          ),
          const SizedBox(height: 24),

          // Filter Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8), color: Colors.white),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.calendar_today, size: 16, color: Color(0xFF1E3A8A)),
                    SizedBox(width: 8),
                    Text('01 Aug 2026 - 09 Sep 2026', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildDropdown('All Activity Types'),
              const SizedBox(width: 12),
              _buildDropdown('All Users'),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search by patient name, booking ID, action...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 12),
              _buildActionButton(Icons.refresh, 'Reset'),
            ],
          ),
          const SizedBox(height: 24),

          // Main Content Layout
          Expanded(
            child: ResponsiveSplitView(
              leftFlex: 6,
              rightFlex: 3,
              showRightPane: _selectedActivity != null,
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
                                  if (tab == 'All Activities') tabLabel += ' (1,248)';
                                  if (tab == 'Bookings') tabLabel += ' (320)';
                                  if (tab == 'Samples') tabLabel += ' (356)';
                                  if (tab == 'Reports') tabLabel += ' (624)';
                                  if (tab == 'Communications') tabLabel += ' (268)';
                                  if (tab == 'System Logs') tabLabel += ' (80)';

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
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.download, size: 14, color: Color(0xFFEA580C)),
                                label: const Text('Export', style: TextStyle(color: Color(0xFF1E293B))),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          color: const Color(0xFFF8FAFC),
                          child: Row(
                            children: const [
                              SizedBox(width: 30, child: Text('#', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              Expanded(flex: 2, child: Text('Date & Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              Expanded(flex: 2, child: Text('Activity Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              Expanded(flex: 3, child: Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              Expanded(flex: 2, child: Text('Reference ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              Expanded(flex: 2, child: Text('Performed By', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              Expanded(flex: 1, child: Center(child: Text('Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))))),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        
                        // Table Body
                        Expanded(
                          child: _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C))) : ListView.separated(
                            itemCount: displayedActivities.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            itemBuilder: (context, index) {
                              final activity = displayedActivities[index];
                              final isSelected = _selectedActivity?.id == activity.id;

                              return InkWell(
                                onTap: () => setState(() => _selectedActivity = activity),
                                child: Container(
                                  color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 30, child: Text('${index + 1}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                                      Expanded(flex: 2, child: Text(DateFormat('dd Sep yyyy hh:mm a').format(activity.dateTime), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)))),
                                      Expanded(flex: 2, child: Row(children: [_buildActivityBadge(activity.type)])),
                                      Expanded(flex: 3, child: Text(activity.description, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                                      Expanded(flex: 2, child: Text(activity.referenceId, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                                      Expanded(flex: 2, child: Text(activity.performedBy, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.visibility, size: 14, color: Color(0xFF1E293B)),
                                                SizedBox(width: 4),
                                                Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                              ],
                                            ),
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
                              const Text('Showing 1 to 10 of 1,248 activities', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                              Row(
                                children: [
                                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.chevron_left, size: 16)),
                                  const SizedBox(width: 8),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFEA580C), borderRadius: BorderRadius.circular(4)), child: const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                  const SizedBox(width: 8),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)), child: const Text('2', style: TextStyle(color: Color(0xFF1E293B)))),
                                  const SizedBox(width: 8),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)), child: const Text('3', style: TextStyle(color: Color(0xFF1E293B)))),
                                  const SizedBox(width: 8),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)), child: const Text('4', style: TextStyle(color: Color(0xFF1E293B)))),
                                  const SizedBox(width: 8),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)), child: const Text('5', style: TextStyle(color: Color(0xFF1E293B)))),
                                  const SizedBox(width: 8),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: const Text('...', style: TextStyle(color: Color(0xFF64748B)))),
                                  const SizedBox(width: 8),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)), child: const Text('125', style: TextStyle(color: Color(0xFF1E293B)))),
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
                rightPane: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Activity Details Card
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
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: const Color(0xFFEA580C).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.assignment, color: Color(0xFFEA580C), size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Activity Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                ],
                              ),
                              const SizedBox(height: 24),
                              if (_selectedActivity != null) ...[
                                _buildDetailRow('Date & Time', DateFormat('dd Sep yyyy hh:mm a').format(_selectedActivity!.dateTime)),
                                _buildDetailRow('Activity Type', '', customValue: Row(children: [_buildActivityBadge(_selectedActivity!.type)])),
                                _buildDetailRow('Description', _selectedActivity!.description),
                                const SizedBox(height: 12),
                                _buildDetailRow('Reference ID', _selectedActivity!.referenceId),
                                _buildDetailRow('Performed By', _selectedActivity!.performedBy),
                                
                                if (_selectedActivity!.patientName != null) ...[
                                  _buildDetailRow('Patient Name', _selectedActivity!.patientName!),
                                  if (_selectedActivity!.patientPhone != null)
                                    _buildDetailRow('Phone', _selectedActivity!.patientPhone!),
                                ],
                                
                                if (_selectedActivity!.type == 'Report Sent' || _selectedActivity!.type == 'Report Generated') ...[
                                  _buildDetailRow('Report', '', customValue: Row(children: const [Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFF3B82F6)), SizedBox(width: 6), Text('View Report (PDF)', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 13, decoration: TextDecoration.underline))])),
                                ],
                                
                                if (_selectedActivity!.type == 'Report Sent') ...[
                                  _buildDetailRow('Sent Via', '', customValue: Row(children: const [Icon(Icons.wechat, size: 16, color: Colors.green), SizedBox(width: 6), Text('WhatsApp', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13))])),
                                ],

                                if (_selectedActivity!.message != null) ...[
                                  const SizedBox(height: 8),
                                  _buildDetailRow('Message', '', customValue: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                                    child: Text(_selectedActivity!.message!, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
                                  )),
                                ],
                              ] else ...[
                                const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Select an activity to view details', style: TextStyle(color: Color(0xFF94A3B8))))),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Related Actions Card
                        Container(
                          width: double.infinity,
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
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: const Color(0xFFEA580C).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.shopping_bag, color: Color(0xFFEA580C), size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Related Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: _buildRelatedAction(Icons.calendar_today, 'View Booking')),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildRelatedAction(Icons.science, 'View Sample')),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildRelatedAction(Icons.description, 'View Report')),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildRelatedAction(Icons.send, 'Resend Report')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
          
          const SizedBox(height: 24),
          
          // Bottom Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xFFEA580C), shape: BoxShape.circle),
                      child: const Icon(Icons.history, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Complete History, Better Tracking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF9A3412))),
                        SizedBox(height: 4),
                        Text('Track every activity from booking to report delivery', style: TextStyle(fontSize: 14, color: Color(0xFFC2410C))),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: const [
                    Icon(Icons.eco, color: Colors.green, size: 24),
                    SizedBox(width: 8),
                    Text('Transparency Builds Trust', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9A3412))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
