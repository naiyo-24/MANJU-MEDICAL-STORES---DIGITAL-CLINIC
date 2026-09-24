import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import 'package:go_router/go_router.dart';
import '../../models/lab_models.dart';
import '../../services/lab_data_service.dart';
import 'package:uuid/uuid.dart';
import 'lab_create_template_screen.dart';

class LabTemplatesScreen extends StatefulWidget {
  const LabTemplatesScreen({super.key});

  @override
  State<LabTemplatesScreen> createState() => _LabTemplatesScreenState();
}

class _LabTemplatesScreenState extends State<LabTemplatesScreen> {
  List<LabTemplate> _templates = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
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
    final filteredTemplates = _templates.where((t) => t.name.toLowerCase().contains(_searchQuery)).toList();
    final totalPages = (filteredTemplates.length + _itemsPerPage - 1) ~/ _itemsPerPage;
    if (_currentPage > totalPages && totalPages > 0) _currentPage = totalPages;
    final startIndex = filteredTemplates.isEmpty ? 0 : (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filteredTemplates.length);
    final paginatedTemplates = filteredTemplates.isEmpty ? <LabTemplate>[] : filteredTemplates.sublist(startIndex, endIndex);

    return Container(
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header
          Responsive.isMobile(context)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFEA580C), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.description, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Templates', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              SizedBox(height: 4),
                              Text('Create and customize report templates for each test', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildActionButton(Icons.upload, 'Import Template', () {}),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToCreateTemplate(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New Template'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA580C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFEA580C), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.description, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Templates', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                SizedBox(height: 4),
                                Text('Create and customize report templates for each test', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                        ],
                      ),
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
          !Responsive.isDesktop(context)
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(width: 240, child: _buildStatCard(Icons.description, 'Total Templates', '${_templates.length}', Colors.red)),
                      const SizedBox(width: 16),
                      SizedBox(width: 240, child: _buildStatCard(Icons.check_circle, 'Active Templates', '${_templates.where((t) => t.isActive).length}', Colors.green)),
                      const SizedBox(width: 16),
                      SizedBox(width: 240, child: _buildStatCard(Icons.schedule, 'Inactive Templates', '${_templates.where((t) => !t.isActive).length}', Colors.orange)),
                      const SizedBox(width: 16),
                      SizedBox(width: 240, child: _buildStatCard(Icons.group, 'Assigned to Tests', '0', Colors.purple)),
                    ],
                  ),
                )
              : Row(
                  children: [
                    Expanded(child: _buildStatCard(Icons.description, 'Total Templates', '${_templates.length}', Colors.red)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(Icons.check_circle, 'Active Templates', '${_templates.where((t) => t.isActive).length}', Colors.green)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(Icons.schedule, 'Inactive Templates', '${_templates.where((t) => !t.isActive).length}', Colors.orange)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(Icons.group, 'Assigned to Tests', '0', Colors.purple)),
                  ],
                ),
          const SizedBox(height: 24),

          // Main Layout
          Expanded(
            child: ResponsiveSplitView(
            leftFlex: 5,
            rightFlex: 4,
            showRightPane: _selectedTemplate != null,
            leftPane: Container(
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
                        _isLoading ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFFEA580C)))) : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: paginatedTemplates.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          itemBuilder: (context, index) {
                              final template = paginatedTemplates[index];
                              final isSelected = _selectedTemplate?.id == template.id;

                              return InkWell(
                                onTap: () => setState(() => _selectedTemplate = template),
                                child: Container(
                                  color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 30, child: Text('${startIndex + index + 1}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
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
                                            InkWell(
                                              onTap: () async {
                                                final cloneJson = template.toJson();
                                                cloneJson['id'] = const Uuid().v4();
                                                cloneJson['name'] = '${template.name} (Copy)';
                                                final clone = LabTemplate.fromJson(cloneJson);
                                                await LabDataService.saveTemplate(clone);
                                                _loadData();
                                              },
                                              child: _buildIconBtn(Icons.copy, Colors.grey),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (c) => AlertDialog(
                                                    title: const Text('Delete Template'),
                                                    content: Text('Are you sure you want to delete ${template.name}?'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  await LabDataService.deleteTemplate(template.id);
                                                  if (_selectedTemplate?.id == template.id) _selectedTemplate = null;
                                                  _loadData();
                                                }
                                              },
                                              child: _buildIconBtn(Icons.delete, Colors.red),
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
                        
                        // Pagination stub
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 12,
                            children: [
                              Text('Showing ${filteredTemplates.isEmpty ? 0 : startIndex + 1} to $endIndex of ${filteredTemplates.length} templates', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                              if (totalPages > 1) Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  InkWell(
                                    onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                                    child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)), child: Icon(Icons.chevron_left, size: 16, color: _currentPage > 1 ? const Color(0xFF1E293B) : const Color(0xFF94A3B8))),
                                  ),
                                  ...List.generate(totalPages, (i) {
                                    final page = i + 1;
                                    final isSelected = page == _currentPage;
                                    return InkWell(
                                      onTap: () => setState(() => _currentPage = page),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFFEA580C) : Colors.transparent, 
                                          border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)), 
                                          borderRadius: BorderRadius.circular(4)
                                        ), 
                                        child: Text('$page', style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1E293B), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))
                                      ),
                                    );
                                  }),
                                  InkWell(
                                    onTap: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                                    child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)), child: Icon(Icons.chevron_right, size: 16, color: _currentPage < totalPages ? const Color(0xFF1E293B) : const Color(0xFF94A3B8))),
                                  ),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Editor Tabs
                        Row(
                          children: [
                            _buildEditorTab('Template Summary', 0),
                            _buildEditorTab('Assign to Tests', 1),
                          ],
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        
                        SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: _buildSelectedTabContent(),
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
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, Color iconColor) {
    return Container(
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
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
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


  Widget _buildSelectedTabContent() {
    if (_selectedTemplate == null) return const Center(child: Text('Select a template'));
    switch (_selectedTabIndex) {
      case 0:
        return _buildTemplateSummary();
      default:
        return _buildTemplateSummary();
    }
  }



  // ignore: unused_element
  Widget _buildTextField(String label, String value, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedTemplate!.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                      child: Text(_selectedTemplate!.category, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _selectedTemplate!.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _selectedTemplate!.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(fontSize: 12, color: _selectedTemplate!.isActive ? Colors.green : Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final refresh = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LabCreateTemplateScreen(existingTemplate: _selectedTemplate)),
                );
                if (refresh == true) _loadData();
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit Template'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(color: Color(0xFFE2E8F0)),
        const SizedBox(height: 24),
        
        // Parameters Overview
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Test Parameters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            Text('${_selectedTemplate!.fields.length} parameters', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
                child: Row(
                  children: const [
                    Expanded(flex: 3, child: Text('Parameter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                    Expanded(flex: 2, child: Text('Unit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                    Expanded(flex: 3, child: Text('Reference Range', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                  ],
                ),
              ),
              if (_selectedTemplate!.fields.isEmpty)
                const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No parameters defined', style: TextStyle(color: Color(0xFF94A3B8)))))
              else
                ..._selectedTemplate!.fields.map((f) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(f.name, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w500))),
                      Expanded(flex: 2, child: Text(f.unit.isNotEmpty ? f.unit : '-', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                      Expanded(flex: 3, child: Text(f.normalRange.isNotEmpty ? f.normalRange : '-', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                    ],
                  ),
                )),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Template Info
        const Text('Layout Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            children: [
              _buildInfoRow('Format', _selectedTemplate!.reportFormat),
              const SizedBox(height: 8),
              _buildInfoRow('Header Clinic Name', _selectedTemplate!.layoutConfig.clinicName),
              const SizedBox(height: 8),
              _buildInfoRow('Show Patient Details', _selectedTemplate!.showPatientDetails ? 'Yes' : 'No'),
              const SizedBox(height: 8),
              _buildInfoRow('Show QR & PlayStore', _selectedTemplate!.layoutConfig.qrCodeUrl.isNotEmpty ? 'Yes' : 'No'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
        Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)))),
      ],
    );
  }


  // ignore: unused_element
  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.toUpperCase().replaceAll("#", "");
      if (hexColor.length == 6) hexColor = "FF$hexColor";
      return Color(int.parse("0x$hexColor"));
    } catch (e) {
      return const Color(0xFFEA580C); // Fallback manju orange
    }
  }
}


// ignore: unused_element
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
