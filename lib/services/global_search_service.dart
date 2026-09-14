import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import 'auth_service.dart';

class GlobalSearchService {
  static Future<Map<String, dynamic>> searchGlobal(String query) async {
    if (query.length < 2) return {"medicines": [], "customers": [], "invoices": []};

    try {
      final token = await AuthService.getToken();
      final url = Uri.parse('${ApiConstants.baseUrl}/api/admin/search/global?q=$query');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {"medicines": [], "customers": [], "invoices": []};
      } else {
        throw 'Failed to perform global search';
      }
    } catch (e) {
      print('Global search error: $e');
      return {"medicines": [], "customers": [], "invoices": []};
    }
  }
}
