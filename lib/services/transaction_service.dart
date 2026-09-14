import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import 'auth_service.dart';
import 'package:intl/intl.dart';

class TransactionModel {
  final String id;
  final String date;
  final String time;
  final String type; // 'INCOME', 'EXPENSE', 'TRANSFER'
  final String category;
  final String description;
  final double amount;
  final String paymentMode;

  TransactionModel({
    required this.id,
    required this.date,
    required this.time,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.paymentMode,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    String parsedDate = '';
    String parsedTime = '';
    
    if (json['date'] != null) {
      try {
        final dt = DateTime.parse(json['date']);
        parsedDate = DateFormat('dd MMM yyyy').format(dt);
        parsedTime = DateFormat('hh:mm a').format(dt);
      } catch (e) {
        parsedDate = json['date'];
      }
    }

    String categoryName = '';
    if (json['category'] != null && json['category'] is Map) {
      categoryName = json['category']['name'] ?? '';
    }

    String txnType = json['transaction_type'] ?? '';
    if (txnType.toUpperCase() == 'INCOME') txnType = 'Income';
    else if (txnType.toUpperCase() == 'EXPENSE') txnType = 'Expense';
    else if (txnType.toUpperCase() == 'TRANSFER') txnType = 'Transfer';

    return TransactionModel(
      id: json['id'] ?? '',
      date: parsedDate,
      time: parsedTime,
      type: txnType,
      category: categoryName,
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      paymentMode: 'Cash', // Defaulting as backend doesn't seem to store it explicitly unless we use accounts
    );
  }
}

class TransactionService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> saveTransaction(Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/transactions');
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: json.encode(payload),
      );
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw 'Failed to create transaction';
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<TransactionModel>> getTransactions({int skip = 0, int limit = 100}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/transactions?skip=$skip&limit=$limit');
      final response = await http.get(url, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TransactionModel.fromJson(json)).toList();
      } else {
        throw 'Failed to load transactions';
      }
    } catch (e) {
      return [];
    }
  }

  static Future<void> deleteTransaction(String id) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/transactions/$id');
      final response = await http.delete(url, headers: await _getHeaders());
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw 'Failed to delete transaction';
      }
    } catch (e) {
      rethrow;
    }
  }
}
