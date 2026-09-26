import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_client.dart';

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
      lowStockThreshold: json['low_stock_threshold'] != null
          ? int.tryParse(json['low_stock_threshold'].toString())
          : null,
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
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('selected_shop_id');
    if (savedId != null && savedId.isNotEmpty) {
      return savedId;
    }

    if (_cachedShopId != null) return _cachedShopId!;

    final response = await ApiClient().dio.get('/api/admin/shops');

    if (response.statusCode == 200) {
      final List<dynamic> shops = response.data;
      if (shops.isNotEmpty) {
        _cachedShopId = shops.first['id'];
        await prefs.setString('selected_shop_id', _cachedShopId!);
        return _cachedShopId!;
      } else {
        throw Exception('No shops found');
      }
    } else {
      throw Exception('Failed to fetch shop ID');
    }
  }

  static Future<void> setShopId(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_shop_id', shopId);
    _cachedShopId = shopId;
  }

  static Future<List<InventoryItem>> fetchInventory({
    required String shopId,
    String? searchQuery,
    String? startDate,
    String? endDate,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await ApiClient().dio.get(
        '/api/admin/shop/inventory',
        queryParameters: {
          'shop_id': shopId,
          if (searchQuery != null && searchQuery.isNotEmpty)
            'search': searchQuery,
          if (startDate != null && startDate.isNotEmpty)
            'start_date': startDate,
          if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
          'skip': skip,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> itemsList = response.data['items'] ?? [];
        return itemsList.map((item) => InventoryItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load inventory');
      }
    } catch (e) {
      if (e.toString().contains('No shops found')) {
        return [];
      }
      throw Exception('Error fetching inventory: $e');
    }
  }

  static Future<String> uploadInventory({
    required String filename,
    List<int>? bytes,
    String? path,
  }) async {
    try {
      final shopId = await getShopId();

      MultipartFile multipartFile;
      if (bytes != null) {
        multipartFile = MultipartFile.fromBytes(bytes, filename: filename);
      } else if (path != null) {
        multipartFile = await MultipartFile.fromFile(path, filename: filename);
      } else {
        throw Exception("File data is missing");
      }

      FormData formData = FormData.fromMap({'file': multipartFile});

      final response = await ApiClient().dio.post(
        '/api/admin/shop/upload-inventory',
        queryParameters: {'shop_id': shopId},
        data: formData,
      );

      if (response.statusCode == 201) {
        return response.data['message'] ?? 'Upload successful';
      } else {
        throw Exception('Upload failed: ${response.data}');
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final detail = e.response!.data is Map ? (e.response!.data['detail'] ?? e.response!.data.toString()) : e.response!.data.toString();
        throw Exception(detail);
      }
      throw Exception('Error uploading inventory: $e');
    }
  }

  static Future<void> addMedicine(Map<String, dynamic> itemData) async {
    try {
      itemData['shop_id'] = await getShopId();
      final response = await ApiClient().dio.post(
        '/api/admin/shop/inventory/add',
        data: itemData,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to add medicine: ${response.data}');
      }
    } catch (e) {
      if (e is DioException &&
          e.response != null &&
          e.response!.data is Map &&
          e.response!.data['detail'] != null) {
        throw Exception(e.response!.data['detail']);
      }
      throw Exception(e.toString());
    }
  }

  static Future<String> uploadMedicineImage(
    Uint8List bytes,
    String filename,
  ) async {
    try {
      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await ApiClient().dio.post(
        '/api/admin/shop/inventory/upload-image',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['image_url'];
      } else {
        throw Exception('Image upload failed: ${response.data}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  static Future<void> updateMedicine(
    String itemId,
    Map<String, dynamic> itemData,
  ) async {
    try {
      final response = await ApiClient().dio.patch(
        '/api/admin/shop/inventory/$itemId/update',
        data: itemData,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update medicine: ${response.data}');
      }
    } catch (e) {
      throw Exception('Error updating medicine: $e');
    }
  }

  static Future<void> deleteMedicine(String itemId) async {
    try {
      final response = await ApiClient().dio.delete(
        '/api/admin/shop/inventory/$itemId/delete',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete medicine: ${response.data}');
      }
    } catch (e) {
      throw Exception('Error deleting medicine: $e');
    }
  }
}
