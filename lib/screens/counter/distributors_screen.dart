import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/counter_providers.dart';
import '../../providers/distributor_provider.dart';
import 'widgets/distributors/add_distributor_dialog.dart';
import 'widgets/distributors/dashboard/distributor_kpi_cards.dart';
import 'widgets/distributors/dashboard/distributor_charts.dart';
import 'widgets/distributors/dashboard/distributor_list_view.dart';
import '../../services/export_service.dart';

class DistributorsScreen extends ConsumerStatefulWidget {
  const DistributorsScreen({super.key});

  @override
  ConsumerState<DistributorsScreen> createState() => _DistributorsScreenState();
}

class _DistributorsScreenState extends ConsumerState<DistributorsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final distributorsAsync = ref.watch(distributorsProvider);
    final allDistributors = distributorsAsync.value ?? [];
    final filteredDistributors = _searchQuery.isEmpty 
        ? allDistributors 
        : allDistributors.where((d) => 
            (d['name']?.toString().toLowerCase() ?? '').contains(_searchQuery) ||
            (d['email']?.toString().toLowerCase() ?? '').contains(_searchQuery) ||
            (d['phone']?.toString().toLowerCase() ?? '').contains(_searchQuery)
          ).toList();

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
                if (isDesktop) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Distributors',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.refresh, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B)),
                            onPressed: () {
                              ref.invalidate(distributorsProvider);
                              ref.invalidate(purchaseBillsProvider);
                            },
                            tooltip: 'Refresh',
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            onSelected: (value) async {
                              final dataToExport = filteredDistributors.map((d) => {
                                'Name': d['name'] ?? '',
                                'Email': d['email'] ?? '',
                                'Phone': d['phone'] ?? '',
                                'GSTIN': d['gstin'] ?? '',
                                'Address': d['address'] ?? '',
                                'Status': d['status'] ?? 'Active',
                              }).toList();

                              final timestamp = DateTime.now().millisecondsSinceEpoch;
                              final settings = ref.read(settingsProvider).value ??
                                  await ref.read(settingsProvider.future).catchError((_) => <String, dynamic>{});

                              if (value == 'csv') {
                                await ExportService.exportToCSV(dataToExport, 'Distributors_$timestamp');
                              } else if (value == 'excel') {
                                await ExportService.exportToExcel(dataToExport, 'Distributors_$timestamp');
                              } else if (value == 'pdf') {
                                await ExportService.exportToPDF(dataToExport, 'Distributors_$timestamp', settings);
                              }
                            },
                            offset: const Offset(0, 40),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'csv',
                                child: Text('Export as CSV'),
                              ),
                              const PopupMenuItem(
                                value: 'excel',
                                child: Text('Export as Excel'),
                              ),
                              const PopupMenuItem(
                                value: 'pdf',
                                child: Text('Export as PDF'),
                              ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF166534)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.download, color: Color(0xFF166534), size: 18),
                                  SizedBox(width: 8),
                                  Text('Export', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => const AddDistributorDialog(),
                              );
                            },
                            icon: const Icon(Icons.add, color: Colors.white, size: 18),
                            label: const Text('Add Distributor', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF166534),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Distributors',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B)),
                        onPressed: () {
                          ref.invalidate(distributorsProvider);
                          ref.invalidate(purchaseBillsProvider);
                        },
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          onSelected: (value) async {
                            final dataToExport = filteredDistributors.map((d) => {
                              'Name': d['name'] ?? '',
                              'Email': d['email'] ?? '',
                              'Phone': d['phone'] ?? '',
                              'GSTIN': d['gstin'] ?? '',
                              'Address': d['address'] ?? '',
                              'Status': d['status'] ?? 'Active',
                            }).toList();

                            final timestamp = DateTime.now().millisecondsSinceEpoch;
                            final settings = ref.read(settingsProvider).value ??
                                await ref.read(settingsProvider.future).catchError((_) => <String, dynamic>{});

                            if (value == 'csv') {
                              await ExportService.exportToCSV(dataToExport, 'Distributors_$timestamp');
                            } else if (value == 'excel') {
                              await ExportService.exportToExcel(dataToExport, 'Distributors_$timestamp');
                            } else if (value == 'pdf') {
                              await ExportService.exportToPDF(dataToExport, 'Distributors_$timestamp', settings);
                            }
                          },
                          offset: const Offset(0, 40),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'csv',
                              child: Text('Export as CSV'),
                            ),
                            const PopupMenuItem(
                              value: 'excel',
                              child: Text('Export as Excel'),
                            ),
                            const PopupMenuItem(
                              value: 'pdf',
                              child: Text('Export as PDF'),
                            ),
                          ],
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF166534)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download, color: Color(0xFF166534), size: 18),
                                SizedBox(width: 6),
                                Text('Export', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 6,
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => const AddDistributorDialog(),
                              );
                            },
                            icon: const Icon(Icons.add, color: Colors.white, size: 18),
                            label: const Text('Add Distributor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF166534),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search distributors...',
                prefixIcon: Icon(Icons.search, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B)),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF166534)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: distributorsAsync.when(
                skipLoadingOnReload: false,
                data: (distributors) {
                  if (distributors.isEmpty) {
                    return Center(
                      child: Text(
                        'No distributors found. Add one to get started!',
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 16),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DistributorKpiCards(distributors: distributors),
                        DistributorCharts(distributors: distributors),
                        DistributorListView(distributors: filteredDistributors),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF166534))),
                error: (err, stack) => Center(
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: Colors.red),
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
}
