import 'package:flutter/material.dart';

class ShopSummaryCards extends StatelessWidget {
  final int totalShops;
  final int activeShops;
  final int inactiveShops;
  final int totalLocations;

  const ShopSummaryCards({
    super.key,
    required this.totalShops,
    required this.activeShops,
    required this.inactiveShops,
    required this.totalLocations,
  });

  Widget _buildCard(String title, int count, Color bgColor, Color iconColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(count.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: iconColor.withOpacity(0.5), size: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        final card1 = _buildCard('Total Shops', totalShops, const Color(0xFFECFDF5), const Color(0xFF10B981), Icons.storefront);
        final card2 = _buildCard('Active Shops', activeShops, const Color(0xFFEFF6FF), const Color(0xFF3B82F6), Icons.check_circle);
        final card3 = _buildCard('Inactive Shop', inactiveShops, const Color(0xFFFFF7ED), const Color(0xFFF97316), Icons.pause_circle_filled);
        final card4 = _buildCard('Total Locations', totalLocations, const Color(0xFFF5F3FF), const Color(0xFF8B5CF6), Icons.location_on);

        if (isDesktop) {
          return Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: 16),
              Expanded(child: card2),
              const SizedBox(width: 16),
              Expanded(child: card3),
              const SizedBox(width: 16),
              Expanded(child: card4),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 16),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: card3),
                  const SizedBox(width: 16),
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        }
      }
    );
  }
}
