import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/responsive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'dart:typed_data';
import '../../models/lab_models.dart';
import '../../services/lab_data_service.dart';
import '../../providers/lab_providers.dart';
import '../../services/pdf_generator_service.dart';
import 'package:uuid/uuid.dart';
import 'package:printing/printing.dart';

class LabTestsScreen extends ConsumerStatefulWidget {
  const LabTestsScreen({super.key});

  @override
  ConsumerState<LabTestsScreen> createState() => _LabTestsScreenState();
}

class _LabTestsScreenState extends ConsumerState<LabTestsScreen> {
  List<LabTest> _tests = [];
  List<LabTemplate> _templates = [];
  List<LabPackage> _packages = [];
  List<String> _customCategories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();
  int _selectedTabIndex = 0;
  String? _selectedCategory;
  String? _selectedStatus;
  String? _selectedTemplate;
  LabTest? _selectedTest;

  List<String> get _allCategories {
    final fromTests = _tests.map((t) => t.category).where((c) => c.isNotEmpty).toSet().toList();
    return {...fromTests, ..._customCategories}.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await ref.read(labTestsProvider.notifier).loadTests();
    await ref.read(labTemplatesProvider.notifier).loadTemplates();
    await ref.read(labPackagesProvider.notifier).loadPackages();
    await ref.read(labCustomCategoriesProvider.notifier).loadCategories();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddTestDialog({LabTest? existingTest}) {
    final nameCtrl = TextEditingController(text: existingTest?.name);
    final codeCtrl = TextEditingController(text: existingTest?.testCode);
    final descCtrl = TextEditingController(text: existingTest?.description);
    String selectedCategory = existingTest?.category ?? (_allCategories.isNotEmpty ? _allCategories.first : 'Uncategorized');
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
                      Expanded(
                        child: _allCategories.isNotEmpty 
                          ? DropdownButtonFormField<String>(
                              value: _allCategories.contains(selectedCategory) ? selectedCategory : _allCategories.first,
                              decoration: const InputDecoration(labelText: 'Category', isDense: true, border: OutlineInputBorder()),
                              items: _allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (v) => setDialogState(() => selectedCategory = v!),
                            )
                          : TextField(
                              controller: TextEditingController(text: selectedCategory),
                              decoration: const InputDecoration(labelText: 'Category', isDense: true, border: OutlineInputBorder()),
                              onChanged: (v) => selectedCategory = v,
                            ),
                      ),
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
                  category: selectedCategory,
                  price: double.tryParse(priceCtrl.text) ?? 0,
                  templateId: selectedTemplate,
                  sampleType: sampleCtrl.text,
                  reportingTime: timeCtrl.text,
                  isActive: isActive,
                );
                await ref.read(labTestsProvider.notifier).addOrUpdateTest(test);
                if (mounted) Navigator.pop(context, );
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

  void _exportCSV() async {
    String csv = 'ID,Code,Name,Category,Price,Sample Type,Reporting Time,Status\n';
    for (var test in _tests) {
      csv += '${test.id},${test.testCode},${test.name},${test.category},${test.price},${test.sampleType},${test.reportingTime},${test.isActive ? 'Active' : 'Inactive'}\n';
    }
    final bytes = utf8.encode(csv);
    await FileSaver.instance.saveFile(name: 'lab_tests_export.csv', bytes: bytes);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV exported successfully!')));
  }

  void _exportExcel() async {
    var excel = Excel.createExcel();
    var sheet = excel['Sheet1'];
    sheet.appendRow([
      TextCellValue('ID'), TextCellValue('Code'), TextCellValue('Name'), TextCellValue('Category'), 
      TextCellValue('Price'), TextCellValue('Sample Type'), TextCellValue('Reporting Time'), TextCellValue('Status')
    ]);
    
    for (var test in _tests) {
      sheet.appendRow([
        TextCellValue(test.id), TextCellValue(test.testCode), TextCellValue(test.name), TextCellValue(test.category),
        TextCellValue(test.price.toString()), TextCellValue(test.sampleType), TextCellValue(test.reportingTime), 
        TextCellValue(test.isActive ? 'Active' : 'Inactive')
      ]);
    }
    
    final bytes = excel.encode();
    if (bytes != null) {
      await FileSaver.instance.saveFile(name: 'lab_tests_export.xlsx', bytes: Uint8List.fromList(bytes));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel exported successfully!')));
    }
  }

  void _exportPDF() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('SirfBill - Lab Catalog', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Code', 'Name', 'Category', 'Price', 'Sample'],
                data: _tests.map((t) => [t.testCode, t.name, t.category, t.price.toString(), t.sampleType]).toList(),
              ),
            ],
          );
        },
      ),
    );
    
    final bytes = await pdf.save();
    await FileSaver.instance.saveFile(name: 'lab_tests_export.pdf', bytes: bytes);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF exported successfully!')));
  }

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Export Format', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export as CSV'),
              onTap: () { Navigator.pop(context); _exportCSV(); },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.grid_on, color: Colors.blue),
              title: const Text('Export as Excel (.xlsx)'),
              onTap: () { Navigator.pop(context); _exportExcel(); },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              onTap: () { Navigator.pop(context); _exportPDF(); },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) => _CategoriesDialog(
        tests: _tests,
        onUpdate: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final testsAsync = ref.watch(labTestsProvider);
    final templatesAsync = ref.watch(labTemplatesProvider);
    final packagesAsync = ref.watch(labPackagesProvider);
    final customCategoriesAsync = ref.watch(labCustomCategoriesProvider);
    
    _tests = testsAsync.value ?? [];
    _templates = templatesAsync.value ?? [];
    _packages = packagesAsync.value ?? [];
    _customCategories = customCategoriesAsync.value ?? [];

    if (_tests.isNotEmpty && _selectedTest == null) {
      _selectedTest = _tests.first;
    }

    if (testsAsync.isLoading || templatesAsync.isLoading || packagesAsync.isLoading || customCategoriesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final filteredTests = _tests.where((t) {
      final matchesSearch = t.name.toLowerCase().contains(_searchQuery.toLowerCase()) || t.testCode.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == null || t.category == _selectedCategory;
      final matchesStatus = _selectedStatus == null || (_selectedStatus == 'Active' && t.isActive) || (_selectedStatus == 'Inactive' && !t.isActive);
      
      String? templateIdFilter;
      if (_selectedTemplate != null) {
        templateIdFilter = _templates.where((temp) => temp.name == _selectedTemplate).firstOrNull?.id;
      }
      final matchesTemplate = _selectedTemplate == null || t.templateId == templateIdFilter;
      
      bool matchesTab = true;
      if (_selectedTabIndex == 3) {
        matchesTab = !t.isActive;
      }
      
      return matchesSearch && matchesCategory && matchesStatus && matchesTemplate && matchesTab;
    }).toList();

    final totalPages = (filteredTests.length + _itemsPerPage - 1) ~/ _itemsPerPage;
    if (_currentPage > totalPages && totalPages > 0) _currentPage = totalPages;
    final startIndex = filteredTests.isEmpty ? 0 : (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filteredTests.length);
    final paginatedTests = filteredTests.isEmpty ? <LabTest>[] : filteredTests.sublist(startIndex, endIndex);


    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(24.0),
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
                          child: const Icon(Icons.science, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Lab Tests', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              SizedBox(height: 4),
                              Text('Manage laboratory tests, pricing, templates and configurations', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        const Text('Dashboard > Lab Tests', style: TextStyle(color: Color(0xFF64748B))),
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
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFEA580C), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.science, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Lab Tests', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                SizedBox(height: 4),
                                Text('Manage laboratory tests, pricing, templates and configurations', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Text('Dashboard > Lab Tests', style: TextStyle(color: Color(0xFF64748B))),
                        const SizedBox(width: 24),
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
          !Responsive.isDesktop(context)
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(width: 200, child: _buildStatCard(Icons.science, 'Total Tests', '${_tests.length}', '', Colors.green)),
                      const SizedBox(width: 16),
                      SizedBox(width: 200, child: _buildStatCard(Icons.category, 'Categories', '${_tests.map((t) => t.category).toSet().length}', '', Colors.green)),
                      const SizedBox(width: 16),
                      SizedBox(width: 200, child: _buildStatCard(Icons.description, 'Templates', '0', '', Colors.green)),
                      const SizedBox(width: 16),
                      SizedBox(width: 200, child: _buildStatCard(Icons.inventory_2, 'Active Packages', '0', '', Colors.green)),
                      const SizedBox(width: 16),
                      SizedBox(width: 200, child: _buildStatCard(Icons.bar_chart, 'Tests Performed', '0', '', Colors.green)),
                    ],
                  ),
                )
              : Row(
                  children: [
                    Expanded(child: _buildStatCard(Icons.science, 'Total Tests', '${_tests.length}', '', Colors.green)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(Icons.category, 'Categories', '${_tests.map((t) => t.category).toSet().length}', '', Colors.green)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(Icons.description, 'Templates', '0', '', Colors.green)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(Icons.inventory_2, 'Active Packages', '0', '', Colors.green)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(Icons.bar_chart, 'Tests Performed', '0', '', Colors.green)),
                  ],
                ),
          const SizedBox(height: 24),

          // Main Layout
          ResponsiveSplitView(
            leftFlex: 12,
            rightFlex: 4,
            showRightPane: _selectedTest != null,
              leftPane: Container(
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
                          child: Responsive.isMobile(context)
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
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
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildActionButton(Icons.upload, 'Import (Excel)', () async {
                                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                                            type: FileType.custom,
                                            allowedExtensions: ['csv'],
                                            withData: true,
                                          );
                                          
                                          if (result != null && mounted) {
                                            setState(() => _isLoading = true);
                                            final bytes = result.files.single.bytes;
                                            final name = result.files.single.name;
                                            if (bytes != null) {
                                              final success = await LabDataService.uploadCSV(bytes, name);
                                              if (success && mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tests imported successfully!')));
                                                _loadData();
                                              } else if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to import tests. Please check CSV format.')));
                                                setState(() => _isLoading = false);
                                              }
                                            }
                                          }
                                        }),
                                        _buildActionButton(Icons.download, 'Export', () {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export functionality coming soon')));
                                        }),
                                        _buildActionButton(Icons.settings, 'Categories', _showCategoriesDialog),
                                      ],
                                    ),
                                  ],
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      _buildTab('All Tests', 0),
                                      const SizedBox(width: 24),
                                      _buildTab('By Category', 1),
                                      const SizedBox(width: 24),
                                      _buildTab('By Template', 2),
                                      const SizedBox(width: 24),
                                      _buildTab('Inactive Tests', 3),
                                      const SizedBox(width: 24),
                                      _buildActionButton(Icons.upload, 'Import (Excel)', () async {
                                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: ['csv'],
                                          withData: true,
                                        );
                                        
                                        if (result != null && mounted) {
                                          setState(() => _isLoading = true);
                                          final bytes = result.files.single.bytes;
                                          final name = result.files.single.name;
                                          if (bytes != null) {
                                            final success = await LabDataService.uploadCSV(bytes, name);
                                            if (success && mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tests imported successfully!')));
                                              _loadData();
                                            } else if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to import tests. Please check CSV format.')));
                                              setState(() => _isLoading = false);
                                            }
                                          }
                                        }
                                      }),
                                      const SizedBox(width: 8),
                                      _buildActionButton(Icons.download, 'Export', () {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export functionality coming soon')));
                                      }),
                                      const SizedBox(width: 8),
                                      _buildActionButton(Icons.settings, 'Categories', _showCategoriesDialog),
                                    ],
                                  ),
                                ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        
                        // Filters
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Responsive.isMobile(context)
                              ? Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 40,
                                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: (val) => setState(() => _searchQuery = val),
                                        decoration: const InputDecoration(hintText: 'Search test name, code or keyword...', hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)), prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                      ),
                                    ),
                                    _buildDropdown('All Categories', _allCategories, _selectedCategory, (v) => setState(() => _selectedCategory = v)),
                                    _buildDropdown('All Status', ['Active', 'Inactive'], _selectedStatus, (v) => setState(() => _selectedStatus = v)),
                                    _buildDropdown('All Templates', _templates.map((t) => t.name).toList(), _selectedTemplate, (v) => setState(() => _selectedTemplate = v)),
                                    if (_searchQuery.isNotEmpty || _selectedCategory != null || _selectedStatus != null || _selectedTemplate != null)
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _searchController.clear();
                                            _searchQuery = '';
                                            _selectedCategory = null;
                                            _selectedStatus = null;
                                            _selectedTemplate = null;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.refresh, size: 16, color: Color(0xFF64748B)), SizedBox(width: 8), Text('Reset', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))]),
                                        ),
                                      ),
                                  ],
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 250,
                                        height: 40,
                                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                                        child: TextField(
                                          controller: _searchController,
                                          onChanged: (val) => setState(() => _searchQuery = val),
                                          decoration: const InputDecoration(hintText: 'Search test name, code or keyword...', hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)), prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      _buildDropdown('All Categories', _allCategories, _selectedCategory, (v) => setState(() => _selectedCategory = v)),
                                      const SizedBox(width: 16),
                                      _buildDropdown('All Status', ['Active', 'Inactive'], _selectedStatus, (v) => setState(() => _selectedStatus = v)),
                                      const SizedBox(width: 16),
                                      _buildDropdown('All Templates', _templates.map((t) => t.name).toList(), _selectedTemplate, (v) => setState(() => _selectedTemplate = v)),
                                      if (_searchQuery.isNotEmpty || _selectedCategory != null || _selectedStatus != null || _selectedTemplate != null) ...[
                                        const SizedBox(width: 16),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _searchController.clear();
                                              _searchQuery = '';
                                              _selectedCategory = null;
                                              _selectedStatus = null;
                                              _selectedTemplate = null;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.refresh, size: 16, color: Color(0xFF64748B)), SizedBox(width: 8), Text('Reset', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))]),
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                        ),
                        
                        // Table Header & Body
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final tableWidth = constraints.maxWidth > 800 ? constraints.maxWidth : 800.0;
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: tableWidth,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
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
                                    _isLoading ? const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: Color(0xFFEA580C)))) : ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: paginatedTests.length,
                                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                      itemBuilder: (context, index) {
                                          final test = paginatedTests[index];
                                          final isSelected = _selectedTest?.id == test.id;
                                          
                                          final templateName = _templates.where((t) => t.id == test.templateId).firstOrNull?.name ?? 'Unknown';

                                          return InkWell(
                                            onTap: () => setState(() => _selectedTest = test),
                                            child: Container(
                                              color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                              child: Row(
                                                children: [
                                                  SizedBox(width: 30, child: Text('${startIndex + index + 1}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
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
                                                          _buildTableRowButton(
                                                            Icons.visibility, 
                                                            'View', 
                                                            onTap: () {
                                                              setState(() => _selectedTest = test);
                                                              showDialog(
                                                                context: context,
                                                                builder: (context) => AlertDialog(
                                                                  title: const Text('Test Details', style: TextStyle(fontWeight: FontWeight.bold)),
                                                                  content: SizedBox(
                                                                    width: 400,
                                                                    child: Column(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        _buildDetailRow('Name', test.name),
                                                                        _buildDetailRow('Code', test.testCode),
                                                                        _buildDetailRow('Category', test.category),
                                                                        _buildDetailRow('Price', '₹${test.price}'),
                                                                        _buildDetailRow('Sample Type', test.sampleType),
                                                                        _buildDetailRow('Reporting Time', test.reportingTime),
                                                                        _buildDetailRow('Status', test.isActive ? 'Active' : 'Inactive'),
                                                                        _buildDetailRow('Description', test.description),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  actions: [
                                                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
                                                                  ]
                                                                )
                                                              );
                                                            }
                                                          ),
                                                          const SizedBox(width: 4),
                                                          _buildTableRowButton(
                                                            Icons.edit, 
                                                            'Edit', 
                                                            onTap: () => _showAddTestDialog(existingTest: test)
                                                          ),
                                                          const SizedBox(width: 4),
                                                          _buildTableRowButton(
                                                            Icons.copy, 
                                                            'Clone', 
                                                            onTap: () {
                                                              final cloned = LabTest(
                                                                id: '',
                                                                name: '${test.name} - Copy',
                                                                testCode: '${test.testCode}_COPY',
                                                                description: test.description,
                                                                category: test.category,
                                                                price: test.price,
                                                                templateId: test.templateId,
                                                                sampleType: test.sampleType,
                                                                reportingTime: test.reportingTime,
                                                                isActive: test.isActive,
                                                              );
                                                              _showAddTestDialog(existingTest: cloned);
                                                            }
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
                                    
                                    // Pagination stub
                                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      child: Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        runSpacing: 12,
                                        children: [
                                          Text('Showing ${filteredTests.isEmpty ? 0 : startIndex + 1} to $endIndex of ${filteredTests.length} tests', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
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
                            );
                          },
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
                    child: _selectedTest == null
                        ? const Padding(padding: EdgeInsets.all(48), child: Text('Select a test to view details', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8))))
                        : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 8,
                            children: [
                              const Text('Test Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              InkWell(
                                onTap: () => _showAddTestDialog(existingTest: _selectedTest),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
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
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking feature coming soon!')));
                              },
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
                              Expanded(
                                child: _buildQuickActionCard(
                                  Icons.edit, 
                                  'Edit Test', 
                                  const Color(0xFFEA580C),
                                  onTap: () {
                                    if (_selectedTest != null) {
                                      _showAddTestDialog(existingTest: _selectedTest);
                                    }
                                  }
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildQuickActionCard(
                                  Icons.copy, 
                                  'Clone Test', 
                                  const Color(0xFFEA580C),
                                  onTap: () {
                                    if (_selectedTest != null) {
                                      final cloned = LabTest(
                                        id: '',
                                        name: '${_selectedTest!.name} - Copy',
                                        testCode: '${_selectedTest!.testCode}_COPY',
                                        description: _selectedTest!.description,
                                        category: _selectedTest!.category,
                                        price: _selectedTest!.price,
                                        templateId: _selectedTest!.templateId,
                                        sampleType: _selectedTest!.sampleType,
                                        reportingTime: _selectedTest!.reportingTime,
                                        isActive: _selectedTest!.isActive,
                                      );
                                      _showAddTestDialog(existingTest: cloned);
                                    }
                                  }
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionCard(
                                  Icons.description, 
                                  'Manage Template', 
                                  const Color(0xFFEA580C),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please navigate to the Templates tab to manage templates.')));
                                  }
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildQuickActionCard(
                                  Icons.analytics, 
                                  'View Reports', 
                                  const Color(0xFFEA580C),
                                  onTap: () async {
                                    try {
                                      final template = _templates.firstWhere((t) => t.id == _selectedTest!.templateId, orElse: () => LabTemplate(id: '', name: 'Empty Template'));
                                      
                                      final patientData = {
                                        'patientName': 'Chitra Paul',
                                        'age': '63',
                                        'gender': 'Female',
                                        'patientId': 'PID-2026',
                                        'referredBy': 'Dr. Anunita Mitra Banerjee',
                                        'sampleId': 'SID-478',
                                        'sampleType': _selectedTest!.sampleType,
                                        'collectionDate': '22/06/2026',
                                        'reportingDate': '22/06/2026',
                                      };
                                      
                                      final pdfBytes = await PdfGeneratorService.generateReport(_selectedTest!, template, patientData);
                                      
                                      if (!context.mounted) return;
                                      
                                      showDialog(
                                        context: context,
                                        builder: (context) => Dialog(
                                          child: SizedBox(
                                            width: 800,
                                            height: 800,
                                            child: PdfPreview(
                                              build: (format) => pdfBytes,
                                              canChangeOrientation: false,
                                              canChangePageFormat: false,
                                              canDebug: false,
                                              allowSharing: true,
                                              allowPrinting: true,
                                            )
                                          )
                                        )
                                      );
                                    } catch (e) {
                                      print(e);
                                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
                                    }
                                  }
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Expanded(child: Text('Related Packages', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                              SizedBox(width: 8),
                              Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFFEA580C), fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_packages.where((p) => p.testIds.contains(_selectedTest!.id)).isEmpty)
                            const Text('No related packages found.', style: TextStyle(color: Colors.grey, fontSize: 13))
                          else
                            ..._packages.where((p) => p.testIds.contains(_selectedTest!.id)).take(3).map((pkg) => _buildRelatedPackage(pkg.name, '${pkg.testIds.length} Tests', pkg.discountedPrice.toString())),
                        ],
                      ),
                    ),
                  ),
            ),
          
          // Bottom Summary Cards
          const SizedBox(height: 24),
          !Responsive.isDesktop(context)
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(width: 240, child: _buildBottomSummaryCard(Icons.description, 'Custom Templates', 'Create and customize report templates for each test')),
                      const SizedBox(width: 16),
                      SizedBox(width: 240, child: _buildBottomSummaryCard(Icons.inventory_2, 'Test Packages', 'Group tests with special pricing')),
                      const SizedBox(width: 16),
                      SizedBox(width: 240, child: _buildBottomSummaryCard(Icons.science, 'Sample Tracking', 'Track samples from collection to reporting')),
                      const SizedBox(width: 16),
                      SizedBox(width: 240, child: _buildBottomSummaryCard(Icons.analytics, 'Report Generation', 'Generate professional reports with your templates')),
                      const SizedBox(width: 16),
                      SizedBox(width: 240, child: _buildBottomSummaryCard(Icons.send, 'Send Reports', 'Send reports via WhatsApp, Email or SMS')),
                    ],
                  ),
                )
              : Row(
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
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, String trend, Color trendColor) {
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFEA580C)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Container(
      width: 180,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            hint: Text(hint, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            value: value,
            icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
            items: [
              DropdownMenuItem<String>(value: null, child: Text(hint, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
              ...items.map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
              ))
            ],
            onChanged: onChanged,
          ),
        ),
    );
  }

  Widget _buildTableRowButton(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8), color: const Color(0xFFFFF7ED).withOpacity(0.5)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              ),
            ),
          ],
        ),
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
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text('₹ $price', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                  child: const Icon(Icons.add, size: 14, color: Color(0xFFEA580C)),
                ),
              ],
            ),
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

