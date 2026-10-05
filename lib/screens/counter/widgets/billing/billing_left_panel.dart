import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/billing_provider.dart';
import '../../../../providers/counter_providers.dart';
import '../../../../../utils/format_utils.dart';
import 'billing_dialogs.dart';

class BillingLeftPanel extends ConsumerStatefulWidget {
  final bool isDesktopWidth;
  final bool hasEnoughHeight;
  final List<Map<String, dynamic>> filteredMedicines;
  final List<String> categories;
  final int selectedCategoryIndex;
  final Function(Map<String, dynamic>) onAddToCart;
  final Function(int) onCategorySelected;
  final Function(String) onSearch;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final TextEditingController searchController;

  const BillingLeftPanel({
    super.key,
    required this.isDesktopWidth,
    required this.hasEnoughHeight,
    required this.filteredMedicines,
    required this.categories,
    required this.selectedCategoryIndex,
    required this.onAddToCart,
    required this.onCategorySelected,
    required this.onSearch,
    required this.hasMore,
    required this.onLoadMore,
    required this.searchController,
  });


  @override
  ConsumerState<BillingLeftPanel> createState() => _BillingLeftPanelState();
}

class _BillingLeftPanelState extends ConsumerState<BillingLeftPanel> {
  late final LinkedScrollControllerGroup _verticalControllers;
  late final ScrollController _headController;
  late final ScrollController _bodyController;

  @override
  void initState() {
    super.initState();
    _verticalControllers = LinkedScrollControllerGroup();
    _headController = _verticalControllers.addAndGet();
    _bodyController = _verticalControllers.addAndGet();
  }

