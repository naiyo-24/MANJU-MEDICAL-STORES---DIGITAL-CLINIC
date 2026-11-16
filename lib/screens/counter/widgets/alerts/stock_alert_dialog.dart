import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/stock_alert_item.dart';
import '../../../../providers/stock_alert_provider.dart';
import '../../../../providers/distributor_provider.dart';
import '../../../../utils/responsive.dart';
import '../distributors/add_distributor_dialog.dart';

class StockAlertDialog extends ConsumerStatefulWidget {
  const StockAlertDialog({super.key});

  static Future<void> show(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const StockAlertDialog(),
      );
    }

    return showDialog(
      context: context,
      builder: (context) => const StockAlertDialog(),
    );
  }

  @override
  ConsumerState<StockAlertDialog> createState() => _StockAlertDialogState();
}

class _StockAlertDialogState extends ConsumerState<StockAlertDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);
    final alertsAsync = ref.watch(stockAlertProvider);

    final cardBg = Theme.of(context).cardColor;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final secondaryTextColor = isDark ? Colors.grey[400] : const Color(0xFF64748B);
    final borderColor = Theme.of(context).dividerColor;

    final contentWidget = Container(
      constraints: BoxConstraints(
        maxWidth: isMobile ? double.infinity : 650,
        maxHeight: isMobile
            ? MediaQuery.of(context).size.height * 0.85
            : MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mobile Drag Handle
          if (isMobile)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(20, isMobile ? 12 : 20, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Alert Notifications',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      Text(
                        'Medicines running low or out of stock',
                        style: TextStyle(fontSize: 12, color: secondaryTextColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh Alerts',
                  icon: Icon(Icons.refresh, size: 20, color: secondaryTextColor),
                  onPressed: () => ref.read(stockAlertProvider.notifier).refresh(),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: Icon(Icons.close, size: 20, color: secondaryTextColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _filter = val.trim().toLowerCase()),
              style: TextStyle(fontSize: 13, color: primaryTextColor),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search alerts by medicine or brand...',
                hintStyle: TextStyle(fontSize: 12, color: secondaryTextColor),
                prefixIcon: Icon(Icons.search, size: 18, color: secondaryTextColor),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _filter = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF22C55E)),
                ),
              ),
            ),
          ),

          // Alert List
          Flexible(
            child: alertsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Color(0xFF22C55E)),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Failed to load alerts: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
              data: (alerts) {
                final filtered = _filter.isEmpty
                    ? alerts
                    : alerts.where((a) {
                        return a.name.toLowerCase().contains(_filter) ||
                            a.manufacturer.toLowerCase().contains(_filter) ||
                            (a.distributorName ?? '').toLowerCase().contains(_filter);
                      }).toList();

                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: const Color(0xFF22C55E),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filter.isEmpty
                              ? 'All stocks are healthy!'
                              : 'No matching stock alerts found.',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _filter.isEmpty
                              ? 'No medicines are currently at or below their low stock threshold.'
                              : 'Try searching with a different term.',
                          style: TextStyle(fontSize: 12, color: secondaryTextColor),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => Divider(height: 8, color: borderColor),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildAlertTile(
                      context,
                      item: item,
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      borderColor: borderColor,
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1, color: borderColor),

          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/counter/inventory');
                  },
                  icon: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: const Text('Open Inventory', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return contentWidget;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: contentWidget,
    );
  }

  Widget _buildAlertTile(
    BuildContext context, {
    required StockAlertItem item,
    required bool isDark,
    required Color primaryTextColor,
    required Color? secondaryTextColor,
    required Color borderColor,
  }) {
    final bool isOut = item.isOutOfStock;
    final badgeBg = isOut
        ? const Color(0xFFEF4444).withValues(alpha: isDark ? 0.3 : 0.12)
        : const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.3 : 0.12);
    final badgeTextColor = isOut ? const Color(0xFFEF4444) : const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isOut ? Icons.block : Icons.warning_amber_rounded,
              color: badgeTextColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.manufacturer.isNotEmpty ? item.manufacturer : 'Unknown Mfg'} • Batch: ${item.batchNumber.isNotEmpty ? item.batchNumber : 'N/A'}',
                  style: TextStyle(fontSize: 11, color: secondaryTextColor),
                ),
                if (item.distributorName != null && item.distributorName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.local_shipping_outlined, size: 12, color: secondaryTextColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Supplier: ${item.distributorName}',
                          style: TextStyle(fontSize: 11, color: secondaryTextColor, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOut ? 'Out of Stock' : '${item.stockQuantity} left (Min: ${item.lowStockThreshold})',
                  style: TextStyle(
                    color: badgeTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Action Button: Order if distributor exists, or Add Distributor if not assigned
              if (item.distributorId != null && item.distributorId!.isNotEmpty)
                InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    // Fetch or read distributors to find this distributor's record
                    final distributorsList = ref.read(distributorsProvider).value ?? [];
                    final matchedDist = distributorsList.firstWhere(
                      (d) => d['id']?.toString() == item.distributorId,
                      orElse: () => {
                        'id': item.distributorId,
                        'name': item.distributorName ?? 'Distributor',
                        'phone': item.distributorPhone ?? '',
                      },
                    );

                    // Navigate to purchase order screen with the distributor
                    context.push('/counter/distributors/purchase', extra: matchedDist);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF166534),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Update Medicine',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: () async {
                    // Open Add Distributor Dialog
                    await showDialog(
                      context: context,
                      builder: (ctx) => const AddDistributorDialog(),
                    );
                    // Refresh alerts and distributors on return
                    ref.invalidate(distributorsProvider);
                    ref.invalidate(stockAlertProvider);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_add_alt_1,
                          size: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add Supplier',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
