import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_client.dart';

class PurchaseService {
  final ApiClient _apiClient = ApiClient();

  // Create a purchase bill
  Future<Map<String, dynamic>> createPurchaseBill(Map<String, dynamic> data) async {
    try {
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
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getString('shop_id');
      final response = await _apiClient.dio.get(
        '/api/admin/purchases/',
        queryParameters: shopId != null ? {'shop_id': shopId} : {},
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
}
