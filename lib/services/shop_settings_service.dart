import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';

class ShopSettingsService {
  static const String endpoint = '${ApiConstants.baseUrl}/api/admin/shop-settings/';

  static Future<Map<String, dynamic>> getSettings() async {
    final response = await http.get(Uri.parse(endpoint));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load shop settings');
    }
  }

  static Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update shop settings');
    }
  }

  static Future<String> uploadLogo(List<int> bytes, String filename) async {
    var request = http.MultipartRequest('POST', Uri.parse('${endpoint}upload/logo'));
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    ));
    var response = await request.send();
    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      return json.decode(resStr)['url'];
    } else {
      throw Exception('Failed to upload logo');
    }
  }

  static Future<String> uploadQr(List<int> bytes, String filename) async {
    var request = http.MultipartRequest('POST', Uri.parse('${endpoint}upload/qr'));
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    ));
    var response = await request.send();
    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      return json.decode(resStr)['url'];
    } else {
      throw Exception('Failed to upload QR');
    }
  }
}
