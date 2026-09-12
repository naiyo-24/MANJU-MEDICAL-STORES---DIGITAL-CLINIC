import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedBill {
  final String id;
  final String invoiceNo;
  final String customerName;
  final String customerPhone;
  final String doctorName;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;
  final List<Map<String, dynamic>> items;
  final DateTime createdAt;

  SavedBill({
    required this.id,
    required this.invoiceNo,
    required this.customerName,
    required this.customerPhone,
    required this.doctorName,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.grandTotal,
    required this.items,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceNo': invoiceNo,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'doctorName': doctorName,
    'subtotal': subtotal,
    'discount': discount,
    'tax': tax,
    'grandTotal': grandTotal,
    'items': items,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavedBill.fromJson(Map<String, dynamic> json) => SavedBill(
    id: json['id'],
    invoiceNo: json['invoiceNo'],
    customerName: json['customerName'],
    customerPhone: json['customerPhone'] ?? '',
    doctorName: json['doctorName'] ?? '',
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
    tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
    grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
    items: List<Map<String, dynamic>>.from(json['items'] ?? []),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class BillingHistoryService {
  static const String _key = 'billing_history';
  
  // Notifier to let the UI know when history is updated
  static final ValueNotifier<int> historyUpdated = ValueNotifier(0);

  static Future<void> saveBill(SavedBill bill) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentHistory = prefs.getStringList(_key) ?? [];
    
    currentHistory.add(jsonEncode(bill.toJson()));
    await prefs.setStringList(_key, currentHistory);
    
    // Notify listeners that history changed
    historyUpdated.value++;
  }

  static Future<List<SavedBill>> getBillingHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentHistory = prefs.getStringList(_key) ?? [];
    
    final bills = currentHistory.map((draftStr) {
      final Map<String, dynamic> json = jsonDecode(draftStr);
      return SavedBill.fromJson(json);
    }).toList();
    
    // Sort by latest first
    bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bills;
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
