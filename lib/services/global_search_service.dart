import '../config/api_client.dart';

class GlobalSearchService {
  static Future<Map<String, dynamic>> searchGlobal(String query) async {
    if (query.length < 2) {
      return {"medicines": [], "customers": [], "invoices": []};
    }

    try {
      final response = await ApiClient().dio.get(
        '/api/admin/search/global',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        return response.data['data'] ??
            {"medicines": [], "customers": [], "invoices": []};
      } else {
        throw 'Failed to perform global search';
      }
    } catch (e) {
      // ignore: avoid_print
      print('Global search error: $e');
      return {"medicines": [], "customers": [], "invoices": []};
    }
  }
}
