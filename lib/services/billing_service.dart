import '../config/api_client.dart';
import 'inventory_service.dart';
import '../config/api_constants.dart';

class BillingService {
  static Future<Map<String, dynamic>> checkout({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerLocation,
    String? customerGstin,
    String? invoiceNo,
    String paymentMethod = 'CASH',
  }) async {
    try {
      final shopId = await InventoryService.getShopId();

      final requestData = {
        'shop_id': shopId,
        'tenant_id': shopId,
        'items': items
            .map(
              (item) => {
                'inventory_item_id': item['inventory_item_id'],
                'quantity': item['qty'],
                'is_loose': item['is_loose'] ?? false,
              },
            )
            .toList(),
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
      };

      if (customerId != null && customerId.isNotEmpty) {
        requestData['user_id'] = customerId;
      }
      if (customerName != null && customerName.isNotEmpty) {
        requestData['customer_name'] = customerName;
      }
      if (customerPhone != null && customerPhone.isNotEmpty) {
        requestData['customer_phone'] = customerPhone;
      }
      if (customerLocation != null && customerLocation.isNotEmpty) {
        requestData['customer_location'] = customerLocation;
      }
      if (customerGstin != null && customerGstin.isNotEmpty) {
        requestData['customer_gstin'] = customerGstin;
      }
      if (invoiceNo != null && invoiceNo.isNotEmpty) {
        requestData['invoice_no'] = invoiceNo;
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

  static Future<Map<String, dynamic>> rectifyInvoice({
    required String invoiceNo,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerLocation,
    String? customerGstin,
    String paymentMethod = 'CASH',
    double subtotal = 0.0,
    double totalDiscount = 0.0,
    double totalGst = 0.0,
  }) async {
    try {
      final shopId = await InventoryService.getShopId();

      final requestData = {
        'shop_id': shopId,
        'tenant_id': shopId,
        'invoice_no': invoiceNo,
        'items': items
            .map(
              (item) => {
                'inventory_item_id': item['inventory_item_id'],
                'quantity': item['qty'] ?? item['quantity'] ?? 1,
                'is_loose': item['is_loose'] ?? false,
              },
            )
            .toList(),
        'total_amount': totalAmount,
        'subtotal': subtotal,
        'total_discount': totalDiscount,
        'total_gst': totalGst,
        'payment_method': paymentMethod,
      };

      if (customerId != null && customerId.isNotEmpty) {
        requestData['user_id'] = customerId;
      }
      if (customerName != null && customerName.isNotEmpty) {
        requestData['customer_name'] = customerName;
      }
      if (customerPhone != null && customerPhone.isNotEmpty) {
        requestData['customer_phone'] = customerPhone;
      }
      if (customerLocation != null && customerLocation.isNotEmpty) {
        requestData['customer_location'] = customerLocation;
      }
      if (customerGstin != null && customerGstin.isNotEmpty) {
        requestData['customer_gstin'] = customerGstin;
      }

      final response = await ApiClient().dio.put(
        '/api/admin/pos/invoices/$invoiceNo/rectify',
        data: requestData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Invoice rectification failed: ${response.data}');
      }
    } catch (e) {
      throw Exception('Error during invoice rectification: $e');
    }
  }

  static Future<Map<String, dynamic>> getPosHistory({
    int limit = ApiConstants.defaultFetchLimit,
    int? days,
  }) async {
    try {
      final shopId = await InventoryService.getShopId();

      final Map<String, dynamic> queryParams = {
        'shop_id': shopId,
        'tenant_id': shopId,
        'limit': limit,
        '_t': DateTime.now().millisecondsSinceEpoch,
      };

      if (days != null) {
        queryParams['days'] = days;
      }

      final response = await ApiClient().dio.get(
        '/api/admin/pos/history',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to fetch POS history: ${response.data}');
      }
    } catch (e) {
      if (e.toString().contains('No shops found')) {
        return <String, dynamic>{
          'history': <dynamic>[],
          'summary': <String, dynamic>{},
        };
      }
      throw Exception('Error fetching POS history: $e');
    }
  }
}