  @override
  void dispose() {
    _headController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Widget _buildFilterChip(String label, int index) {
    bool isSelected = widget.selectedCategoryIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => widget.onCategorySelected(index),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF22C55E) : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF64748B)),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConditionalExpanded(bool condition, Widget child) {
    if (condition) {
      return Expanded(child: child);
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    final racksAsync = ref.watch(rackProvider);
    final racks = racksAsync.value ?? [];
    
    final categoriesAsync = ref.watch(categoryProvider);
    final allCategories = categoriesAsync.value ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          // Search & Action Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: widget.searchController,
                            onChanged: widget.onSearch,
                            onSubmitted: widget.onSearch,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText:
                                  'Search medicine by name, brand, barcode...',
                              hintStyle: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : const Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.qr_code_scanner,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Medicines',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                InkWell(
                  onTap: () => context.go('/counter/inventory'),
                  child: const Text(
                    'View Stock',
                    style: TextStyle(
                      color: Color(0xFF22C55E),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.categories
                    .asMap()
                    .entries
                    .map((entry) => _buildFilterChip(entry.value, entry.key))
                    .toList(),
              ),
            ),
          ),

          // Medicines Table
          _buildConditionalExpanded(
            widget.hasEnoughHeight,
            LayoutBuilder(
              builder: (context, tableConstraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FIXED LEFT COLUMN (Medicine Name)
                    Container(
                      width: widget.isDesktopWidth ? 200 : 120,
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 40,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : const Color(0xFFF1F5F9),
                            padding: EdgeInsets.symmetric(horizontal: widget.isDesktopWidth ? 16 : 8, vertical: 12),
                            child: Text(
                              'Medicine Name',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          _buildConditionalExpanded(
                            widget.hasEnoughHeight,
                            ListView.separated(
                              controller: _headController,
                              shrinkWrap: !widget.hasEnoughHeight,
                              physics: widget.hasEnoughHeight ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                              itemCount: widget.filteredMedicines.length + 1,
                              separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor),
                              itemBuilder: (context, index) {
                                if (index == widget.filteredMedicines.length) {
                                  return const SizedBox(height: 68); // Match the Load More button height
                                }
                                final item = widget.filteredMedicines[index];
                                return Container(
                                  height: 48, // Fixed height to guarantee sync
                                  padding: EdgeInsets.symmetric(horizontal: widget.isDesktopWidth ? 16 : 8, vertical: 0),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    (item['name'] ?? '').toString().split(' - Item')[0],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // SCROLLABLE RIGHT COLUMNS
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: widget.isDesktopWidth ? 1000 : 700, // Fixed width for scrollable area
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                height: 40,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : const Color(0xFFF1F5F9),
                                padding: EdgeInsets.symmetric(horizontal: widget.isDesktopWidth ? 16 : 8, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(flex: 2, child: Text('Brand', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                    Expanded(flex: 2, child: Text('SKU / Barcode', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                    Expanded(flex: 2, child: Text('Batch No', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                    Expanded(flex: 2, child: Text('Expiry', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                    Expanded(flex: 2, child: Text('HSN Code', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                    Expanded(flex: 2, child: Text('MRP', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                    Expanded(flex: 2, child: Text('GST (%)', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                    Expanded(flex: 2, child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                    SizedBox(width: 80, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF475569), fontSize: 12))),
                                  ],
                                ),
                              ),
                              _buildConditionalExpanded(
                                widget.hasEnoughHeight,
                                ListView.separated(
                                  controller: _bodyController,
                                  shrinkWrap: !widget.hasEnoughHeight,
                                  physics: widget.hasEnoughHeight ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                                  itemCount: widget.filteredMedicines.length + 1,
                                  separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor),
                                  itemBuilder: (context, index) {
                                    if (index == widget.filteredMedicines.length) {
                                      if (widget.hasMore) {
                                        return Container(
                                          height: 68,
                                          padding: const EdgeInsets.all(16.0),
                                          child: Center(
                                            child: OutlinedButton(
                                              onPressed: widget.onLoadMore,
                                              child: const Text('Load More'),
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox(height: 68);
                                    }
                                    final item = widget.filteredMedicines[index];
                                    return Container(
                                      height: 48, // Fixed height to guarantee sync
                                      padding: EdgeInsets.symmetric(horizontal: widget.isDesktopWidth ? 16 : 8, vertical: 0),
                                      child: Row(
                                        children: [
                                          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Text(item['brand'] ?? item['manufacturer'] ?? '', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B), fontSize: 12), overflow: TextOverflow.ellipsis))),
                                          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Text(item['pack'] ?? item['sku'] ?? '', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 12), overflow: TextOverflow.ellipsis))),
                                          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Text(item['batch_number'] ?? '', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 12), overflow: TextOverflow.ellipsis))),
                                          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Text(item['expiry_date'] ?? '', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 12), overflow: TextOverflow.ellipsis))),
                                          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Text(item['hsn_code'] ?? '-', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 12), overflow: TextOverflow.ellipsis))),
                                          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Text('₹${(item['mrp'] ?? 0).toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B), fontSize: 12), overflow: TextOverflow.ellipsis))),
                                          Expanded(
                                            flex: 2, 
                                            child: Align(
                                              alignment: Alignment.centerLeft, 
                                              child: Text(
                                                ((item['cgst'] as num? ?? 0) + (item['sgst'] as num? ?? 0)) > 0 
                                                    ? '${((item['cgst'] as num? ?? 0) + (item['sgst'] as num? ?? 0)).toStringAsFixed(1)}%' 
                                                    : '-', 
                                                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 12), 
                                                overflow: TextOverflow.ellipsis
                                              )
                                            )
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: (item['stock'] ?? 0) <= 0 && (item['loose_stock'] ?? 0) <= 0 ? const Color(0xFFFEE2E2) : const Color(0xFFF1F8F5), borderRadius: BorderRadius.circular(12)),
                                                  child: Text(FormatUtils.formatInventoryStock(item), style: TextStyle(color: (item['stock'] ?? 0) <= 0 && (item['loose_stock'] ?? 0) <= 0 ? Colors.red : const Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 12)),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 80,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: ElevatedButton.icon(
                                                onPressed: ((item['stock'] ?? 0) > 0) ? () => widget.onAddToCart(item) : null,
                                                icon: const Icon(Icons.add_shopping_cart, size: 14),
                                                label: const Text('Add'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF22C55E),
                                                  foregroundColor: Colors.white,
                                                  disabledBackgroundColor: Colors.grey.shade300,
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                                  minimumSize: const Size(0, 32),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
