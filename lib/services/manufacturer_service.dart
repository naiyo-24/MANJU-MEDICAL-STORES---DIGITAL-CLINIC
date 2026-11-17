import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_client.dart';
import '../models/manufacturer.dart';
import 'inventory_service.dart';

class ManufacturerService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch all active manufacturers for the current shop with optional search query
  Future<List<Manufacturer>> getManufacturers({String? search}) async {
    try {
      final shopId = await InventoryService.getShopId();
      final queryParams = <String, dynamic>{
        'shop_id': shopId,
        'tenant_id': shopId,
        '_t': DateTime.now().millisecondsSinceEpoch,
      };

      if (search != null && search.trim().isNotEmpty) {
        // Backend supports 'q' or 'search'
        queryParams['q'] = search.trim();
        queryParams['search'] = search.trim();
      }

      final response = await _apiClient.dio.get(
        '/api/admin/manufacturers/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        dynamic data = response.data;
        if (data is Map) {
          data = data['manufacturers'] ??
              data['items'] ??
              data['data'] ??
              data.values.first;
        }
        if (data is List) {
          return data
              .map((json) => Manufacturer.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      }
      throw Exception('Failed to load manufacturers: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching manufacturers: $e');
      }
      if (e is DioException) {
        throw Exception(
            'DioError ${e.response?.statusCode} on ${e.requestOptions.path}: ${e.response?.data ?? e.message}');
      }
      rethrow;
    }
  }

  /// Add a new manufacturer
  Future<Manufacturer> addManufacturer({
    required String name,
    String? shortCode,
  }) async {
    try {
      final shopId = await InventoryService.getShopId();
      final payload = <String, dynamic>{
        'shop_id': shopId,
        'tenant_id': shopId,
        'name': name.trim(),
        if (shortCode != null && shortCode.trim().isNotEmpty)
          'short_code': shortCode.trim().toUpperCase(),
      };

      final response = await _apiClient.dio.post(
        '/api/admin/manufacturers/',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Manufacturer.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to add manufacturer: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        print('Error adding manufacturer: $e');
      }
      if (e is DioException) {
        final detail = e.response?.data is Map
            ? e.response?.data['detail']
            : e.response?.data?.toString();
        throw Exception(detail ?? 'Error adding manufacturer');
      }
      rethrow;
    }
  }

  /// Update an existing manufacturer
  Future<Manufacturer> updateManufacturer(
    String id, {
    String? name,
    String? shortCode,
  }) async {
    try {
      final shopId = await InventoryService.getShopId();
      final payload = <String, dynamic>{
        if (name != null) 'name': name.trim(),
        if (shortCode != null)
          'short_code': shortCode.trim().isNotEmpty
              ? shortCode.trim().toUpperCase()
              : null,
      };

      final response = await _apiClient.dio.patch(
        '/api/admin/manufacturers/$id',
        queryParameters: {'shop_id': shopId, 'tenant_id': shopId},
        data: payload,
      );

      if (response.statusCode == 200) {
        return Manufacturer.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to update manufacturer: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        print('Error updating manufacturer: $e');
      }
      if (e is DioException) {
        final detail = e.response?.data is Map
            ? e.response?.data['detail']
            : e.response?.data?.toString();
        throw Exception(detail ?? 'Error updating manufacturer');
      }
      rethrow;
    }
  }

  /// Soft-delete a manufacturer
  Future<void> deleteManufacturer(String id) async {
    try {
      final shopId = await InventoryService.getShopId();
      final response = await _apiClient.dio.delete(
        '/api/admin/manufacturers/$id',
        queryParameters: {'shop_id': shopId, 'tenant_id': shopId},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete manufacturer: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting manufacturer: $e');
      }
      if (e is DioException) {
        final detail = e.response?.data is Map
            ? e.response?.data['detail']
            : e.response?.data?.toString();
        throw Exception(detail ?? 'Error deleting manufacturer');
      }
      rethrow;
    }
  }
}
