import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_client.dart';
import 'inventory_service.dart';

class PurchaseService {
  final ApiClient _apiClient = ApiClient();

  // Create a purchase bill
  Future<Map<String, dynamic>> createPurchaseBill(Map<String, dynamic> data) async {
    try {
      final shopId = await InventoryService.getShopId();
      data['tenant_id'] = shopId;
      final response = await _apiClient.dio.post(
        '/api/admin/purchases/',
        data: data,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to create purchase bill: ${response.statusCode} - ${response.data}');
    } catch (e) {
      print('Error creating purchase bill: $e');
      rethrow;
    }
  }

  // Fetch purchase bills
  Future<List<dynamic>> getPurchaseBills() async {
    try {
      final shopId = await InventoryService.getShopId();
      final response = await _apiClient.dio.get(
        '/api/admin/purchases/',
        queryParameters: {'shop_id': shopId, 'tenant_id': shopId},
      );
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error fetching purchase bills: $e');
      return [];
    }
  }
  // Mark a purchase bill as PAID
  Future<void> markBillAsPaid(String billId) async {
    try {
      final response = await _apiClient.dio.patch('/api/admin/purchases/$billId/pay');
      if (response.statusCode != 200) {
        throw Exception('Failed to mark bill as paid');
      }
    } catch (e) {
      print('Error paying bill: $e');
      rethrow;
    }
  }
}
