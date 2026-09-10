import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionModel {
  final String id;
  final String date;
  final String time;
  final String type; // 'Income', 'Expense'
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'type': type,
      'category': category,
      'description': description,
      'amount': amount,
      'paymentMode': paymentMode,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      paymentMode: json['paymentMode'] ?? '',
    );
  }
}

class TransactionService {
  static const String _transactionsKey = 'saved_transactions';

  static Future<void> saveTransaction(TransactionModel transaction) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> txnsJson = prefs.getStringList(_transactionsKey) ?? [];
    
    int index = txnsJson.indexWhere((c) {
      final map = jsonDecode(c);
      return map['id'] == transaction.id;
    });

    if (index != -1) {
      txnsJson[index] = jsonEncode(transaction.toJson());
    } else {
      txnsJson.insert(0, jsonEncode(transaction.toJson())); // Add to top
    }

    await prefs.setStringList(_transactionsKey, txnsJson);
  }

  static Future<List<TransactionModel>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> txnsJson = prefs.getStringList(_transactionsKey) ?? [];
    
    return txnsJson.map((c) => TransactionModel.fromJson(jsonDecode(c))).toList();
  }

  static Future<void> deleteTransaction(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> txnsJson = prefs.getStringList(_transactionsKey) ?? [];
    
    txnsJson.removeWhere((c) {
      final map = jsonDecode(c);
      return map['id'] == id;
    });

    await prefs.setStringList(_transactionsKey, txnsJson);
  }
}
