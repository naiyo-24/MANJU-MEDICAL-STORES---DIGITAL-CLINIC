import 'package:flutter/material.dart';
import '../../models/lab_models.dart';
import '../../services/lab_data_service.dart';
import 'package:uuid/uuid.dart';

class LabTestsScreen extends StatefulWidget {
  const LabTestsScreen({super.key});

  @override
  State<LabTestsScreen> createState() => _LabTestsScreenState();
}

class _LabTestsScreenState extends State<LabTestsScreen> {
  List<LabTest> _tests = [];
  List<LabTemplate> _templates = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _selectedTabIndex = 0;
  LabTest? _selectedTest;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final tests = await LabDataService.getTests();
    final templates = await LabDataService.getTemplates();
    setState(() {
      _tests = tests;
      _templates = templates;
      if (_tests.isNotEmpty && _selectedTest == null) {
        _selectedTest = _tests.first;
      }
      _isLoading = false;
    });
  }

  void _showAddTestDialog({LabTest? existingTest}) {
    final nameCtrl = TextEditingController(text: existingTest?.name);
    final codeCtrl = TextEditingController(text: existingTest?.testCode);
    final descCtrl = TextEditingController(text: existingTest?.description);
    final catCtrl = TextEditingController(text: existingTest?.category ?? 'Hematology');
    final priceCtrl = TextEditingController(text: existingTest?.price.toString());
    final sampleCtrl = TextEditingController(text: existingTest?.sampleType ?? 'Blood');
    final timeCtrl = TextEditingController(text: existingTest?.reportingTime ?? '24 hours');
    String selectedTemplate = existingTest?.templateId ?? (_templates.isNotEmpty ? _templates.first.id : '');
    bool isActive = existingTest?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingTest == null ? 'Add New Test' : 'Edit Test'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Test Name', isDense: true, border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Test Code (e.g. T001)', isDense: true, border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category', isDense: true, border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price (₹)', isDense: true, border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: sampleCtrl, decoration: const InputDecoration(labelText: 'Sample Type', isDense: true, border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Reporting Time', isDense: true, border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_templates.isNotEmpty) DropdownButtonFormField<String>(
                    value: selectedTemplate,
                    decoration: const InputDecoration(labelText: 'Assigned Template', isDense: true, border: OutlineInputBorder()),
                    items: _templates.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                    onChanged: (v) => setDialogState(() => selectedTemplate = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', isDense: true, border: OutlineInputBorder()), maxLines: 2),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Active Status'),
                    value: isActive,
                    onChanged: (val) => setDialogState(() => isActive = val),
                    activeColor: const Color(0xFFEA580C),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final test = LabTest(
                  id: existingTest?.id ?? const Uuid().v4(),
                  name: nameCtrl.text,
                  testCode: codeCtrl.text,
                  description: descCtrl.text,
                  category: catCtrl.text,
                  price: double.tryParse(priceCtrl.text) ?? 0,
                  templateId: selectedTemplate,
                  sampleType: sampleCtrl.text,
                  reportingTime: timeCtrl.text,
                  isActive: isActive,
                );
                await LabDataService.saveTest(test);
                if (mounted) Navigator.pop(context);
                _loadData();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
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
                    child: const Icon(Icons.science, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Lab Tests', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      SizedBox(height: 4),
                      Text('Manage laboratory tests, pricing, templates and configurations', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Dashboard > Lab Tests', style: TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddTestDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New Test'),
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
              _buildStatCard(Icons.science, 'Total Tests', '256', '+12% vs last month', Colors.green),
              const SizedBox(width: 16),
              _buildStatCard(Icons.category, 'Categories', '18', '+2%', Colors.green),
              const SizedBox(width: 16),
              _buildStatCard(Icons.description, 'Templates', '42', '+16%', Colors.green),
              const SizedBox(width: 16),
              _buildStatCard(Icons.inventory_2, 'Active Packages', '12', '+8%', Colors.green),
              const SizedBox(width: 16),
              _buildStatCard(Icons.bar_chart, 'Tests Performed', '1,245', '+20%', Colors.green),
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
                  flex: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tabs and Action buttons
                        Padding(
                          padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  _buildTab('All Tests', 0),
                                  const SizedBox(width: 24),
                                  _buildTab('By Category', 1),
                                  const SizedBox(width: 24),
                                  _buildTab('By Template', 2),
                                  const SizedBox(width: 24),
                                  _buildTab('Inactive Tests', 3),
                                ],
                              ),
                              Row(
                                children: [
                                  _buildActionButton(Icons.upload, 'Import (Excel)', () {}),
                                  const SizedBox(width: 8),
                                  _buildActionButton(Icons.download, 'Export', () {}),
                                  const SizedBox(width: 8),
                                  _buildActionButton(Icons.settings, 'Categories', () {}),
                                ],
                              )
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        
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
                                      hintText: 'Search test name, code or keyword...',
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
                              _buildDropdown('All Templates'),
                              const SizedBox(width: 12),
                              Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: const [
                                    Icon(Icons.refresh, size: 16, color: Color(0xFF64748B)),
                                    SizedBox(width: 8),
                                    Text('Reset', style: TextStyle(color: Color(0xFF1E293B))),
                                  ],
                                ),
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
                              Expanded(flex: 3, child: Text('Test Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              Expanded(flex: 2, child: Text('Test Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              Expanded(flex: 2, child: Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              Expanded(flex: 2, child: Text('Price (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              Expanded(flex: 2, child: Text('Template', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              Expanded(flex: 3, child: Center(child: Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))))),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        
                        // Table Body
                        Expanded(
                          child: _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C))) : ListView.separated(
                            itemCount: _tests.where((t) => t.name.toLowerCase().contains(_searchQuery) || t.testCode.toLowerCase().contains(_searchQuery)).length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            itemBuilder: (context, index) {
                              final filtered = _tests.where((t) => t.name.toLowerCase().contains(_searchQuery) || t.testCode.toLowerCase().contains(_searchQuery)).toList();
                              final test = filtered[index];
                              final isSelected = _selectedTest?.id == test.id;
                              
                              final templateName = _templates.where((t) => t.id == test.templateId).firstOrNull?.name ?? 'Unknown';

                              return InkWell(
                                onTap: () => setState(() => _selectedTest = test),
                                child: Container(
                                  color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 30, child: Text('${index + 1}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                                      Expanded(flex: 3, child: Text(test.name, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF1E293B)))),
                                      Expanded(flex: 2, child: Text(test.testCode.isEmpty ? '-' : test.testCode, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                                      Expanded(flex: 2, child: Text(test.category, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                                      Expanded(flex: 2, child: Text(test.price.toStringAsFixed(2), style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                                      Expanded(flex: 2, child: Text(templateName, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            Container(width: 8, height: 8, decoration: BoxDecoration(color: test.isActive ? Colors.green : Colors.red, shape: BoxShape.circle)),
                                            const SizedBox(width: 6),
                                            Text(test.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 13, color: test.isActive ? Colors.green : Colors.red)),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              _buildTableRowButton(Icons.visibility, 'View'),
                                              const SizedBox(width: 4),
                                              InkWell(onTap: () => _showAddTestDialog(existingTest: test), child: _buildTableRowButton(Icons.edit, 'Edit')),
                                              const SizedBox(width: 4),
                                              _buildTableRowButton(Icons.copy, 'Clone'),
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
                        ),
                        
                        // Pagination stub
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Showing 1 to 10 of 256 tests', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                              Row(
                                children: [
                                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.chevron_left, size: 16)),
                                  const SizedBox(width: 8),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFEA580C), borderRadius: BorderRadius.circular(4)), child: const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                  const SizedBox(width: 8),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)), child: const Text('2', style: TextStyle(color: Color(0xFF1E293B)))),
                                  const SizedBox(width: 8),
                                  const Text('...', style: TextStyle(color: Color(0xFF64748B))),
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
                
                // Right Pane: Detail view
                if (_selectedTest != null) Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Test Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              InkWell(
                                onTap: () => _showAddTestDialog(existingTest: _selectedTest),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.edit, size: 14, color: Color(0xFFEA580C)),
                                      SizedBox(width: 6),
                                      Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(_selectedTest!.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: _selectedTest!.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                                child: Row(
                                  children: [
                                    Container(width: 6, height: 6, decoration: BoxDecoration(color: _selectedTest!.isActive ? Colors.green : Colors.red, shape: BoxShape.circle)),
                                    const SizedBox(width: 4),
                                    Text(_selectedTest!.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _selectedTest!.isActive ? Colors.green : Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildDetailRow('Test Code', _selectedTest!.testCode),
                          _buildDetailRow('Category', _selectedTest!.category),
                          _buildDetailRow('Price (₹)', _selectedTest!.price.toStringAsFixed(2)),
                          _buildDetailRow('Template', _templates.where((t) => t.id == _selectedTest!.templateId).firstOrNull?.name ?? 'Unknown'),
                          _buildDetailRow('Sample Type', _selectedTest!.sampleType),
                          _buildDetailRow('Reporting Time', _selectedTest!.reportingTime),
                          _buildDetailRow('Description', _selectedTest!.description),
                          
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.science, size: 16),
                              label: const Text('Book This Test'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEA580C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          const Text('Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildQuickActionCard(Icons.edit, 'Edit Test', const Color(0xFFEA580C))),
                              const SizedBox(width: 8),
                              Expanded(child: _buildQuickActionCard(Icons.copy, 'Clone Test', const Color(0xFFEA580C))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildQuickActionCard(Icons.description, 'Manage Template', const Color(0xFFEA580C))),
                              const SizedBox(width: 8),
                              Expanded(child: _buildQuickActionCard(Icons.analytics, 'View Reports', const Color(0xFFEA580C))),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Related Packages', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFFEA580C), fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildRelatedPackage('Full Body Checkup', '32 Tests', '2,500'),
                          _buildRelatedPackage('Health Checkup Basic', '18 Tests', '1,499'),
                          _buildRelatedPackage('Diabetic Profile', '12 Tests', '999'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Summary Cards
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildBottomSummaryCard(Icons.description, 'Custom Templates', 'Create and customize report templates for each test')),
              const SizedBox(width: 16),
              Expanded(child: _buildBottomSummaryCard(Icons.inventory_2, 'Test Packages', 'Group tests with special pricing')),
              const SizedBox(width: 16),
              Expanded(child: _buildBottomSummaryCard(Icons.science, 'Sample Tracking', 'Track samples from collection to reporting')),
              const SizedBox(width: 16),
              Expanded(child: _buildBottomSummaryCard(Icons.analytics, 'Report Generation', 'Generate professional reports with your templates')),
              const SizedBox(width: 16),
              Expanded(child: _buildBottomSummaryCard(Icons.send, 'Send Reports', 'Send reports via WhatsApp, Email or SMS')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, String trend, Color trendColor) {
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
              decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 12, color: trendColor),
                          Text(trend.split(' ').first, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: trendColor)),
                        ],
                      )
                    ],
                  ),
                  Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  Text(trend.split(' ').skip(1).join(' '), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isSelected ? const Color(0xFFEA580C) : Colors.transparent, width: 2)),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFFEA580C)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint) {
    return Expanded(
      flex: 2,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(hint, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRowButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8), color: const Color(0xFFFFF7ED).withOpacity(0.5)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildRelatedPackage(String name, String tests, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.inventory_2, size: 16, color: Color(0xFFEA580C)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                Text(tests, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text('₹ $price', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
            child: const Icon(Icons.add, size: 14, color: Color(0xFFEA580C)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummaryCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFFEA580C), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
