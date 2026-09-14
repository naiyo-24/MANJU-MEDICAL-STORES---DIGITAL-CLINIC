import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import 'auth_service.dart';
import 'inventory_service.dart';

class BillingService {
  static Future<Map<String, dynamic>> checkout({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    String? customerId,
    String paymentMethod = 'CASH',
  }) async {
    try {
      final token = await AuthService.getToken();
      final shopId = await InventoryService.getShopId();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/pos/checkout'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'shop_id': shopId,
          if (customerId != null) 'user_id': customerId,
          'items': items.map((item) => {
            'inventory_item_id': item['inventory_item_id'],
            'quantity': item['qty'],
          }).toList(),
          'total_amount': totalAmount,
          'payment_method': paymentMethod,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Checkout failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during checkout: $e');
    }
  }

  static Future<Map<String, dynamic>> getPosHistory() async {
    try {
      final token = await AuthService.getToken();
      final shopId = await InventoryService.getShopId();

      if (shopId == null) throw Exception('Shop ID not found');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/pos/history?shop_id=$shopId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch POS history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching POS history: $e');
    }
  }
}
