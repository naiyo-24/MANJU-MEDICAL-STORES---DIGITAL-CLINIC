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

      final requestData = {
        'shop_id': shopId,
        'items': items.map((item) => {
          'inventory_item_id': item['inventory_item_id'],
          'quantity': item['qty'],
        }).toList(),
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
      };

      if (customerId != null && customerId.isNotEmpty) {
        requestData['user_id'] = customerId;
      }

      final response = await ApiClient().dio.post(
        '/api/admin/pos/checkout',
        data: requestData,
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
      if (e.toString().contains('No shops found')) {
        return <String, dynamic>{'history': <dynamic>[], 'summary': <String, dynamic>{}};
      }
      throw Exception('Error fetching POS history: $e');
    }
  }
}
