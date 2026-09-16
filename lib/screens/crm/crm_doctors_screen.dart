import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm_models.dart';
import '../../services/crm_data_service.dart';
import '../../providers/crm_providers.dart';

class CrmDoctorsScreen extends ConsumerStatefulWidget {
  const CrmDoctorsScreen({super.key});

  @override
  ConsumerState<CrmDoctorsScreen> createState() => _CrmDoctorsScreenState();
}

class _CrmDoctorsScreenState extends ConsumerState<CrmDoctorsScreen> {
  List<CrmDoctor> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await ref.read(crmDoctorsProvider.notifier).loadDoctors();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(crmDoctorsProvider);
    _doctors = doctorsAsync.value ?? [];

    if (doctorsAsync.isLoading) {
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
                        Expanded(child: _buildDataGrid()),
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
                child: const Icon(Icons.people_alt, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Doctor Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  SizedBox(height: 4),
                  Text('Add, view, edit and manage all doctors', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add New Doctor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 1200;
    return isDesktop
      ? Row(
          children: [
            Expanded(child: _buildStatCard('Total Doctors', '24', Icons.group, const Color(0xFF8B5CF6))),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Active Doctors', '20', Icons.person, const Color(0xFF22C55E))),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('On Leave', '3', Icons.person_off, const Color(0xFFEF4444))),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Inactive', '1', Icons.person_outline, const Color(0xFFF59E0B))),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Specializations', '8', Icons.medical_services_outlined, const Color(0xFF8B5CF6))),
          ],
        )
      : SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(width: 250, child: _buildStatCard('Total Doctors', '24', Icons.group, const Color(0xFF8B5CF6))),
              const SizedBox(width: 16),
              SizedBox(width: 250, child: _buildStatCard('Active Doctors', '20', Icons.person, const Color(0xFF22C55E))),
              const SizedBox(width: 16),
              SizedBox(width: 250, child: _buildStatCard('On Leave', '3', Icons.person_off, const Color(0xFFEF4444))),
              const SizedBox(width: 16),
              SizedBox(width: 250, child: _buildStatCard('Inactive', '1', Icons.person_outline, const Color(0xFFF59E0B))),
              const SizedBox(width: 16),
              SizedBox(width: 250, child: _buildStatCard('Specializations', '8', Icons.medical_services_outlined, const Color(0xFF8B5CF6))),
            ],
          ),
        );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
        ],
      ),
    );
  }

  Widget _buildDataGrid() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          // Toolbar
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
                    const SizedBox(width: 16),
                    SizedBox(width: 150, child: _buildDropdown('All Specializations')),
                    const SizedBox(width: 16),
                    SizedBox(width: 150, child: _buildDropdown('All Availability')),
                    const SizedBox(width: 16),
                    SizedBox(width: 150, child: _buildDropdown('All Status')),
                    const SizedBox(width: 16),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)),
                      child: TextButton(onPressed: () {}, child: const Text('Reset', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600))),
                    ),
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
                    minWidth: 1200,
                    maxWidth: constraints.maxWidth > 1200 ? constraints.maxWidth : 1200,
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
                            const SizedBox(width: 32, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12))),
                            const Expanded(flex: 3, child: Text('Doctor Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12))),
                            const Expanded(flex: 2, child: Text('Specialization', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12))),
                            const Expanded(flex: 1, child: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12))),
                            const Expanded(flex: 2, child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12))),
                            const Expanded(flex: 1, child: Text('Consultation Fee', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12))),
                            const Expanded(flex: 2, child: Text('Availability', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12))),
                            const Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12))),
                            const SizedBox(width: 120, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      
                      // Table Body
                      Expanded(
                        child: ListView.separated(
                          itemCount: _doctors.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (context, index) {
                            final doc = _doctors[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  const SizedBox(width: 32, child: Icon(Icons.check_box_outline_blank, color: Color(0xFFCBD5E1), size: 18)),
                                  SizedBox(width: 32, child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 13))),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: const Color(0xFFF1F5F9),
                                          child: ClipOval(child: Image.network(doc.avatarUrl, width: 32, height: 32, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person, color: Color(0xFF94A3B8)))),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(doc.name, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 13)),
                                            Text(doc.id, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(flex: 2, child: Text(doc.specialization, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 12, fontWeight: FontWeight.w500))),
                                  Expanded(flex: 1, child: Text(doc.phone, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 12))),
                                  Expanded(flex: 2, child: Text(doc.email, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 12))),
                                  Expanded(flex: 1, child: Text(doc.consultationFee, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 12))),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(doc.availabilityDays, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 12)),
                                        Text(doc.availabilityTime, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Expanded(flex: 1, child: Align(alignment: Alignment.centerLeft, child: _buildStatusPill(doc.status))),
                                  SizedBox(
                                    width: 120,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildActionIcon(Icons.visibility_outlined, const Color(0xFF3B82F6)),
                                        const SizedBox(width: 8),
                                        _buildActionIcon(Icons.edit_outlined, const Color(0xFF8B5CF6)),
                                        const SizedBox(width: 8),
                                        _buildActionIcon(Icons.more_vert, const Color(0xFF94A3B8)),
                                      ],
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
                const Text('Showing 1 to 10 of 24 doctors', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                Row(
                  children: [
                    _buildPageBtn(Icons.chevron_left, false),
                    _buildPageBtn('1', true),
                    _buildPageBtn('2', false),
                    _buildPageBtn('3', false),
                    _buildPageBtn(Icons.chevron_right, false),
                  ],
                ),
                Row(
                  children: [
                    const Text('Rows per page:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: const [
                          Text('10', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF1E3A8A)),
                        ],
                      ),
                    ),
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

  Widget _buildDropdown(String label) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 13, fontWeight: FontWeight.w500)),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF1E3A8A)),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Active':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF16A34A);
        break;
      case 'On Leave':
        bgColor = const Color(0xFFFFEDD5);
        textColor = const Color(0xFFEA580C);
        break;
      case 'Inactive':
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

  Widget _buildActionIcon(IconData icon, Color color) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(child: Icon(icon, size: 14, color: color)),
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
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: content is IconData
            ? Icon(content, size: 16, color: const Color(0xFF1E3A8A))
            : Text(content.toString(), style: TextStyle(color: isActive ? Colors.white : const Color(0xFF1E3A8A), fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
      ),
    );
  }
}
