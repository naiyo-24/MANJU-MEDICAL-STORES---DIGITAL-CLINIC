import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/billing_provider.dart';
import 'billing_dialogs.dart';

class BillingLeftPanel extends ConsumerWidget {
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
  });

  Widget _buildFilterChip(String label, int index) {
    bool isSelected = selectedCategoryIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => onCategorySelected(index),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF22C55E) : Colors.white,
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
              color: isSelected ? Colors.white : const Color(0xFF64748B),
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: Color(0xFF64748B),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: onSearch,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText:
                                  'Search medicine by name, brand, barcode...',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.qr_code_scanner,
                          color: Color(0xFF64748B),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    BillingDialogs.showAddCustomItemDialog(context, (item) {
                      ref.read(billingProvider.notifier).addItem(item);
                    });
                  },
                  icon: const Icon(
                    Icons.add,
                    color: Color(0xFF22C55E),
                    size: 16,
                  ),
                  label: const Text(
                    'Add Custom Item',
                    style: TextStyle(
                      color: Color(0xFF166534),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF22C55E)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                const Text(
                  'Available Medicines',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
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
                children: categories
                    .asMap()
                    .entries
                    .map((entry) => _buildFilterChip(entry.value, entry.key))
                    .toList(),
              ),
            ),
          ),

          // Medicines Table
          _buildConditionalExpanded(
            hasEnoughHeight,
            LayoutBuilder(
              builder: (context, tableConstraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 800,
                      maxWidth: tableConstraints.maxWidth > 800
                          ? tableConstraints.maxWidth
                          : 800,
                    ),
                    child: Column(
                      children: [
                        // Medicines Table Header
                        Container(
                          color: const Color(0xFFF8FAFC),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Medicine Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Brand',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'SKU / Barcode',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'MRP (₹)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'GST (%)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Stock',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  'Action',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Medicines Table Body
                        _buildConditionalExpanded(
                          hasEnoughHeight,
                          ListView.separated(
                            shrinkWrap: !hasEnoughHeight,
                            physics: hasEnoughHeight
                                ? const AlwaysScrollableScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            itemCount: filteredMedicines.length + 1,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              color: Color(0xFFE2E8F0),
                            ),
                            itemBuilder: (context, index) {
                              if (index == filteredMedicines.length) {
                                if (hasMore) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: OutlinedButton(
                                        onPressed: onLoadMore,
                                        child: const Text('Load More'),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }
                              final item = filteredMedicines[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        item['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        item['brand'],
                                        style: const TextStyle(
                                          color: Color(0xFF1E293B),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        item['pack'],
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        item['mrp'].toStringAsFixed(2),
                                        style: const TextStyle(
                                          color: Color(0xFF1E293B),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        ((item['cgst'] as num? ?? 0) +
                                                    (item['sgst'] as num? ??
                                                        0)) >
                                                0
                                            ? '${((item['cgst'] as num? ?? 0) + (item['sgst'] as num? ?? 0)).toStringAsFixed(1)}%'
                                            : '-',
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        item['stock'].toString(),
                                        style: const TextStyle(
                                          color: Color(0xFF1E293B),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: ElevatedButton.icon(
                                        onPressed: () => onAddToCart(item),
                                        icon: const Icon(
                                          Icons.add_shopping_cart,
                                          size: 14,
                                        ),
                                        label: const Text(
                                          'Add',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF22C55E,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                          minimumSize: Size.zero,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
