import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/manufacturer.dart';
import '../../providers/counter_providers.dart';
import '../../providers/manufacturer_provider.dart';
import 'widgets/manufacturers/add_manufacturer_dialog.dart';
import 'widgets/manufacturers/edit_manufacturer_dialog.dart';
import '../../services/export_service.dart';

class ManufacturersScreen extends ConsumerStatefulWidget {
  const ManufacturersScreen({super.key});

  @override
  ConsumerState<ManufacturersScreen> createState() =>
      _ManufacturersScreenState();
}

class _ManufacturersScreenState extends ConsumerState<ManufacturersScreen> {
  String _searchQuery = '';

  void _showAddDialog() {
    showDialog<Manufacturer>(
      context: context,
      builder: (context) => const AddManufacturerDialog(),
    );
  }

  void _showEditDialog(Manufacturer mfg) {
    showDialog(
      context: context,
      builder: (context) => EditManufacturerDialog(manufacturer: mfg),
    );
  }

  void _showDeleteDialog(Manufacturer mfg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = mfg.shortCode != null && mfg.shortCode!.isNotEmpty
        ? '${mfg.name} (${mfg.shortCode})'
        : mfg.name;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Manufacturer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$title"? Active medicines linked to this manufacturer will retain their text label.',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await ref
                    .read(manufacturerProvider.notifier)
                    .deleteManufacturer(mfg.id);
                if (mounted) {
                  nav.pop();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Manufacturer deleted successfully'),
                      backgroundColor: Color(0xFF166534),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete manufacturer: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(String type, List<Manufacturer> filtered,
      int Function(Manufacturer) getMappedCount) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dataToExport = filtered
        .map((m) => {
              'Name': m.name,
              'Short Code': m.shortCode ?? '',
              'Mapped Medicines': getMappedCount(m),
            })
        .toList();

    final settings = ref.read(settingsProvider).value ?? {};

    if (type == 'csv') {
      await ExportService.exportToCSV(dataToExport, 'Manufacturers_$timestamp');
    } else if (type == 'excel') {
      await ExportService.exportToExcel(
          dataToExport, 'Manufacturers_$timestamp');
    } else if (type == 'pdf') {
      await ExportService.exportToPDF(
          dataToExport, 'Manufacturers_$timestamp', settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manufacturersAsync = ref.watch(manufacturerProvider);
    final allManufacturers = manufacturersAsync.value ?? [];
    final inventoryItems = ref.watch(inventoryProvider).value ?? [];

    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? allManufacturers
        : allManufacturers.where((m) {
            final name = m.name.toLowerCase();
            final code = (m.shortCode ?? '').toLowerCase();
            return name.contains(query) || code.contains(query);
          }).toList();

    // Set of registered manufacturer identifiers for true association
    final registeredMfgIds = allManufacturers.map((m) => m.id).toSet();
    final registeredMfgNames =
        allManufacturers.map((m) => m.name.toLowerCase().trim()).toSet();

    // Compute medicine counts per manufacturer
    final Map<String, int> medicineCountsByMfgId = {};
    final Map<String, int> medicineCountsByName = {};
    int totalMappedMedicines = 0;

    for (final item in inventoryItems) {
      bool isItemMapped = false;
      if (item.manufacturerId != null &&
          registeredMfgIds.contains(item.manufacturerId)) {
        medicineCountsByMfgId[item.manufacturerId!] =
            (medicineCountsByMfgId[item.manufacturerId!] ?? 0) + 1;
        isItemMapped = true;
      }
      if (item.manufacturer.isNotEmpty) {
        final lower = item.manufacturer.toLowerCase().trim();
        if (registeredMfgNames.contains(lower)) {
          medicineCountsByName[lower] = (medicineCountsByName[lower] ?? 0) + 1;
          isItemMapped = true;
        }
      }
      if (isItemMapped) {
        totalMappedMedicines++;
      }
    }

    int getMappedCount(Manufacturer m) {
      if (medicineCountsByMfgId.containsKey(m.id)) {
        return medicineCountsByMfgId[m.id]!;
      }
      return medicineCountsByName[m.name.toLowerCase().trim()] ?? 0;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24.0 : 12.0,
              vertical: isDesktop ? 24.0 : 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (Responsive: Desktop side-by-side, Mobile stacked)
                if (isDesktop) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.domain,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manufacturers',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pharmaceutical companies and medicine brand manufacturers',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Refresh',
                            onPressed: () => ref
                                .read(manufacturerProvider.notifier)
                                .refresh(),
                            icon: Icon(
                              Icons.refresh,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (filtered.isNotEmpty)
                            PopupMenuButton<String>(
                              tooltip: 'Export Manufacturers',
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              onSelected: (val) =>
                                  _handleExport(val, filtered, getMappedCount),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'csv',
                                  child: Row(
                                    children: [
                                      Icon(Icons.table_chart, size: 18),
                                      SizedBox(width: 8),
                                      Text('Export as CSV'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'excel',
                                  child: Row(
                                    children: [
                                      Icon(Icons.grid_on, size: 18),
                                      SizedBox(width: 8),
                                      Text('Export as Excel'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'pdf',
                                  child: Row(
                                    children: [
                                      Icon(Icons.picture_as_pdf, size: 18),
                                      SizedBox(width: 8),
                                      Text('Export as PDF'),
                                    ],
                                  ),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey[700]!
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.download,
                                      size: 16,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Export',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _showAddDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Manufacturer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  // Mobile Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.domain,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Manufacturers',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pharmaceutical brand manufacturers',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : const Color(0xFF64748B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: () =>
                            ref.read(manufacturerProvider.notifier).refresh(),
                        icon: Icon(
                          Icons.refresh,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (filtered.isNotEmpty) ...[
                        Expanded(
                          flex: 4,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            onSelected: (val) =>
                                _handleExport(val, filtered, getMappedCount),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'csv',
                                child: Row(
                                  children: [
                                    Icon(Icons.table_chart, size: 18),
                                    SizedBox(width: 8),
                                    Text('Export as CSV'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'excel',
                                child: Row(
                                  children: [
                                    Icon(Icons.grid_on, size: 18),
                                    SizedBox(width: 8),
                                    Text('Export as Excel'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'pdf',
                                child: Row(
                                  children: [
                                    Icon(Icons.picture_as_pdf, size: 18),
                                    SizedBox(width: 8),
                                    Text('Export as PDF'),
                                  ],
                                ),
                              ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey[700]!
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.download,
                                    size: 16,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Export',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        flex: 6,
                        child: ElevatedButton.icon(
                          onPressed: _showAddDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Manufacturer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // 2. Search Bar at Top (Matching Distributors screen)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? Colors.grey[800]!
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText:
                          'Search manufacturer by name or brand abbreviation...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Three KPI Summary Cards (Total Manufacturers, Mapped Medicines, Short Codes Assigned)
                if (isDesktop)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: 'Total Manufacturers',
                          value: '${allManufacturers.length}',
                          icon: Icons.domain,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: 'Mapped Medicines',
                          value: '$totalMappedMedicines',
                          icon: Icons.medication,
                          color: const Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: 'Short Codes Assigned',
                          value:
                              '${allManufacturers.where((m) => m.shortCode != null && m.shortCode!.isNotEmpty).length}',
                          icon: Icons.tag,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: 'Total Manufacturers',
                          value: '${allManufacturers.length}',
                          icon: Icons.domain,
                          color: const Color(0xFF0284C7),
                          isMobile: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: 'Mapped Medicines',
                          value: '$totalMappedMedicines',
                          icon: Icons.medication,
                          color: const Color(0xFF059669),
                          isMobile: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: 'Short Codes',
                          value:
                              '${allManufacturers.where((m) => m.shortCode != null && m.shortCode!.isNotEmpty).length}',
                          icon: Icons.tag,
                          color: const Color(0xFFD97706),
                          isMobile: true,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // 4. Table / List Content
                Expanded(
                  child: manufacturersAsync.when(
                    data: (_) {
                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.domain_disabled,
                                size: 56,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No manufacturers added yet'
                                    : 'No manufacturers match your search',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : const Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Add pharmaceutical companies to organize medicine brands.'
                                    : 'Try searching by a different name or short code.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _showAddDialog,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add First Manufacturer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[800]!
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: isDark
                                  ? Colors.grey[800]!
                                  : const Color(0xFFE2E8F0),
                            ),
                            itemBuilder: (context, index) {
                              final mfg = filtered[index];
                              final mappedCount = getMappedCount(mfg);
                              final initials = mfg.name.isNotEmpty
                                  ? mfg.name
                                      .trim()
                                      .split(' ')
                                      .take(2)
                                      .map((e) => e.isNotEmpty ? e[0] : '')
                                      .join()
                                      .toUpperCase()
                                  : 'MF';

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF059669)
                                      .withValues(alpha: 0.12),
                                  foregroundColor: const Color(0xFF059669),
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        mfg.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1E293B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (mfg.shortCode != null &&
                                        mfg.shortCode!.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0284C7)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFF0284C7)
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          mfg.shortCode!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            height: 1.15,
                                            letterSpacing: 0.4,
                                            color: Color(0xFF0284C7),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    '$mappedCount medicines linked in inventory',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: Color(0xFF0284C7),
                                      ),
                                      onPressed: () => _showEditDialog(mfg),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _showDeleteDialog(mfg),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text('Failed to load manufacturers: $e'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => ref
                                .read(manufacturerProvider.notifier)
                                .refresh(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    double? customWidth,
    bool isMobile = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: customWidth,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 14,
        vertical: isMobile ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: isMobile ? 18 : 20),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
