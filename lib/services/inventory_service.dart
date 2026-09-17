import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import 'auth_service.dart';

class InventoryItem {
  final String id;
  final String name;
  final String sku;
  final String manufacturer;
  final String batchNumber;
  final int stockQuantity;
  final double unitPrice;
  final double buyingPrice;
  final String? hsnCode;
  final String expiryDate;
  final int? lowStockThreshold;
  final String? imageUrl;
  final double? gst;
  final String? createdAt;
  final String? updatedAt;

  InventoryItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.manufacturer,
    required this.batchNumber,
    required this.stockQuantity,
    required this.unitPrice,
    required this.buyingPrice,
    this.hsnCode,
    required this.expiryDate,
    this.lowStockThreshold,
    this.imageUrl,
    this.gst,
    this.createdAt,
    this.updatedAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      sku: json['sku'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      batchNumber: json['batch_number'] ?? '',
      stockQuantity: json['stock_quantity'] ?? 0,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      buyingPrice: (json['buying_price'] ?? 0).toDouble(),
      hsnCode: json['hsn_code'],
      expiryDate: json['expiry_date'] ?? '',
      lowStockThreshold: json['low_stock_threshold'] != null ? int.tryParse(json['low_stock_threshold'].toString()) : null,
      imageUrl: json['image_url'],
      gst: json['gst'] != null ? (json['gst'] as num).toDouble() : 0.0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'manufacturer': manufacturer,
      'batch_number': batchNumber,
      'stock_quantity': stockQuantity,
      'unit_price': unitPrice,
      'buying_price': buyingPrice,
      'hsn_code': hsnCode,
      'expiry_date': expiryDate,
      'gst': gst,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class InventoryService {
  static String? _cachedShopId;

  static Future<String> getShopId() async {
    if (_cachedShopId != null) return _cachedShopId!;

    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/shops'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> shops = json.decode(response.body);
      if (shops.isNotEmpty) {
        _cachedShopId = shops.first['id'];
        return _cachedShopId!;
      } else {
        throw Exception('No shops found');
      }
    } else {
      throw Exception('Failed to fetch shop ID');
    }
  }

  static Future<List<InventoryItem>> fetchInventory({String? searchQuery, String? startDate, String? endDate}) async {
    try {
      final token = await AuthService.getToken();
      final shopId = await getShopId();
      String url = '${ApiConstants.baseUrl}/api/admin/shop/inventory?shop_id=$shopId';
      if (searchQuery != null && searchQuery.isNotEmpty) {
        url += '&search=$searchQuery';
      }
      if (startDate != null && startDate.isNotEmpty) {
        url += '&start_date=$startDate';
      }
      if (endDate != null && endDate.isNotEmpty) {
        url += '&end_date=$endDate';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> itemsList = data['items'] ?? [];
        return itemsList.map((item) => InventoryItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load inventory');
      }
    } catch (e) {
      throw Exception('Error fetching inventory: $e');
    }
  }

  static Future<String> uploadInventory(String filePath) async {
    try {
      final token = await AuthService.getToken();
      final shopId = await getShopId();
      final url = Uri.parse('${ApiConstants.baseUrl}/api/admin/shop/upload-inventory?shop_id=$shopId');
      var request = http.MultipartRequest('POST', url);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      var response = await request.send();
      
      if (response.statusCode == 201) {
        final respStr = await response.stream.bytesToString();
        final jsonResp = json.decode(respStr);
        return jsonResp['message'] ?? 'Upload successful';
      } else {
        final respStr = await response.stream.bytesToString();
        throw Exception('Upload failed: $respStr');
      }
    } catch (e) {
      throw Exception('Error uploading inventory: $e');
    }
  }

  static Future<void> addMedicine(Map<String, dynamic> itemData) async {
    try {
      final token = await AuthService.getToken();
      itemData['shop_id'] = await getShopId();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/shop/inventory/add'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(itemData),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to add medicine: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding medicine: $e');
    }
  }

  static Future<String> uploadMedicineImage(Uint8List bytes, String filename) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse('${ApiConstants.baseUrl}/api/admin/shop/inventory/upload-image');
      var request = http.MultipartRequest('POST', url);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      
      var response = await request.send();
      
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonResp = json.decode(respStr);
        return jsonResp['image_url'];
      } else {
        final respStr = await response.stream.bytesToString();
        throw Exception('Image upload failed: $respStr');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  static Future<void> updateMedicine(String itemId, Map<String, dynamic> itemData) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/shop/inventory/$itemId/update'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(itemData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update medicine: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating medicine: $e');
    }
  }

  static Future<void> deleteMedicine(String itemId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/shop/inventory/$itemId/delete'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete medicine: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting medicine: $e');
    }
  }
}
