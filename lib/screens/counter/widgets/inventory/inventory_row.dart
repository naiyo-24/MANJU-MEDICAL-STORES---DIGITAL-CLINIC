import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/inventory_service.dart';
import '../../../../config/api_constants.dart';
import 'status_badge.dart';

class InventoryRowWidget extends StatelessWidget {
  final InventoryItem medicine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const InventoryRowWidget({
    super.key,
    required this.medicine,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = medicine.stockQuantity <= 0
        ? 'Out of Stock'
        : (medicine.stockQuantity <= (medicine.lowStockThreshold ?? 10)
              ? 'Low Stock'
              : (medicine.stockQuantity <= 50 ? 'Medium Stock' : 'OK'));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    image: medicine.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(
                              '${ApiConstants.baseUrl}${medicine.imageUrl}',
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: medicine.imageUrl == null
                      ? const Icon(
                          Icons.medication,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        medicine.manufacturer.isNotEmpty
                            ? medicine.manufacturer
                            : 'Unknown',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  medicine.createdAt != null
                      ? DateFormat(
                          'MMM dd, yyyy',
                        ).format(DateTime.parse(medicine.createdAt!).toLocal())
                      : 'N/A',
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 12,
                  ),
                ),
                if (medicine.updatedAt != null)
                  Text(
                    'Updated: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(medicine.updatedAt!).toLocal())}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              medicine.stockQuantity.toString(),
              style: TextStyle(
                color: medicine.stockQuantity <= 0
                    ? const Color(0xFFDC2626) // Red
                    : (medicine.stockQuantity <=
                              (medicine.lowStockThreshold ?? 10)
                          ? const Color(0xFFD97706) // Yellow/Orange
                          : (medicine.stockQuantity <= 50
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF16A34A))), // Blue / Green
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹${medicine.unitPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              medicine.gst != null && medicine.gst! > 0
                  ? '${medicine.gst!.toStringAsFixed(1)}%'
                  : '-',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              medicine.expiryDate,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(status: status),
            ),
          ),
          SizedBox(
            width: 40,
            child: PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
