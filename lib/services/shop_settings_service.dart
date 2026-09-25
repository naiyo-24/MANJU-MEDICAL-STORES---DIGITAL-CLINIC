import 'package:dio/dio.dart';
import '../config/api_client.dart';

class ShopSettingsService {
  static Future<Map<String, dynamic>> getSettings() async {
    final response = await ApiClient().dio.get('/api/admin/shop-settings/');
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to load shop settings');
    }
  }

  static Future<Map<String, dynamic>> updateSettings(
    Map<String, dynamic> data,
  ) async {
    final response = await ApiClient().dio.put(
      '/api/admin/shop-settings/',
      data: data,
    );
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to update shop settings');
    }
  }

  static Future<String> uploadLogo(List<int> bytes, String filename) async {
    FormData formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    var response = await ApiClient().dio.post(
      '/api/admin/shop-settings/upload/logo',
      data: formData,
    );
    if (response.statusCode == 200) {
      return response.data['url'];
    } else {
      throw Exception('Failed to upload logo');
    }
  }

  static Future<String> uploadQr(List<int> bytes, String filename) async {
    FormData formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    var response = await ApiClient().dio.post(
      '/api/admin/shop-settings/upload/qr',
      data: formData,
    );
    if (response.statusCode == 200) {
      return response.data['url'];
    } else {
      throw Exception('Failed to upload QR');
    }
  }
}
