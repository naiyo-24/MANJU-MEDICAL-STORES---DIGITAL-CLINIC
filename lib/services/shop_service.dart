import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import 'auth_service.dart';

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
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Shop>> getShops() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiConstants.baseUrl}/api/admin/shops');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
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
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiConstants.baseUrl}/api/admin/shop');
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'name': name,
          'code': code,
          'address': address,
          'city': city,
          'contact_number': contactNumber,
          'status': status,
          'is_primary': isPrimary,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Shop.fromJson(data);
      } else {
        final data = json.decode(response.body);
        throw Exception(data['detail'] ?? 'Failed to create shop');
      }
    } catch (e) {
      throw Exception('Error creating shop: $e');
    }
  }
}
