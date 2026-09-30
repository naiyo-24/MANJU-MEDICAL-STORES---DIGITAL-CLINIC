import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/distributor_provider.dart';

class DistributorDropdown extends ConsumerWidget {
  final String? selectedDistributorId;
  final ValueChanged<String?> onChanged;

  const DistributorDropdown({
    super.key,
    required this.selectedDistributorId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distributorsAsync = ref.watch(distributorsProvider);

    return distributorsAsync.when(
      data: (distributors) {
        return DropdownButtonFormField<String>(
          value: selectedDistributorId,
          decoration: InputDecoration(
            labelText: 'Distributor',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Select a Distributor'),
            ),
            ...distributors.map((d) {
              return DropdownMenuItem<String>(
                value: d['id'].toString(),
                child: Text(d['name'].toString()),
              );
            }),
          ],
          onChanged: onChanged,
        );
      },
      loading: () => const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator())),
      error: (err, stack) => Text('Error loading distributors: $err'),
    );
  }
}
