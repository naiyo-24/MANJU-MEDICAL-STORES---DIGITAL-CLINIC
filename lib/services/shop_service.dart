import 'package:dio/dio.dart';
import '../config/api_client.dart';

class Shop {
  final String id;
  final String name;
  final String code;
  final String location;
  final String city;
  final String contact;
  final String status;
  final bool isPrimary;

  Shop({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    required this.city,
    required this.contact,
    required this.status,
    required this.isPrimary,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      code: json['code'] ?? 'N/A',
      location: json['address'] ?? 'N/A',
      city: json['city'] ?? 'N/A',
      contact: json['contact_number'] ?? 'N/A',
      status: json['status'] ?? 'Active',
      isPrimary: json['is_primary'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'location': location,
      'city': city,
      'contact': contact,
      'status': status,
      'isPrimary': isPrimary,
    };
  }
}

class ShopService {
  static Future<List<Shop>> getShops() async {
    try {
      final response = await ApiClient().dio.get('/api/admin/shops');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Shop.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load shops: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching shops: $e');
    }
  }

  static Future<Shop> createShop({
    required String name,
    required String code,
    required String address,
    required String city,
    required String contactNumber,
    required String status,
    required bool isPrimary,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '/api/admin/shop',
        data: {
          'name': name,
          'code': code,
          'address': address,
          'city': city,
          'contact_number': contactNumber,
          'status': status,
          'is_primary': isPrimary,
        },
      );

      if (response.statusCode == 201) {
        return Shop.fromJson(response.data);
      } else {
        throw Exception('Failed to create shop');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Failed to create shop');
    } catch (e) {
      throw Exception('Error creating shop: $e');
    }
  }
}
