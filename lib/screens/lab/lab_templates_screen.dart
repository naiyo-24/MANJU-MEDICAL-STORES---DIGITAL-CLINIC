import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/lab_models.dart';
import '../../services/lab_data_service.dart';
import 'package:uuid/uuid.dart';

class LabTemplatesScreen extends StatefulWidget {
  const LabTemplatesScreen({super.key});

  @override
  State<LabTemplatesScreen> createState() => _LabTemplatesScreenState();
}

class _LabTemplatesScreenState extends State<LabTemplatesScreen> {
  List<LabTemplate> _templates = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _selectedTabIndex = 0;
  LabTemplate? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final templates = await LabDataService.getTemplates();
    setState(() {
      _templates = templates;
      if (_templates.isNotEmpty && _selectedTemplate == null) {
        _selectedTemplate = _templates.first;
      }
      _isLoading = false;
    });
  }

  Future<void> _navigateToCreateTemplate({LabTemplate? existingTemplate}) async {
    await context.push('/lab/templates/create', extra: existingTemplate);
    _loadData(); // Reload data when returning from the create screen
  }

  @override
  Widget build(BuildContext context) {
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
                    child: const Icon(Icons.description, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Templates', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      SizedBox(height: 4),
                      Text('Create and customize report templates for each test', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  _buildActionButton(Icons.upload, 'Import Template', () {}),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCreateTemplate(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create New Template'),
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
            ],
          ),
          const SizedBox(height: 32),

          // Stats Row
          Row(
            children: [
              _buildStatCard(Icons.description, 'Total Templates', '42', Colors.red),
              const SizedBox(width: 16),
              _buildStatCard(Icons.check_circle, 'Active Templates', '38', Colors.green),
              const SizedBox(width: 16),
              _buildStatCard(Icons.schedule, 'Inactive Templates', '4', Colors.orange),
              const SizedBox(width: 16),
              _buildStatCard(Icons.group, 'Assigned to Tests', '12', Colors.purple),
            ],
          ),
          const SizedBox(height: 24),

          // Main Layout
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Pane: Table
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filters
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
                                      hintText: 'Search template name, test or category...',
                                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                      prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 11),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildDropdown('All Categories'),
                              const SizedBox(width: 12),
                              _buildDropdown('All Status'),
                              const SizedBox(width: 12),
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.filter_alt, size: 18, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          color: const Color(0xFFF8FAFC),
                          child: Row(
                            children: const [
                              SizedBox(width: 30, child: Text('#', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              Expanded(flex: 3, child: Text('Template Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              Expanded(flex: 3, child: Text('Test / Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              Expanded(flex: 2, child: Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              SizedBox(width: 120, child: Center(child: Text('Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))))),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        
                        // Table Body
                        Expanded(
                          child: _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C))) : ListView.separated(
                            itemCount: _templates.where((t) => t.name.toLowerCase().contains(_searchQuery)).length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            itemBuilder: (context, index) {
                              final filtered = _templates.where((t) => t.name.toLowerCase().contains(_searchQuery)).toList();
                              final template = filtered[index];
                              final isSelected = _selectedTemplate?.id == template.id;

                              return InkWell(
                                onTap: () => setState(() => _selectedTemplate = template),
                                child: Container(
                                  color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 30, child: Text('${index + 1}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                                      Expanded(flex: 3, child: Text(template.name, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF1E293B)))),
                                      Expanded(flex: 3, child: Text(template.category, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                                      Expanded(flex: 2, child: Text(template.type, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            Container(width: 8, height: 8, decoration: BoxDecoration(color: template.isActive ? Colors.green : Colors.grey, shape: BoxShape.circle)),
                                            const SizedBox(width: 6),
                                            Text(template.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 13, color: template.isActive ? Colors.green : Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            InkWell(onTap: () => _navigateToCreateTemplate(existingTemplate: template), child: _buildIconBtn(Icons.edit, Colors.blue)),
                                            const SizedBox(width: 8),
                                            _buildIconBtn(Icons.copy, Colors.grey),
                                            const SizedBox(width: 8),
                                            _buildIconBtn(Icons.delete, Colors.red),
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
                        
                        // Pagination stub
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Showing 1 to 12 of 42 templates', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
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
                                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.chevron_right, size: 16)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 24),
                
                // Right Pane: Template Editor
                if (_selectedTemplate != null) Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Editor Tabs
                        Row(
                          children: [
                            _buildEditorTab('Template Editor', 0),
                            _buildEditorTab('Design Settings', 1),
                            _buildEditorTab('Preview', 2),
                            _buildEditorTab('Assign to Tests', 3),
                          ],
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Form Fields
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          RichText(text: const TextSpan(children: [TextSpan(text: 'Template Name ', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)), TextSpan(text: '*', style: TextStyle(color: Colors.red, fontSize: 12))])),
                                          const SizedBox(height: 8),
                                          Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)), child: Align(alignment: Alignment.centerLeft, child: Text(_selectedTemplate!.name, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))))),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          RichText(text: const TextSpan(children: [TextSpan(text: 'Category ', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)), TextSpan(text: '*', style: TextStyle(color: Colors.red, fontSize: 12))])),
                                          const SizedBox(height: 8),
                                          _buildDropdown(_selectedTemplate!.category),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Template Type', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                          const SizedBox(height: 8),
                                          _buildDropdown(_selectedTemplate!.type),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                
                                // WYSIWYG Toolbar Stub
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.format_bold, size: 18, color: Color(0xFF1E293B)),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.format_italic, size: 18, color: Color(0xFF64748B)),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.format_underlined, size: 18, color: Color(0xFF64748B)),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.format_align_left, size: 18, color: Color(0xFF1E293B)),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.format_list_bulleted, size: 18, color: Color(0xFF64748B)),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.format_list_numbered, size: 18, color: Color(0xFF64748B)),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.table_chart_outlined, size: 18, color: Color(0xFF64748B)),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.image_outlined, size: 18, color: Color(0xFF64748B)),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                                        child: Row(
                                          children: const [
                                            Icon(Icons.data_object, size: 14, color: Color(0xFF1E293B)),
                                            SizedBox(width: 6),
                                            Text('Insert Variable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                            Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF1E293B)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Document Preview Box
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Mock Letterhead
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: const Color(0xFFEA580C).withOpacity(0.1), shape: BoxShape.circle),
                                            child: const Icon(Icons.local_hospital, color: Color(0xFFEA580C), size: 24),
                                          ),
                                          const SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: const [
                                              Text('Manju Medical Stores & Digital Clinic', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
                                              Text('123, Main Road, Kolkata - 700001', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                              Text('Phone: +91 98765 43210  |  Email: lab@manjumedical.com', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      const Center(child: Text('LABORATORY TEST REPORT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                                      const SizedBox(height: 16),
                                      
                                      // Patient Details Block
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: const [
                                              _DocVarRow(label: 'Patient Name', val: '{{patient_name}}'),
                                              _DocVarRow(label: 'Age / Gender', val: '{{age_gender}}'),
                                              _DocVarRow(label: 'Patient ID', val: '{{patient_id}}'),
                                              _DocVarRow(label: 'Referred By', val: '{{referred_by}}'),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: const [
                                              _DocVarRow(label: 'Sample ID', val: '{{sample_id}}'),
                                              _DocVarRow(label: 'Sample Type', val: '{{sample_type}}'),
                                              _DocVarRow(label: 'Collection Date', val: '{{collection_date}}'),
                                              _DocVarRow(label: 'Reporting Date', val: '{{report_date}}'),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Result Table
                                      Container(
                                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0))),
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              color: const Color(0xFFF8FAFC),
                                              child: Row(
                                                children: const [
                                                  Expanded(flex: 3, child: Text('Parameter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2, child: Text('Result', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2, child: Text('Unit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2, child: Text('Reference Range', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                                ],
                                              ),
                                            ),
                                            ..._selectedTemplate!.fields.map((f) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
                                              child: Row(
                                                children: [
                                                  Expanded(flex: 3, child: Text(f.name, style: const TextStyle(fontSize: 11))),
                                                  Expanded(flex: 2, child: Text('{{${f.name.toLowerCase().replaceAll(' ', '_')}}}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                                                  Expanded(flex: 2, child: Text(f.unit, style: const TextStyle(fontSize: 11))),
                                                  Expanded(flex: 2, child: Text(f.normalRange, style: const TextStyle(fontSize: 11))),
                                                ],
                                              ),
                                            )),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Center(child: Text('*** End of Report ***', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                                      
                                      const SizedBox(height: 48),
                                      
                                      // Signatures
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: const [
                                              Text('Verified By', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                              SizedBox(height: 32),
                                              SizedBox(width: 150, child: Divider(color: Color(0xFF94A3B8))),
                                              Text('{{lab_person_name}}', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                              Text('{{designation}}', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.draw, size: 32, color: Color(0xFF94A3B8)), // Mock signature
                                              SizedBox(height: 8),
                                              SizedBox(width: 150, child: Divider(color: Color(0xFF94A3B8))),
                                              Text('Dr. {{doctor_name}}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                              Text('{{qualification}}', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                              Text('Reg. No.: {{reg_no}}', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                            ],
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Bottom Actions
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                            color: Colors.white,
                            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildActionButton(Icons.refresh, 'Reset', () {}),
                              Row(
                                children: [
                                  _buildActionButton(Icons.save, 'Save Template', () {}),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.visibility, size: 16),
                                    label: const Text('Save & Preview'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEA580C),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, Color iconColor) {
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
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isSelected ? const Color(0xFFEA580C) : Colors.transparent, width: 2))),
          child: Center(
            child: Text(
              title,
              style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFEA580C)), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFFEA580C)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hint, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
      child: Icon(icon, size: 14, color: color),
    );
  }
}

class _DocVarRow extends StatelessWidget {
  final String label;
  final String val;

  const _DocVarRow({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          const Text(' : ', style: TextStyle(fontSize: 10)),
          Text(val, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
