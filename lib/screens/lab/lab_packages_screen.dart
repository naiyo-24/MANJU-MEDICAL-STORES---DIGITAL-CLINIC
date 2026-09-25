import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/responsive.dart';
import '../../models/lab_models.dart';
import '../../providers/lab_providers.dart';
import 'package:uuid/uuid.dart';

class LabPackagesScreen extends ConsumerStatefulWidget {
  const LabPackagesScreen({super.key});

  @override
  ConsumerState<LabPackagesScreen> createState() => _LabPackagesScreenState();
}

class _LabPackagesScreenState extends ConsumerState<LabPackagesScreen> {
  List<LabPackage> _packages = [];
  List<LabTest> _allTests = [];
  bool _isLoading = true;
  String _searchQuery = '';
  LabPackage? _selectedPackage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await ref.read(labPackagesProvider.notifier).loadPackages();
    await ref.read(labTestsProvider.notifier).loadTests();
    setState(() {
      _isLoading = false;
    });
  }

  void _showAddPackageDialog({LabPackage? existingPackage}) {
    final nameCtrl = TextEditingController(text: existingPackage?.name);
    final categoryCtrl = TextEditingController(
      text: existingPackage?.category ?? 'Wellness',
    );
    final descCtrl = TextEditingController(text: existingPackage?.description);
    final priceCtrl = TextEditingController(
      text: existingPackage?.discountedPrice.toString(),
    );
    bool isActive = existingPackage?.isActive ?? true;
    List<String> selectedTestIds = existingPackage?.testIds.toList() ?? [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existingPackage == null ? 'Create Package' : 'Edit Package',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Package Name',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: categoryCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Price (₹)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SwitchListTile(
                          title: const Text(
                            'Active Status',
                            style: TextStyle(fontSize: 14),
                          ),
                          value: isActive,
                          onChanged: (val) =>
                              setDialogState(() => isActive = val),
                          activeThumbColor: const Color(0xFFEA580C),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Tests Included:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _allTests.length,
                      itemBuilder: (context, index) {
                        final test = _allTests[index];
                        final isSelected = selectedTestIds.contains(test.id);
                        return CheckboxListTile(
                          title: Text(
                            test.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '₹${test.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                          value: isSelected,
                          activeColor: const Color(0xFFEA580C),
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
                    'Original Total: ₹${selectedTestIds.fold(0.0, (sum, id) => sum + (_allTests.firstWhere(
                          (t) => t.id == id,
                          orElse: () => LabTest(id: '', name: '', description: '', category: '', price: 0, templateId: ''),
                        ).price)).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final pkg = LabPackage(
                  id: existingPackage?.id ?? const Uuid().v4(),
                  name: nameCtrl.text,
                  category: categoryCtrl.text,
                  description: descCtrl.text,
                  testIds: selectedTestIds,
                  discountedPrice: double.tryParse(priceCtrl.text) ?? 0.0,
                  isActive: isActive,
                );
                await ref
                    .read(labPackagesProvider.notifier)
                    .addOrUpdatePackage(pkg);
                // ignore: use_build_context_synchronously
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

  Widget _buildStatCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
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
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Text(
                      '↑+20%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Color(0xFF64748B),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: const Color(0xFF64748B)),
      label: Text(
        label,
        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildTableRowButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          if (label.isNotEmpty) const SizedBox(width: 4),
          if (label.isNotEmpty)
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String title) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFEA580C), size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFEA580C),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(labPackagesProvider);
    final testsAsync = ref.watch(labTestsProvider);

    _packages = packagesAsync.value ?? [];
    _allTests = testsAsync.value ?? [];

    if (_packages.isNotEmpty && _selectedPackage == null) {
      _selectedPackage = _packages.first;
    }

    if (packagesAsync.isLoading || testsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    int totalPackages = _packages.length;
    int activePackages = _packages.where((p) => p.isActive).length;
    int inactivePackages = totalPackages - activePackages;

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
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Packages',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Create and manage test packages with custom pricing',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddPackageDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create New Package'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats Row
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 250,
                child: _buildStatCard(
                  Icons.inventory_2,
                  'Total Packages',
                  totalPackages.toString(),
                  const Color(0xFFEA580C),
                ),
              ),
              SizedBox(
                width: 250,
                child: _buildStatCard(
                  Icons.check_circle,
                  'Active Packages',
                  activePackages.toString(),
                  Colors.green,
                ),
              ),
              SizedBox(
                width: 250,
                child: _buildStatCard(
                  Icons.pause_circle,
                  'Inactive Packages',
                  inactivePackages.toString(),
                  Colors.red,
                ),
              ),
              SizedBox(
                width: 250,
                child: _buildStatCard(
                  Icons.group,
                  'Package Tests Booked',
                  '1,248',
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Content Layout
          Expanded(
            child: ResponsiveSplitView(
              leftFlex: 6,
              rightFlex: 3,
              showRightPane: _selectedPackage != null,
              leftPane: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search & Filters
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              width: 250,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: TextField(
                                onChanged: (v) => setState(
                                  () => _searchQuery = v.toLowerCase(),
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Search package name...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            _buildDropdown('All Categories'),
                            _buildDropdown('All Status'),
                            _buildActionButton(Icons.refresh, 'Reset', () {}),
                            _buildActionButton(
                              Icons.download,
                              'Export (Excel)',
                              () {},
                            ),
                          ],
                        ),
                      ),

                      // Table Header
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 800),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                color: const Color(0xFFF8FAFC),
                                child: Row(
                                  children: const [
                                    SizedBox(
                                      width: 30,
                                      child: Text(
                                        '#',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Package Name',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Category',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Tests Included',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Price (₹)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Status',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Center(
                                        child: Text(
                                          'Action',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(
                                height: 1,
                                color: Color(0xFFE2E8F0),
                              ),

                              // Table Body
                              _isLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFEA580C),
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _packages
                                          .where(
                                            (p) => p.name
                                                .toLowerCase()
                                                .contains(_searchQuery),
                                          )
                                          .length,
                                      separatorBuilder: (context, index) =>
                                          const Divider(
                                            height: 1,
                                            color: Color(0xFFE2E8F0),
                                          ),
                                      itemBuilder: (context, index) {
                                        final filtered = _packages
                                            .where(
                                              (p) => p.name
                                                  .toLowerCase()
                                                  .contains(_searchQuery),
                                            )
                                            .toList();
                                        final package = filtered[index];
                                        final isSelected =
                                            _selectedPackage?.id == package.id;

                                        return InkWell(
                                          onTap: () => setState(
                                            () => _selectedPackage = package,
                                          ),
                                          child: Container(
                                            color: isSelected
                                                ? const Color(0xFFFFF7ED)
                                                : Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 16,
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 30,
                                                  child: Text(
                                                    '${index + 1}',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    package.name,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      color: const Color(
                                                        0xFF1E293B,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    package.category,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    '${package.testIds.length} Tests',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF2563EB),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    package.discountedPrice
                                                        .toStringAsFixed(2),
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration:
                                                            BoxDecoration(
                                                              color:
                                                                  package
                                                                      .isActive
                                                                  ? Colors.green
                                                                  : Colors.red,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              package.isActive
                                                              ? Colors.green
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    )
                                                              : Colors.red
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          package.isActive
                                                              ? 'Active'
                                                              : 'Inactive',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                package.isActive
                                                                ? Colors.green
                                                                : Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: SingleChildScrollView(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        _buildTableRowButton(
                                                          Icons.visibility,
                                                          '',
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        InkWell(
                                                          onTap: () =>
                                                              _showAddPackageDialog(
                                                                existingPackage:
                                                                    package,
                                                              ),
                                                          child:
                                                              _buildTableRowButton(
                                                                Icons.edit,
                                                                '',
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        _buildTableRowButton(
                                                          Icons.copy,
                                                          '',
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        InkWell(
                                                          onTap: () async {
                                                            await ref
                                                                .read(
                                                                  labPackagesProvider
                                                                      .notifier,
                                                                )
                                                                .deletePackage(
                                                                  package.id,
                                                                );
                                                            if (context.mounted) {
                                                              Navigator.pop(
                                                                context,
                                                              );
                                                            }
                                                          },
                                                          child:
                                                              _buildTableRowButton(
                                                                Icons.delete,
                                                                '',
                                                              ),
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
                            ],
                          ),
                        ),
                      ),

                      // Pagination
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            Text(
                              'Showing 1 to 10 of $totalPackages packages',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.chevron_left,
                                    size: 16,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEA580C),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '1',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '2',
                                    style: TextStyle(color: Color(0xFF1E293B)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right,
                                    size: 16,
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
              rightPane: SingleChildScrollView(
                child: Column(
                  children: [
                    // Package Details Card
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFEA580C,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2,
                                      color: Color(0xFFEA580C),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Package Details',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  if (_selectedPackage != null) {
                                    _showAddPackageDialog(
                                      existingPackage: _selectedPackage!,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.edit, size: 14),
                                label: const Text('Edit'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFEA580C),
                                  side: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (_selectedPackage != null) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow(
                                        'Package Name',
                                        _selectedPackage!.name,
                                      ),
                                      _buildDetailRow(
                                        'Category',
                                        _selectedPackage!.category,
                                      ),
                                      _buildDetailRow(
                                        'Price (₹)',
                                        _selectedPackage!.discountedPrice
                                            .toStringAsFixed(2),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(
                                              width: 100,
                                              child: Text(
                                                'Status',
                                                style: TextStyle(
                                                  color: Color(0xFF64748B),
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    _selectedPackage!.isActive
                                                    ? Colors.green.withValues(
                                                        alpha: 0.1,
                                                      )
                                                    : Colors.red.withValues(
                                                        alpha: 0.1,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          _selectedPackage!
                                                              .isActive
                                                          ? Colors.green
                                                          : Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _selectedPackage!.isActive
                                                        ? 'Active'
                                                        : 'Inactive',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          _selectedPackage!
                                                              .isActive
                                                          ? Colors.green
                                                          : Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _buildDetailRow(
                                        'Total Tests',
                                        _selectedPackage!.testIds.length
                                            .toString(),
                                      ),
                                    ],
                                  ),
                                ),
                                // Mock graphic placeholder
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.medical_services,
                                        color: Color(0xFF3B82F6),
                                        size: 40,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Health Package',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF1E3A8A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Description',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedPackage!.description,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildTrustBadge(Icons.verified, 'Accurate'),
                                _buildTrustBadge(
                                  Icons.local_offer,
                                  'Affordable',
                                ),
                                _buildTrustBadge(Icons.favorite, 'Trusted'),
                              ],
                            ),
                          ] else ...[
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'Select a package to view details',
                                  style: TextStyle(color: Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tests included list
                    if (_selectedPackage != null)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tests in this Package (${_selectedPackage!.testIds.length})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.add, size: 14),
                                    label: const Text(
                                      'Add Test',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEA580C),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              color: const Color(0xFFF8FAFC),
                              child: Row(
                                children: const [
                                  SizedBox(
                                    width: 20,
                                    child: Text(
                                      '#',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Test Name',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Category',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Action',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _selectedPackage!.testIds.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFE2E8F0),
                                  ),
                              itemBuilder: (context, index) {
                                final testId = _selectedPackage!.testIds[index];
                                final test = _allTests.firstWhere(
                                  (t) => t.id == testId,
                                  orElse: () => LabTest(
                                    id: '',
                                    name: 'Unknown Test',
                                    description: '',
                                    category: 'Unknown',
                                    price: 0,
                                    templateId: '',
                                  ),
                                );
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          test.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          test.category,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {},
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.red.shade100,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.delete_outline,
                                            size: 14,
                                            color: Colors.red.shade400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
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

          // Quick Actions Row
          Row(
            children: [
              Container(
                width: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.add, 'Create Package'),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.copy, 'Duplicate Package'),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.upload, 'Import Packages'),
              const SizedBox(width: 16),
              _buildQuickAction(Icons.download, 'Download List'),
            ],
          ),
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
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFEA580C), size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
