import '../config/api_client.dart';
import '../models/stock_alert_item.dart';
import 'inventory_service.dart';

class StockAlertService {
  /// Fetches low stock alerts from the dedicated backend endpoint if available,
  /// with a robust fallback to existing shop inventory so it functions immediately.
  static Future<List<StockAlertItem>> fetchLowStockAlerts() async {
    try {
      final shopId = await InventoryService.getShopId();
      if (shopId.isEmpty) return [];

      try {
        final response = await ApiClient().dio.get(
          '/api/admin/shop/inventory/low-stock-alerts',
          queryParameters: {
            'shop_id': shopId,
            '_t': DateTime.now().millisecondsSinceEpoch,
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> alertsList = response.data['alerts'] ?? response.data['items'] ?? [];
          return alertsList.map((item) => StockAlertItem.fromJson(item)).toList();
        }
      } catch (_) {
        // Fallback to evaluating low stock items from standard inventory
      }

      // Robust fallback: fetch inventory and filter items at or below threshold
      final items = await InventoryService.fetchInventory(shopId: shopId);
      final List<StockAlertItem> lowStock = [];
      for (final item in items) {
        final threshold = item.lowStockThreshold ?? 10;
        if (item.stockQuantity <= threshold) {
          lowStock.add(StockAlertItem.fromInventoryItem(item));
        }
      }
      return lowStock;
    } catch (e) {
      return [];
    }
  }
}
