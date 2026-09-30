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

class DistributorsScreen extends ConsumerWidget {
  const DistributorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distributorsAsync = ref.watch(distributorsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Distributors',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
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
                        DistributorListView(distributors: distributors),
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
