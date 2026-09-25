import '../config/api_client.dart';
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
  double runningBalance = 0.0; // Initialized to prevent null errors

  TransactionModel({
    required this.id,
    required this.date,
    required this.time,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.paymentMode,
    this.runningBalance = 0.0,
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
    if (txnType.toUpperCase() == 'INCOME') {
      txnType = 'Income';

    } else if (txnType.toUpperCase() == 'EXPENSE') {
      txnType = 'Expense';
    } else if (txnType.toUpperCase() == 'TRANSFER') {
      txnType = 'Transfer';
    }

    return TransactionModel(
      id: json['id'] ?? '',
      date: parsedDate,
      time: parsedTime,
      type: txnType,
      category: categoryName,
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      paymentMode:
          'Cash', // Defaulting as backend doesn't seem to store it explicitly unless we use accounts
    );
  }
}

class TransactionService {
  static Future<void> saveTransaction(Map<String, dynamic> payload) async {
    try {
      final response = await ApiClient().dio.post(
        '/api/transactions',
        data: payload,
      );
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw 'Failed to create transaction';
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<TransactionModel>> getTransactions({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await ApiClient().dio.get(
        '/api/transactions',
        queryParameters: {'skip': skip, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
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
      final response = await ApiClient().dio.delete('/api/transactions/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw 'Failed to delete transaction';
      }
    } catch (e) {
      rethrow;
    }
  }
}
