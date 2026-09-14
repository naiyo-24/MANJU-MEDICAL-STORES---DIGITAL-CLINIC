import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import 'auth_service.dart';

class AccountSummaryModel {
  final double cashInHand;
  final double bankBalance;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;

  AccountSummaryModel({
    required this.cashInHand,
    required this.bankBalance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
  });

  factory AccountSummaryModel.fromJson(Map<String, dynamic> json) {
    return AccountSummaryModel(
      cashInHand: (json['cash_in_hand'] ?? 0.0).toDouble(),
      bankBalance: (json['bank_balance'] ?? 0.0).toDouble(),
      totalIncome: (json['total_income'] ?? 0.0).toDouble(),
      totalExpenses: (json['total_expenses'] ?? 0.0).toDouble(),
      netProfit: (json['net_profit'] ?? 0.0).toDouble(),
    );
  }
}

class AccountModel {
  final String id;
  final String name;
  final String accountType;
  final double balance;

  AccountModel({
    required this.id,
    required this.name,
    required this.accountType,
    required this.balance,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      accountType: json['account_type'] ?? '',
      balance: (json['balance'] ?? 0.0).toDouble(),
    );
  }
}

class AccountService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<AccountSummaryModel> getSummary() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/accounts/summary');
      final response = await http.get(url, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AccountSummaryModel.fromJson(data);
      } else {
        throw 'Failed to load account summary';
      }
    } catch (e) {
      // Fallback default values if API fails
      return AccountSummaryModel(
        cashInHand: 0.0,
        bankBalance: 0.0,
        totalIncome: 0.0,
        totalExpenses: 0.0,
        netProfit: 0.0,
      );
    }
  }

  static Future<List<AccountModel>> getAccounts() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/accounts');
      final response = await http.get(url, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AccountModel.fromJson(json)).toList();
      } else {
        throw 'Failed to load accounts';
      }
    } catch (e) {
      return [];
    }
  }
}
