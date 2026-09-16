import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/crm_models.dart';
import '../../services/crm_data_service.dart';
import '../../providers/crm_provider.dart';

class CrmPatientsScreen extends ConsumerStatefulWidget {
  const CrmPatientsScreen({super.key});

  @override
  ConsumerState<CrmPatientsScreen> createState() => _CrmPatientsScreenState();
}

class _CrmPatientsScreenState extends ConsumerState<CrmPatientsScreen> {
  List<CrmPatient> _patients = [];
  CrmPatient? _selectedPatient;
  List<CrmNote> _patientNotes = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _activeTab = 'All Patients';
  String _selectedGender = 'All Gender';
  String _selectedAge = 'All Age Groups';
  String _selectedStatus = 'All Status';
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final patients = await CrmDataService.getPatients();
    setState(() {
      _patients = patients;
      if (_patients.isNotEmpty) {
        _selectedPatient = _patients.first;
      }
      _isLoading = false;
    });
    if (_selectedPatient != null) {
      _loadNotes(_selectedPatient!.id);
    }
  }

  Future<void> _loadNotes(String patientId) async {
    final notes = await CrmDataService.getNotesForPatient(patientId);
    setState(() {
      _patientNotes = notes;
    });
  }

  void _selectPatient(CrmPatient patient) {
    setState(() {
      _selectedPatient = patient;
    });
    _loadNotes(patient.id);
  }

  List<CrmPatient> get _filteredPatients {
    return _patients.where((p) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!p.name.toLowerCase().contains(query) &&
            !p.phone.contains(query) &&
            !p.email.toLowerCase().contains(query) &&
            !p.uhid.toLowerCase().contains(query)) {
          return false;
        }
      }
      if (_selectedGender != 'All Gender' && p.gender != _selectedGender) return false;
      if (_selectedStatus != 'All Status' && p.status != _selectedStatus) return false;
      
      if (_selectedAge != 'All Age Groups') {
        if (_selectedAge == '0-18 Years' && p.age > 18) return false;
        if (_selectedAge == '19-35 Years' && (p.age < 19 || p.age > 35)) return false;
        if (_selectedAge == '36-60 Years' && (p.age < 36 || p.age > 60)) return false;
        if (_selectedAge == '60+ Years' && p.age <= 60) return false;
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
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
    );
  }

  Widget _buildHeader() {
    return Row(
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
              child: const Icon(Icons.people, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Patient Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                Text('Add, view and manage patient records', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              ],
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddPatientDialog(context),
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: const Text('Add New Patient', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  void _showAddPatientDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final ageController = TextEditingController();
    String gender = 'Male';
    String bloodGroup = 'O+';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Patient', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: ageController, decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()))),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: gender,
                              decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                              items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (v) => setState(() => gender = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: bloodGroup,
                        decoration: const InputDecoration(labelText: 'Blood Group', border: OutlineInputBorder()),
                        items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v) => setState(() => bloodGroup = v!),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
                    final newPatient = CrmPatient(
                      id: 'p${DateTime.now().millisecondsSinceEpoch}',
                      name: nameController.text,
                      uhid: 'PT${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      phone: phoneController.text,
                      email: emailController.text,
                      address: 'Added via CRM',
                      age: int.tryParse(ageController.text) ?? 0,
                      gender: gender,
                      bloodGroup: bloodGroup,
                      lastVisit: DateTime.now(),
                      status: 'New',
                    );
                    await CrmDataService.addPatient(newPatient);
                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadData();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
                  child: const Text('Add Patient'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature will be available in Phase 2!'),
        backgroundColor: Color(0xFF8B5CF6),
      ),
    );
  }

  void _showEditPatientDialog(BuildContext context, CrmPatient patient) {
    final nameController = TextEditingController(text: patient.name);
    final phoneController = TextEditingController(text: patient.phone);
    final emailController = TextEditingController(text: patient.email);
    final ageController = TextEditingController(text: patient.age.toString());
    String gender = patient.gender;
    String bloodGroup = patient.bloodGroup;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Patient', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: ageController, decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()))),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: gender,
                              decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                              items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (v) => setState(() => gender = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].contains(bloodGroup) ? bloodGroup : 'O+',
                        decoration: const InputDecoration(labelText: 'Blood Group', border: OutlineInputBorder()),
                        items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v) => setState(() => bloodGroup = v!),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
                    final updatedPatient = CrmPatient(
                      id: patient.id,
                      name: nameController.text,
                      uhid: patient.uhid,
                      phone: phoneController.text,
                      email: emailController.text,
                      address: patient.address,
                      age: int.tryParse(ageController.text) ?? patient.age,
                      gender: gender,
                      bloodGroup: bloodGroup,
                      lastVisit: patient.lastVisit,
                      status: patient.status,
                    );
                    await CrmDataService.updatePatient(updatedPatient);
                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadData();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
                  child: const Text('Save Changes'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showDeletePatientDialog(BuildContext context, CrmPatient patient) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Patient', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete ${patient.name}? This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await CrmDataService.deletePatient(patient.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (_selectedPatient?.id == patient.id) {
                    setState(() => _selectedPatient = null);
                  }
                  _loadData();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 1000;
    return isDesktop
      ? Row(
          children: [
            Expanded(child: _buildStatCard('Total Patients', '1,248', Icons.people, const Color(0xFF8B5CF6), '12%')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('New Patients', '186', Icons.person_add, const Color(0xFF22C55E), '18%')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Existing Patients', '892', Icons.people_alt, const Color(0xFF3B82F6), '10%')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Follow Ups', '356', Icons.update, const Color(0xFFEC4899), '22%')),
          ],
        )
      : SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(width: 250, child: _buildStatCard('Total Patients', '1,248', Icons.people, const Color(0xFF8B5CF6), '12%')),
              const SizedBox(width: 16),
              SizedBox(width: 250, child: _buildStatCard('New Patients', '186', Icons.person_add, const Color(0xFF22C55E), '18%')),
              const SizedBox(width: 16),
              SizedBox(width: 250, child: _buildStatCard('Existing Patients', '892', Icons.people_alt, const Color(0xFF3B82F6), '10%')),
              const SizedBox(width: 16),
              SizedBox(width: 250, child: _buildStatCard('Follow Ups', '356', Icons.update, const Color(0xFFEC4899), '22%')),
            ],
          ),
        );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String increase) {
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
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.arrow_upward, color: Color(0xFF22C55E), size: 14),
                  Text(increase, style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const Text('vs last month', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPane() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Tabs and Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildTab('All Patients (1,248)'),
                    _buildTab('New Patients (186)'),
                    _buildTab('Follow Ups (356)'),
                    _buildTab('Inactive (72)'),
                  ],
                ),
                Row(
                  children: [
                    _buildActionButton(Icons.upload, 'Import', const Color(0xFF8B5CF6), onTap: () => _showComingSoon(context)),
                    const SizedBox(width: 8),
                    _buildActionButton(Icons.download, 'Export', const Color(0xFF8B5CF6), onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting patients list to CSV...')));
                    }),
                    const SizedBox(width: 8),
                    _buildActionButton(Icons.filter_list, 'Filters', const Color(0xFF1E3A8A), isSolid: true),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          // Filters Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 250,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by name, phone...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(width: 150, child: _buildFilterDropdown('All Gender', ['All Gender', 'Male', 'Female', 'Other'], _selectedGender, (v) => setState(() => _selectedGender = v!))),
                    const SizedBox(width: 12),
                    SizedBox(width: 150, child: _buildFilterDropdown('All Age Groups', ['All Age Groups', '0-18 Years', '19-35 Years', '36-60 Years', '60+ Years'], _selectedAge, (v) => setState(() => _selectedAge = v!))),
                    const SizedBox(width: 12),
                    SizedBox(width: 150, child: _buildFilterDropdown('All Status', ['All Status', 'Active', 'Inactive', 'Follow Up'], _selectedStatus, (v) => setState(() => _selectedStatus = v!))),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _selectedGender = 'All Gender';
                          _selectedAge = 'All Age Groups';
                          _selectedStatus = 'All Status';
                        });
                      },
                      child: const Text('Reset', style: TextStyle(color: Color(0xFF3B82F6))),
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
                            Expanded(flex: 2, child: const Text('Patient Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                            Expanded(flex: 1, child: const Text('UHID', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                            Expanded(flex: 1, child: const Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                            Expanded(flex: 1, child: const Text('Age / Gender', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                            Expanded(flex: 1, child: const Text('Last Visit', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                            Expanded(flex: 1, child: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                            const SizedBox(width: 100, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      // Table Body
                      Expanded(
                        child: ListView.separated(
                          itemCount: _filteredPatients.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (context, index) {
                            final patient = _filteredPatients[index];
                            final isSelected = _selectedPatient?.id == patient.id;
                            
                            return InkWell(
                              onTap: () => _selectPatient(patient),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                color: isSelected ? const Color(0xFFF3E8FF).withOpacity(0.3) : Colors.transparent,
                                child: Row(
                                  children: [
                                    const SizedBox(width: 32, child: Icon(Icons.check_box_outline_blank, color: Color(0xFFCBD5E1), size: 18)),
                                    SizedBox(width: 32, child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w500))),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: _getAvatarColor(patient.name),
                                            child: Text(
                                              patient.name.substring(0, 2).toUpperCase(),
                                              style: TextStyle(color: _getTextColor(patient.name), fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(patient.name, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600, fontSize: 13))),
                                        ],
                                      ),
                                    ),
                                    Expanded(flex: 1, child: Text(patient.uhid, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
                                    Expanded(flex: 1, child: Text(patient.phone, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13))),
                                    Expanded(flex: 1, child: Text('${patient.age} Y / ${patient.gender}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
                                    Expanded(flex: 1, child: Text(DateFormat('dd MMM yyyy').format(patient.lastVisit), style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
                                    Expanded(flex: 1, child: _buildStatusPill(patient.status)),
                                    SizedBox(
                                      width: 100,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _buildActionIcon(Icons.remove_red_eye, const Color(0xFF3B82F6), onTap: () => _selectPatient(patient)),
                                          const SizedBox(width: 4),
                                          _buildActionIcon(Icons.edit, const Color(0xFF3B82F6), onTap: () => _showEditPatientDialog(context, patient)),
                                          const SizedBox(width: 4),
                                          _buildActionIcon(Icons.delete, const Color(0xFFEF4444), onTap: () => _showDeletePatientDialog(context, patient)),
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
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          // Pagination
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Showing 1 to 10 of 1,248 patients', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                Row(
                  children: [
                    _buildPageBtn(Icons.chevron_left, false),
                    _buildPageBtn('1', true),
                    _buildPageBtn('2', false),
                    _buildPageBtn('3', false),
                    _buildPageBtn('4', false),
                    _buildPageBtn('5', false),
                    _buildPageBtn('...', false),
                    _buildPageBtn('125', false),
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
    if (_selectedPatient == null) {
      return Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: const Center(child: Text('Select a patient to view details', style: TextStyle(color: Color(0xFF94A3B8)))),
      );
    }

    final p = _selectedPatient!;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_pin, color: Color(0xFF8B5CF6), size: 20),
                      const SizedBox(width: 8),
                      const Text('Patient Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      InkWell(
                        onTap: () {
                          ref.read(crmProvider.notifier).selectPatient(p);
                          context.go('/crm/prescriptions');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFF3E8FF), border: Border.all(color: const Color(0xFFE9D5FF)), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.edit_document, size: 12, color: Color(0xFF8B5CF6)),
                              SizedBox(width: 4),
                              Text('Prescription', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.edit, size: 12, color: Color(0xFF1E3A8A)),
                            SizedBox(width: 4),
                            Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _getAvatarColor(p.name),
                    child: Text(
                      p.name.substring(0, 2).toUpperCase(),
                      style: TextStyle(color: _getTextColor(p.name), fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            const SizedBox(width: 8),
                            _buildStatusPill(p.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('UHID: ${p.uhid}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        const SizedBox(height: 8),
                        _buildContactRow(Icons.phone, p.phone),
                        const SizedBox(height: 4),
                        _buildContactRow(Icons.email_outlined, p.email),
                        const SizedBox(height: 4),
                        _buildContactRow(Icons.location_on_outlined, p.address),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDemographicInfo('${p.age} Y', 'Age'),
                  _buildDemographicInfo(p.gender, 'Gender'),
                  _buildDemographicInfo(p.bloodGroup, 'Blood Group'),
                  _buildDemographicInfo(DateFormat('dd MMM yyyy').format(p.lastVisit), 'Last Visit'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Quick Actions
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildQuickAction(Icons.description_outlined, 'View Medical History', const Color(0xFF3B82F6), onTap: () => _showComingSoon(context)),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildQuickAction(Icons.calendar_month, 'Book Appointment', const Color(0xFF8B5CF6), onTap: () => _showComingSoon(context)),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildQuickAction(Icons.edit_document, 'Create Prescription', const Color(0xFF8B5CF6), onTap: () {
                ref.read(crmProvider.notifier).selectPatient(p);
                context.go('/crm/prescriptions');
              }),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildQuickAction(Icons.receipt_long, 'Generate Payment Receipt', const Color(0xFF8B5CF6), onTap: () => _showComingSoon(context)),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildQuickAction(Icons.science, 'Create Lab Test Bill', const Color(0xFF8B5CF6), onTap: () => _showComingSoon(context)),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildQuickAction(Icons.send, 'Send to Lab', const Color(0xFF3B82F6), onTap: () => _showComingSoon(context)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Quick Notes
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
                  Row(
                    children: const [
                      Icon(Icons.notes, color: Color(0xFF3B82F6), size: 20),
                      SizedBox(width: 8),
                      Text('Quick Notes', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                  Row(
                    children: const [
                      Icon(Icons.add, size: 14, color: Color(0xFF8B5CF6)),
                      Text('Add Note', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_patientNotes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No notes available.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                )
              else
                ..._patientNotes.map((note) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note.note, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, height: 1.5)),
                      const SizedBox(height: 12),
                      Text('${note.author}  |  ${DateFormat('dd MMM yyyy, hh:mm a').format(note.createdAt)}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    ],
                  ),
                )),
            ],
          ),
        ),
      ],
    ));
  }

  // --- Helper Widgets ---

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

  Widget _buildActionButton(IconData icon, String label, Color color, {bool isSolid = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSolid ? color : Colors.white,
          border: Border.all(color: isSolid ? color : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSolid ? Colors.white : color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSolid ? Colors.white : color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 16),
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color color;
    Color bgColor;
    if (status == 'Active') {
      color = const Color(0xFF22C55E);
      bgColor = const Color(0xFF22C55E).withOpacity(0.1);
    } else if (status == 'Follow Up') {
      color = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFF59E0B).withOpacity(0.1);
    } else {
      color = const Color(0xFFEF4444);
      bgColor = const Color(0xFFEF4444).withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: color),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Widget _buildPageBtn(dynamic content, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF8B5CF6) : Colors.white,
        border: Border.all(color: isActive ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: content is IconData
            ? Icon(content, size: 18, color: const Color(0xFF64748B))
            : Text(content as String, style: TextStyle(color: isActive ? Colors.white : const Color(0xFF64748B), fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8B5CF6)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildDemographicInfo(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 16),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
              ],
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }

  // Avatar colors
  Color _getAvatarColor(String name) {
    final colors = [const Color(0xFFE0E7FF), const Color(0xFFD1FAE5), const Color(0xFFFCE7F3), const Color(0xFFFEF3C7)];
    return colors[name.length % colors.length];
  }

  Color _getTextColor(String name) {
    final colors = [const Color(0xFF4338CA), const Color(0xFF047857), const Color(0xFFBE185D), const Color(0xFFB45309)];
    return colors[name.length % colors.length];
  }
}