class _CategoriesDialog extends ConsumerStatefulWidget {
  final List<LabTest> tests;
  final VoidCallback onUpdate;

  const _CategoriesDialog({Key? key, required this.tests, required this.onUpdate}) : super(key: key);

  @override
  ConsumerState<_CategoriesDialog> createState() => _CategoriesDialogState();
}

class _CategoriesDialogState extends ConsumerState<_CategoriesDialog> {
  List<String> _customCategories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final custom = await LabDataService.getCustomCategories();
    if (mounted) {
      setState(() {
        _customCategories = custom;
      });
    }
  }

  List<String> get _allCategories {
    final fromTests = widget.tests.map((t) => t.category).where((c) => c.isNotEmpty).toSet().toList();
    return {...fromTests, ..._customCategories}.toList()..sort();
  }

  void _addCategory() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Category Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await ref.read(labCustomCategoriesProvider.notifier).addCategory(ctrl.text.trim());
                if (mounted) Navigator.pop(ctx);
                _loadCategories();
                widget.onUpdate();
              }
            },
            child: const Text('Add'),
          )
        ],
      )
    );
  }

  void _editCategory(String oldName) {
    final ctrl = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Category Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                
                await ref.read(labCustomCategoriesProvider.notifier).renameCategory(oldName, newName);
                
                // Bulk update tests
                final testsToUpdate = widget.tests.where((t) => t.category == oldName).toList();
                for (var test in testsToUpdate) {
                  test.category = newName;
                  await ref.read(labTestsProvider.notifier).addOrUpdateTest(test);
                }
                
                _loadCategories();
                widget.onUpdate();
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Rename'),
          )
        ],
      )
    );
  }

  void _deleteCategory(String name) {
    final testCount = widget.tests.where((t) => t.category == name).length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(testCount > 0 
          ? 'This will move $testCount tests to "Uncategorized". Are you sure?'
          : 'Are you sure you want to delete this category?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              
              await ref.read(labCustomCategoriesProvider.notifier).deleteCategory(name);
              
              final testsToUpdate = widget.tests.where((t) => t.category == name).toList();
              for (var test in testsToUpdate) {
                test.category = 'Uncategorized';
                await ref.read(labTestsProvider.notifier).addOrUpdateTest(test);
              }
              
              _loadCategories();
              widget.onUpdate();
              if (mounted) setState(() => _isLoading = false);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _allCategories;
    
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Manage Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.add, color: Color(0xFFEA580C)), onPressed: _addCategory),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 400,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty 
            ? const Center(child: Text('No categories found', style: TextStyle(color: Colors.grey)))
            : ListView.separated(
              itemCount: categories.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final count = widget.tests.where((t) => t.category == cat).length;
                return ListTile(
                  leading: const Icon(Icons.folder, color: Color(0xFFEA580C)),
                  title: Text(cat),
                  subtitle: Text('$count tests', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blue), onPressed: () => _editCategory(cat)),
                      IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _deleteCategory(cat)),
                    ],
                  ),
                );
              },
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
