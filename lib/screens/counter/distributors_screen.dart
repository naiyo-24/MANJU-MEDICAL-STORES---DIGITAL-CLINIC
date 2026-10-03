import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/distributor_provider.dart';
import 'widgets/distributors/add_distributor_dialog.dart';
import 'widgets/distributors/dashboard/distributor_kpi_cards.dart';
import 'widgets/distributors/dashboard/distributor_charts.dart';
import 'widgets/distributors/dashboard/distributor_list_view.dart';
import 'distributor_detail_screen.dart';
import 'add_purchase_bill_screen.dart';
import 'package:go_router/go_router.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 16,
              spacing: 16,
              children: [
                const Text(
                  'Distributors',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    PopupMenuButton<String>(
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
                        if (value == 'csv') {
                          await ExportService.exportToCSV(dataToExport, 'Distributors_$timestamp');
                        } else if (value == 'excel') {
                          await ExportService.exportToExcel(dataToExport, 'Distributors_$timestamp');
                        } else if (value == 'pdf') {
                          await ExportService.exportToPDF(dataToExport, 'Distributors_$timestamp');
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
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search distributors...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
                data: (distributors) {
                  if (distributors.isEmpty) {
                    return const Center(
                      child: Text(
                        'No distributors found. Add one to get started!',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
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
      ),
    );
  }
}
