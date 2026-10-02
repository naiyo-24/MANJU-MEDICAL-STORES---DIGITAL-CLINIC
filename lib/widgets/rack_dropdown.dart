import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rack_service.dart';
import '../providers/counter_providers.dart';

class RackDropdown extends ConsumerStatefulWidget {
  final String? selectedRackId;
  final ValueChanged<String?> onChanged;

  const RackDropdown({
    super.key,
    this.selectedRackId,
    required this.onChanged,
  });

  @override
  ConsumerState<RackDropdown> createState() => _RackDropdownState();
}

class _RackDropdownState extends ConsumerState<RackDropdown> {
  @override
  void initState() {
    super.initState();
    // Riverpod handles fetching automatically upon watching
  }

  void _showAddRackDialog() {
    final rackNoCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Rack'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rackNoCtrl,
              decoration: const InputDecoration(labelText: 'Rack Number'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: detailsCtrl,
              decoration: const InputDecoration(labelText: 'Details (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (rackNoCtrl.text.isEmpty) return;
              try {
                final newRack = await ref.read(rackProvider.notifier).createRack(
                  rackNoCtrl.text,
                  detailsCtrl.text.isEmpty ? null : detailsCtrl.text,
                );
                if (mounted) {
                  widget.onChanged(newRack?.id);
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add rack: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rackAsync = ref.watch(rackProvider);

    return rackAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const Text('Error loading racks'),
      data: (racks) {
        final isValidValue = widget.selectedRackId == null || racks.any((r) => r.id == widget.selectedRackId);
        final safeValue = isValidValue ? widget.selectedRackId : null;

        return DropdownButtonFormField<String>(
              isExpanded: true,
              value: safeValue,
              decoration: InputDecoration(
                labelText: 'Rack / Location',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: [
                ...racks.map((rack) {
                  final displayText = rack.details != null && rack.details!.isNotEmpty
                      ? '${rack.rackNumber} (${rack.details})'
                      : rack.rackNumber;
                  return DropdownMenuItem(
                    value: rack.id,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(displayText, overflow: TextOverflow.ellipsis)),
                          IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    // Close the dropdown first
                    Navigator.pop(context);
                    
                    // Show confirmation dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Rack'),
                        content: Text('Are you sure you want to delete "$displayText"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                await ref.read(rackProvider.notifier).deleteRack(rack.id);
                                if (widget.selectedRackId == rack.id) {
                                  widget.onChanged(null);
                                }
                                if (mounted) Navigator.pop(context);
                              } catch (e) {
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to delete rack: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }),
          DropdownMenuItem(
            value: 'add_new',
            child: Row(
              children: const [
                Icon(Icons.add, color: Color(0xFF22C55E)),
                SizedBox(width: 8),
                Expanded(child: Text('Add New Rack', overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold))),
              ],
            ),
          ),
      ],
      selectedItemBuilder: (BuildContext context) {
        return [
          ...racks.map((rack) {
            final displayText = rack.details != null && rack.details!.isNotEmpty
                ? '${rack.rackNumber} (${rack.details})'
                : rack.rackNumber;
            return Text(displayText, overflow: TextOverflow.ellipsis);
          }),
          const Text('Add New Rack'),
        ];
      },
      onChanged: (value) {
        if (value == 'add_new') {
          _showAddRackDialog();
        } else {
          widget.onChanged(value);
        }
      },
    ); // close DropdownButtonFormField
      }, // close data
    ); // close when
  }
}
