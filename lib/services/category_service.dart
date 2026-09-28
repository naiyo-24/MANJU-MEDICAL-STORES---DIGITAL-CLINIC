import 'package:dio/dio.dart';
import '../config/api_client.dart';
import 'inventory_service.dart';

class Category {
  final String id;
  final String name;
  final String? description;

  Category({
    required this.id,
    required this.name,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}

class CategoryService {
  static Future<List<Category>> getCategories() async {
    try {
      final shopId = await InventoryService.getShopId();
      final response = await ApiClient().dio.get('/api/admin/categories/shop/$shopId');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Category.fromJson(json)).toList();
      }
      throw Exception('Failed to load categories');
    } catch (e) {
      throw Exception('Error loading categories: $e');
    }
  }

  static Future<Category> createCategory(String name, String? description) async {
    try {
      final shopId = await InventoryService.getShopId();
      final response = await ApiClient().dio.post(
        '/api/admin/categories/',
        data: {
          'shop_id': shopId,
          'name': name,
          'description': description,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Category.fromJson(response.data);
      }
      throw Exception('Failed to create category');
    } catch (e) {
      throw Exception('Error creating category: $e');
    }
  }

  static Future<void> deleteCategory(String id) async {
    try {
      final response = await ApiClient().dio.delete('/api/admin/categories/$id');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete category');
      }
    } catch (e) {
      throw Exception('Error deleting category: $e');
    }
  }
}
