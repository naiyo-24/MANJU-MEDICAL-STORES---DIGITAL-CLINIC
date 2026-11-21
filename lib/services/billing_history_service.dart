import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/counter_models.dart';
export '../models/counter_models.dart';

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

    // 30-day cutoff auto-purge
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));

    final List<SavedBill> validBills = [];
    final List<String> validBillsJson = [];

    for (final draftStr in currentHistory) {
      try {
        final Map<String, dynamic> json = jsonDecode(draftStr);
        final bill = SavedBill.fromJson(json);
        if (bill.createdAt.isAfter(cutoffDate)) {
          validBills.add(bill);
          validBillsJson.add(draftStr);
        }
      } catch (_) {
        // Skip corrupted entries
      }
    }

    // If any bills expired, prune storage immediately
    if (validBillsJson.length != currentHistory.length) {
      await prefs.setStringList(_key, validBillsJson);
    }

    // Sort by latest first
    validBills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return validBills;
  }

  static Future<void> updateBill(SavedBill updatedBill) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentHistory = prefs.getStringList(_key) ?? [];

    int index = -1;
    for (int i = 0; i < currentHistory.length; i++) {
      try {
        final map = jsonDecode(currentHistory[i]);
        if (map['id'] == updatedBill.id || map['invoiceNo'] == updatedBill.invoiceNo) {
          index = i;
          break;
        }
      } catch (_) {}
    }

    if (index != -1) {
      currentHistory[index] = jsonEncode(updatedBill.toJson());
    } else {
      currentHistory.add(jsonEncode(updatedBill.toJson()));
    }

    await prefs.setStringList(_key, currentHistory);
    historyUpdated.value++;
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
