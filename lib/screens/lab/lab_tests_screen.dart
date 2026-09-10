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
      _isLoading = false;
    });
  }

  void _showAddTestDialog({LabTest? existingTest}) {
    final nameCtrl = TextEditingController(text: existingTest?.name);
    final descCtrl = TextEditingController(text: existingTest?.description);
    final catCtrl = TextEditingController(text: existingTest?.category ?? 'General');
    final priceCtrl = TextEditingController(text: existingTest?.price.toString());
    String selectedTemplate = existingTest?.templateId ?? (_templates.isNotEmpty ? _templates.first.id : '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingTest == null ? 'Add New Test' : 'Edit Test'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Test Name')),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                  const SizedBox(height: 12),
                  TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category')),
                  const SizedBox(height: 12),
                  TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price (₹)'), keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedTemplate.isEmpty ? null : selectedTemplate,
                    decoration: const InputDecoration(labelText: 'Assigned Template'),
                    items: _templates.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedTemplate = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C)),
              onPressed: () async {
                final price = double.tryParse(priceCtrl.text) ?? 0;
                final test = LabTest(
                  id: existingTest?.id ?? const Uuid().v4(),
                  name: nameCtrl.text,
                  description: descCtrl.text,
                  category: catCtrl.text,
                  price: price,
                  templateId: selectedTemplate,
                );
                await LabDataService.saveTest(test);
                if (mounted) Navigator.pop(context);
                _loadData();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTests = _tests.where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()) || t.category.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text.rich(TextSpan(children: [TextSpan(text: 'Lab ', style: TextStyle(color: Color(0xFF1E293B))), TextSpan(text: 'Tests', style: TextStyle(color: Color(0xFFEA580C)))]), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Manage your laboratory test catalog, pricing, and assigned templates.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 300,
                    height: 52,
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: const InputDecoration(hintText: 'Search tests by name or category...', prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20), border: InputBorder.none, hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12), isDense: true, contentPadding: EdgeInsets.zero),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddTestDialog(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add New Test', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            color: const Color(0xFFF1F5F9),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text('Test Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                                Expanded(flex: 2, child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                                Expanded(flex: 2, child: Text('Price (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                                Expanded(flex: 2, child: Text('Template Assigned', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                                SizedBox(width: 40),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              itemCount: filteredTests.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                              itemBuilder: (context, index) {
                                final test = filteredTests[index];
                                final template = _templates.firstWhere((t) => t.id == test.templateId, orElse: () => LabTemplate(id: '', name: 'Unknown', fields: []));
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(test.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14)),
                                            const SizedBox(height: 4),
                                            Text(test.description, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      Expanded(flex: 2, child: Text(test.category, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                                      Expanded(flex: 2, child: Text('₹${test.price.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.bold))),
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(4)),
                                            child: Text(template.name, style: const TextStyle(color: Color(0xFFEA580C), fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 20),
                                          onSelected: (val) async {
                                            if (val == 'edit') {
                                              _showAddTestDialog(existingTest: test);
                                            } else if (val == 'delete') {
                                              await LabDataService.deleteTest(test.id);
                                              _loadData();
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(value: 'edit', child: Text('Edit Test')),
                                            const PopupMenuItem(value: 'delete', child: Text('Delete Test', style: TextStyle(color: Colors.red))),
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
                  ),
          ),
        ],
      ),
    );
  }
}
