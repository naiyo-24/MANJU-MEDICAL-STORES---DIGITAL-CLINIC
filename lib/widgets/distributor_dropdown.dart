import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/distributor_provider.dart';
import '../screens/counter/widgets/distributors/add_distributor_dialog.dart';

class DistributorDropdown extends ConsumerStatefulWidget {
  final String? selectedDistributorId;
  final ValueChanged<String?> onChanged;

  const DistributorDropdown({
    super.key,
    required this.selectedDistributorId,
    required this.onChanged,
  });

  @override
  ConsumerState<DistributorDropdown> createState() => _DistributorDropdownState();
}

class _DistributorDropdownState extends ConsumerState<DistributorDropdown> {
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

  void _openOverlay(List<dynamic> distributors) {
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
                    final currentDistributors =
                        ref.watch(distributorsProvider).value ?? distributors;
                    final query = _searchCtrl.text.trim().toLowerCase();
                    final filtered = currentDistributors.where((d) {
                      final name = (d['name'] ?? '').toString().toLowerCase();
                      final phone = (d['phone'] ?? '').toString().toLowerCase();
                      return name.contains(query) || phone.contains(query);
                    }).toList();

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "+ Add New Distributor" AT THE TOP
                        InkWell(
                          onTap: () async {
                            _closeOverlay();
                            final result = await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (ctx) => const AddDistributorDialog(),
                            );
                            if (result != null && result['id'] != null) {
                              widget.onChanged(result['id'].toString());
                            }
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
                                  '+ Add New Distributor',
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
                              hintText: 'Search distributor name or phone...',
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
                                    'No distributors found',
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
                                    final d = filtered[index];
                                    final id = d['id'].toString();
                                    final name = d['name'].toString();
                                    final phone = d['phone']?.toString();
                                    final isSelected =
                                        widget.selectedDistributorId == id;

                                    return ListTile(
                                      dense: true,
                                      selected: isSelected,
                                      selectedTileColor: const Color(0xFF166534)
                                          .withValues(alpha: 0.1),
                                      title: Text(
                                        name,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                      subtitle: phone != null && phone.isNotEmpty
                                          ? Text(
                                              phone,
                                              style: const TextStyle(fontSize: 11),
                                            )
                                          : null,
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Color(0xFF166534),
                                            )
                                          : null,
                                      onTap: () {
                                        widget.onChanged(id);
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
    final distributorsAsync = ref.watch(distributorsProvider);

    return distributorsAsync.when(
      data: (distributors) {
        String? selectedName;
        if (widget.selectedDistributorId != null) {
          final match = distributors.firstWhere(
            (d) => d['id']?.toString() == widget.selectedDistributorId,
            orElse: () => null,
          );
          if (match != null) {
            selectedName = match['name']?.toString();
          }
        }

        return CompositedTransformTarget(
          link: _layerLink,
          child: InkWell(
            onTap: () {
              if (_isOpen) {
                _closeOverlay();
              } else {
                _openOverlay(distributors);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Distributor',
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
                    if (widget.selectedDistributorId != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        tooltip: 'Clear Distributor',
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
                selectedName ?? 'Select a Distributor',
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
      error: (err, stack) => Text('Error loading distributors: $err'),
    );
  }
}
