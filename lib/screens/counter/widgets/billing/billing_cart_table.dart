import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../notifiers/billing_notifier.dart';

class BillingCartTable extends StatelessWidget {
  final BillingState billingState;
  final BillingNotifier notifier;
  final Function(int) onIncreaseQty;
  final Function(int) onDecreaseQty;
  final Function(int) onRemoveItem;
  final Function(int) onToggleLoose;
  final Function(int, double) onUpdateItemDiscount;

  const BillingCartTable({
    super.key,
    required this.billingState,
    required this.notifier,
    required this.onIncreaseQty,
    required this.onDecreaseQty,
    required this.onRemoveItem,
    required this.onToggleLoose,
    required this.onUpdateItemDiscount,
  });

  @override
  Widget build(BuildContext context) {
    return       // Bill Table
      LayoutBuilder(
        builder: (context, tableConstraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 500,
                maxWidth: tableConstraints.maxWidth > 500
                    ? tableConstraints.maxWidth
                    : 500,
              ),
              child: Column(
                children: [
                  // Bill Table Header
                  Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text(
                            '#',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Item Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Qty',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Disc (%)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Price (₹)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'GST (%)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Total (₹)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 45,
                          child: Text(
                            'Action',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bill Table Body
                  billingState.currentBill.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Cart is empty',
                              style: TextStyle(color: Color(0xFF94A3B8)),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: billingState.currentBill.length,
                          separatorBuilder: (context, index) =>
                              const Divider(
                                height: 1,
                                color: Color(0xFFE2E8F0),
                              ),
                          itemBuilder: (context, index) {
                            final item = billingState.currentBill[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'].toString().split(' - Item')[0],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          item['brand'],
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 9,
                                          ),
                                        ),
                                          if (item['pack_size'] != null && (item['pack_size'] as num).toInt() > 1)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: InkWell(
                                                onTap: () => onToggleLoose(index),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      item['is_loose'] == true
                                                          ? Icons.check_box
                                                          : Icons.check_box_outline_blank,
                                                      size: 14,
                                                      color: const Color(0xFF166534),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Text(
                                                      'Loose',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        color: Color(0xFF1E293B),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () =>
                                                  onDecreaseQty(index),
                                              child: const Padding(
                                                padding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2,
                                                    ),
                                                child: Icon(
                                                  Icons.remove,
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${item['qty']}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () =>
                                                  onIncreaseQty(index),
                                              child: const Padding(
                                                padding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2,
                                                    ),
                                                child: Icon(
                                                  Icons.add,
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: SizedBox(
                                        height: 24,
                                        width: 40,
                                        child: TextFormField(
                                          initialValue: (item['discount'] as num?)?.toString() ?? '0',
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(fontSize: 10),
                                          decoration: const InputDecoration(
                                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (val) {
                                            final disc = double.tryParse(val) ?? 0.0;
                                            onUpdateItemDiscount(index, disc);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      ((item['is_loose'] == true) 
                                          ? (item['price'] / (item['pack_size'] ?? 1)) 
                                          : item['price']).toStringAsFixed(2),
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      ((item['cgst'] as num? ?? 0.0) +
                                                  (item['sgst'] as num? ??
                                                      0.0)) >
                                              0
                                          ? '${((item['cgst'] as num? ?? 0.0) + (item['sgst'] as num? ?? 0.0)).toStringAsFixed(1)}%'
                                          : '-',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      item['total'].toStringAsFixed(2),
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 45,
                                    child: InkWell(
                                      onTap: () => onRemoveItem(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEE2E2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          );
        },
      );
  }
}
