import '../config/api_client.dart';
import 'inventory_service.dart';

class BillingService {
  static Future<Map<String, dynamic>> checkout({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    String? customerId,
    String paymentMethod = 'CASH',
  }) async {
    try {
      final shopId = await InventoryService.getShopId();

      final response = await ApiClient().dio.post(
        '/api/admin/pos/checkout',
        data: {
          'shop_id': shopId,
          'user_id': customerId,
          'items': items.map((item) => {
            'inventory_item_id': item['inventory_item_id'],
            'quantity': item['qty'],
          }).toList(),
          'total_amount': totalAmount,
          'payment_method': paymentMethod,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Checkout failed: ${response.data}');
      }
    } catch (e) {
      throw Exception('Error during checkout: $e');
    }
  }

  static Future<Map<String, dynamic>> getPosHistory() async {
    try {
      final shopId = await InventoryService.getShopId();

      final response = await ApiClient().dio.get(
        '/api/admin/pos/history',
        queryParameters: {'shop_id': shopId},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to fetch POS history: ${response.data}');
      }
    } catch (e) {
      throw Exception('Error fetching POS history: $e');
    }
  }
}
