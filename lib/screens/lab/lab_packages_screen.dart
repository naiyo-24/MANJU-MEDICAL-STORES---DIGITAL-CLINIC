import 'package:flutter/material.dart';
import '../../models/lab_models.dart';
import '../../services/lab_data_service.dart';
import 'package:uuid/uuid.dart';

class LabPackagesScreen extends StatefulWidget {
  const LabPackagesScreen({super.key});

  @override
  State<LabPackagesScreen> createState() => _LabPackagesScreenState();
}

class _LabPackagesScreenState extends State<LabPackagesScreen> {
  List<LabPackage> _packages = [];
  List<LabTest> _allTests = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final packages = await LabDataService.getPackages();
    final tests = await LabDataService.getTests();
    setState(() {
      _packages = packages;
      _allTests = tests;
      _isLoading = false;
    });
  }

  void _showAddPackageDialog({LabPackage? existingPackage}) {
    final nameCtrl = TextEditingController(text: existingPackage?.name);
    final descCtrl = TextEditingController(text: existingPackage?.description);
    final priceCtrl = TextEditingController(text: existingPackage?.discountedPrice.toString());
    List<String> selectedTestIds = existingPackage?.testIds.toList() ?? [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingPackage == null ? 'Create Package' : 'Edit Package'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Package Name')),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                  const SizedBox(height: 12),
                  TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Discounted Price (₹)'), keyboardType: TextInputType.number),
                  const SizedBox(height: 24),
                  const Text('Select Tests Included:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _allTests.length,
                      itemBuilder: (context, index) {
                        final test = _allTests[index];
                        final isSelected = selectedTestIds.contains(test.id);
                        return CheckboxListTile(
                          title: Text(test.name),
                          subtitle: Text('₹${test.price.toStringAsFixed(2)}'),
                          value: isSelected,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedTestIds.add(test.id);
                              } else {
                                selectedTestIds.remove(test.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Original Total: ₹${selectedTestIds.fold(0.0, (sum, id) => sum + (_allTests.firstWhere((t) => t.id == id, orElse: () => LabTest(id: '', name: '', description: '', category: '', price: 0, templateId: '')).price)).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
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
                final package = LabPackage(
                  id: existingPackage?.id ?? const Uuid().v4(),
                  name: nameCtrl.text,
                  description: descCtrl.text,
                  testIds: selectedTestIds,
                  discountedPrice: price,
                );
                await LabDataService.savePackage(package);
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
    final filteredPackages = _packages.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Health Packages', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ElevatedButton.icon(
                onPressed: () => _showAddPackageDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Create Package'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search packages...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: filteredPackages.length,
                    itemBuilder: (context, index) {
                      final package = filteredPackages[index];
                      final includedTests = _allTests.where((t) => package.testIds.contains(t.id)).toList();
                      final originalPrice = includedTests.fold(0.0, (sum, t) => sum + t.price);
                      
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(package.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                                Row(
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _showAddPackageDialog(existingPackage: package), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                    const SizedBox(width: 8),
                                    IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () async {
                                      await LabDataService.deletePackage(package.id);
                                      _loadData();
                                    }, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(package.description, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const Spacer(),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${includedTests.length} Tests Included', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹${originalPrice.toStringAsFixed(2)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Color(0xFF94A3B8), fontSize: 12)),
                                    Text('₹${package.discountedPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 18)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
