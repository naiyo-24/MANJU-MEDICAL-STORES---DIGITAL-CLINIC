import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/manufacturer.dart';
import '../providers/manufacturer_provider.dart';
import '../screens/counter/widgets/manufacturers/add_manufacturer_dialog.dart';

class ManufacturerDropdown extends ConsumerStatefulWidget {
  final String? selectedManufacturerId;
  final ValueChanged<Manufacturer?> onChanged;

  const ManufacturerDropdown({
    super.key,
    this.selectedManufacturerId,
    required this.onChanged,
  });

  @override
  ConsumerState<ManufacturerDropdown> createState() =>
      _ManufacturerDropdownState();
}

class _ManufacturerDropdownState extends ConsumerState<ManufacturerDropdown> {
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

  void _showAddManufacturerDialog() {
    showDialog<Manufacturer>(
      context: context,
      builder: (context) => const AddManufacturerDialog(),
    ).then((newMfg) {
      if (newMfg != null && mounted) {
        widget.onChanged(newMfg);
      }
    });
  }

  void _showDeleteManufacturerDialog(Manufacturer mfg) {
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
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              try {
                await ref
                    .read(manufacturerProvider.notifier)
                    .deleteManufacturer(mfg.id);
                if (mounted) {
                  if (widget.selectedManufacturerId == mfg.id) {
                    widget.onChanged(null);
                  }
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

  void _toggleOverlay(List<Manufacturer> manufacturers) {
    if (_isOpen) {
      _closeOverlay();
    } else {
      _openOverlay(manufacturers);
    }
  }

  void _openOverlay(List<Manufacturer> manufacturers) {
    _searchCtrl.clear();
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss area
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeOverlay,
            ),
          ),
          // Dropdown content attached to target
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Consumer(
                  builder: (context, ref, _) {
                    final currentMfgs =
                        ref.watch(manufacturerProvider).value ?? manufacturers;
                    final query = _searchCtrl.text.trim().toLowerCase();
                    final filtered = currentMfgs.where((m) {
                      final name = m.name.toLowerCase();
                      final code = (m.shortCode ?? '').toLowerCase();
                      return name.contains(query) || code.contains(query);
                    }).toList();

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "+ Add New Manufacturer" pinned at top
                        InkWell(
                          onTap: () {
                            _closeOverlay();
                            _showAddManufacturerDialog();
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
                                  '+ Add New Manufacturer',
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

                        // Search Input Field
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: _searchCtrl,
                            autofocus: true,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Search by name or short code...',
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
                                borderSide: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF059669),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (_) {
                              _overlayEntry?.markNeedsBuild();
                            },
                          ),
                        ),

                        // List of items
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: filtered.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  child: Center(
                                    child: Text(
                                      _searchCtrl.text.isEmpty
                                          ? 'No manufacturers added yet'
                                          : 'No matching manufacturer',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final mfg = filtered[index];
                                    final isSelected =
                                        widget.selectedManufacturerId == mfg.id;
                                    return InkWell(
                                      onTap: () {
                                        widget.onChanged(mfg);
                                        _closeOverlay();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        color: isSelected
                                            ? const Color(0xFF059669)
                                                .withValues(alpha: 0.1)
                                            : Colors.transparent,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    mfg.name,
                                                    style: TextStyle(
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.w500,
                                                      fontSize: 13,
                                                      color: isSelected
                                                          ? const Color(0xFF059669)
                                                          : null,
                                                    ),
                                                  ),
                                                  if (mfg.shortCode != null &&
                                                      mfg.shortCode!.isNotEmpty)
                                                    Text(
                                                      'Code: ${mfg.shortCode}',
                                                      style: TextStyle(
                                                        color: Colors.grey[500],
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Color(0xFF059669),
                                              ),
                                            const SizedBox(width: 4),
                                            // Delete icon using lightweight InkWell without tooltip
                                            InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              onTap: () {
                                                _closeOverlay();
                                                _showDeleteManufacturerDialog(mfg);
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(6.0),
                                                child: Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeOverlay() {
    if (_isOpen) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      if (mounted) setState(() => _isOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manufacturersAsync = ref.watch(manufacturerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: manufacturersAsync.when(
        data: (manufacturers) {
          Manufacturer? selectedMfg;
          try {
            selectedMfg = manufacturers.firstWhere(
              (m) => m.id == widget.selectedManufacturerId,
            );
          } catch (_) {
            selectedMfg = null;
          }

          final displayText = selectedMfg != null
              ? (selectedMfg.shortCode != null && selectedMfg.shortCode!.isNotEmpty
                  ? '${selectedMfg.name} (${selectedMfg.shortCode})'
                  : selectedMfg.name)
              : null;

          return InkWell(
            onTap: () => _toggleOverlay(manufacturers),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isOpen
                      ? const Color(0xFF059669)
                      : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  width: _isOpen ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayText ?? 'Select Manufacturer',
                      style: TextStyle(
                        fontSize: 13,
                        color: displayText != null
                            ? (isDark ? Colors.white : const Color(0xFF1E293B))
                            : (isDark ? Colors.grey[400] : Colors.grey[500]),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.selectedManufacturerId != null)
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        widget.onChanged(null);
                        if (_isOpen) _closeOverlay();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.clear, size: 16, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text(
                'Loading manufacturers...',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
        error: (e, _) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[300]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error loading: $e',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
