import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';

class AccountingExtendedService {
  static Future<Map<String, dynamic>> getReceivables() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/accounts/extended/receivables'));
      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      return {"receivables": [], "total_receivables": 0.0};
    } catch (e) {
      print('Error fetching receivables: $e');
      return {"receivables": [], "total_receivables": 0.0};
    }
  }

  static Future<Map<String, dynamic>> getPayables() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/accounts/extended/payables'));
      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      return {"payables": [], "total_payables": 0.0};
    } catch (e) {
      print('Error fetching payables: $e');
      return {"payables": [], "total_payables": 0.0};
    }
  }

  static Future<List<dynamic>> getLedger() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/accounts/extended/ledger'));
      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      return [];
    } catch (e) {
      print('Error fetching ledger: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getPnL(String? startDate, String? endDate) async {
    try {
      String url = '${ApiConstants.baseUrl}/api/accounts/extended/reports/pnl';
      List<String> queryParams = [];
      if (startDate != null) queryParams.add('start_date=$startDate');
      if (endDate != null) queryParams.add('end_date=$endDate');
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      return {"total_income": 0.0, "total_expense": 0.0, "net_profit": 0.0};
    } catch (e) {
      print('Error fetching PnL: $e');
      return {"total_income": 0.0, "total_expense": 0.0, "net_profit": 0.0};
    }
  }
}
