import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/counter_providers.dart';
import '../services/rack_service.dart';

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
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchCtrl = TextEditingController();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isOpen) {
        _closeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _closeOverlay();
    _focusNode.dispose();
    _searchCtrl.dispose();
    super.dispose();
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
              autofocus: true,
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
                  rackNoCtrl.text.trim(),
                  detailsCtrl.text.trim().isEmpty ? null : detailsCtrl.text.trim(),
                );
                if (mounted) {
                  if (newRack?.id != null) {
                    widget.onChanged(newRack!.id);
                  }
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  // ignore: use_build_context_synchronously
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

  void _showDeleteRackDialog(Rack rack, String displayText) {
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
                if (mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                  _overlayEntry?.markNeedsBuild();
                }
              } catch (e) {
                if (mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                  // ignore: use_build_context_synchronously
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
  }

  void _openOverlay(List<Rack> racks) {
    if (_isOpen) return;
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).cardColor,
              shadowColor: Colors.black26,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 260),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Consumer(
                  builder: (context, ref, _) {
                    final currentRacks = ref.watch(rackProvider).value ?? racks;
                    final query = _searchCtrl.text.trim().toLowerCase();
                    final filtered = currentRacks.where((r) {
                      final num = r.rackNumber.toLowerCase();
                      final details = (r.details ?? '').toLowerCase();
                      return num.contains(query) || details.contains(query);
                    }).toList();

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "+ Add New Rack" AT THE TOP
                        InkWell(
                          onTap: () {
                            _closeOverlay();
                            _showAddRackDialog();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF166534).withValues(alpha: 0.08),
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  size: 16,
                                  color: Color(0xFF166534),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '+ Add New Rack',
                                  style: TextStyle(
                                    color: Color(0xFF166534),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Search Input Field inside overlay
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: _searchCtrl,
                            autofocus: true,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Search rack number or details...',
                              hintStyle: const TextStyle(fontSize: 12),
                              prefixIcon: const Icon(Icons.search, size: 16),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 14),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        _overlayEntry?.markNeedsBuild();
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (_) {
                              _overlayEntry?.markNeedsBuild();
                            },
                          ),
                        ),

                        // Filtered List
                        Flexible(
                          child: filtered.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    'No racks found',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final rack = filtered[index];
                                    final displayText = rack.details != null && rack.details!.isNotEmpty
                                        ? '${rack.rackNumber} (${rack.details})'
                                        : rack.rackNumber;
                                    final isSelected = widget.selectedRackId == rack.id;

                                    return ListTile(
                                      dense: true,
                                      selected: isSelected,
                                      selectedTileColor: const Color(0xFF166534).withValues(alpha: 0.1),
                                      title: Text(
                                        displayText,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isSelected)
                                            const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Color(0xFF166534),
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                            onPressed: () {
                                              _closeOverlay();
                                              _showDeleteRackDialog(rack, displayText);
                                            },
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        widget.onChanged(rack.id);
                                        _closeOverlay();
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeOverlay() {
    if (!_isOpen) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final rackAsync = ref.watch(rackProvider);

    return rackAsync.when(
      data: (racks) {
        String? selectedName;
        if (widget.selectedRackId != null) {
          final match = racks.firstWhere(
            (r) => r.id == widget.selectedRackId,
            orElse: () => Rack(id: '', rackNumber: ''),
          );
          if (match.id.isNotEmpty) {
            selectedName = match.details != null && match.details!.isNotEmpty
                ? '${match.rackNumber} (${match.details})'
                : match.rackNumber;
          }
        }

        return CompositedTransformTarget(
          link: _layerLink,
          child: InkWell(
            onTap: () {
              if (_isOpen) {
                _closeOverlay();
              } else {
                _openOverlay(racks);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Rack / Location',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.selectedRackId != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        tooltip: 'Clear Rack / Location',
                        onPressed: () {
                          widget.onChanged(null);
                        },
                      ),
                    Icon(
                      _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              child: Text(
                selectedName ?? 'Select a Rack / Location',
                style: TextStyle(
                  fontSize: 14,
                  color: selectedName != null
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Theme.of(context).hintColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Text('Error loading racks: $err'),
    );
  }
}
