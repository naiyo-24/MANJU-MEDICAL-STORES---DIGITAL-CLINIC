import 'package:dio/dio.dart';
import '../config/api_client.dart';
import 'inventory_service.dart';

class Rack {
  final String id;
  final String rackNumber;
  final String? details;

  Rack({
    required this.id,
    required this.rackNumber,
    this.details,
  });

  factory Rack.fromJson(Map<String, dynamic> json) {
    return Rack(
      id: json['id'],
      rackNumber: json['rack_number'],
      details: json['details'],
    );
  }
}

class RackService {
  static Future<List<Rack>> getRacks() async {
    try {
      final shopId = await InventoryService.getShopId();
      final response = await ApiClient().dio.get('/api/admin/racks/shop/$shopId');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Rack.fromJson(json)).toList();
      }
      throw Exception('Failed to load racks');
    } catch (e) {
      throw Exception('Error loading racks: $e');
    }
  }

  static Future<Rack> createRack(String rackNumber, String? details) async {
    try {
      final shopId = await InventoryService.getShopId();
      final response = await ApiClient().dio.post(
        '/api/admin/racks/',
        data: {
          'shop_id': shopId,
          'rack_number': rackNumber,
          'details': details,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Rack.fromJson(response.data);
      }
      throw Exception('Failed to create rack');
    } catch (e) {
      throw Exception('Error creating rack: $e');
    }
  }

  static Future<void> deleteRack(String id) async {
    try {
      final response = await ApiClient().dio.delete('/api/admin/racks/$id');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete rack');
      }
    } catch (e) {
      throw Exception('Error deleting rack: $e');
    }
  }
}
