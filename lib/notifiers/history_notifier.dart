import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/billing_service.dart';

import 'package:intl/intl.dart';
import '../services/billing_history_service.dart';

class HistoryState {
  final List<Map<String, dynamic>> transactions;
  final Map<String, dynamic> summary;

  HistoryState({
    required this.transactions,
    required this.summary,
  });
}

class HistoryNotifier extends AsyncNotifier<HistoryState> {
  @override
  Future<HistoryState> build() async {
    return _fetchHistory();
  }

  Future<HistoryState> _fetchHistory() async {
    final response = await BillingService.getPosHistory();
    
    final historyList = response['history'] as List? ?? [];
    
    final transactions = historyList.map((item) {
      String dateStr = item['date'].toString();
      if (!dateStr.endsWith('Z')) dateStr += 'Z';
      final dt = (DateTime.tryParse(dateStr) ?? DateTime.now()).toLocal();
      final itemsList = (item['items_detail'] as List?)?.map((i) => Map<String, dynamic>.from(i)).toList() ?? [];
      double calculatedSubtotal = 0.0;
      for (var i in itemsList) {
        calculatedSubtotal += ((i['price'] as num?)?.toDouble() ?? 0.0) * ((i['qty'] as num?)?.toInt() ?? 1);
      }
      double grandTotalVal = (item['amount'] as num?)?.toDouble() ?? 0.0;
      double calculatedDiscount = calculatedSubtotal > grandTotalVal ? calculatedSubtotal - grandTotalVal : 0.0;

      return {
        'date': DateFormat('dd MMM yyyy').format(dt),
        'time': DateFormat('hh:mm a').format(dt),
        'createdAtDate': dt,
        'refNo': item['bill_no'],
        'customerName': item['customer_name']?.isEmpty ?? true ? 'Walk-in' : item['customer_name'],
        'customerPhone': item['customer_phone'] ?? '',
        'type': item['type'] ?? 'Sale',
        'items': item['items'] ?? 0,
        'amount': grandTotalVal,
        'paymentMode': item['payment_mode'] ?? 'Cash',
        'status': item['status'] ?? 'Completed',
        'originalBill': SavedBill(
          id: item['id'].toString(),
          invoiceNo: item['bill_no'].toString(),
          customerName: item['customer_name']?.isEmpty ?? true ? 'Walk-in' : item['customer_name'],
          customerPhone: item['customer_phone']?.toString() ?? '',
          doctorName: '',
          subtotal: calculatedSubtotal > 0 ? calculatedSubtotal : grandTotalVal,
          discount: calculatedDiscount,
          tax: 0.0,
          grandTotal: grandTotalVal,
          items: itemsList,
          createdAt: dt,
        ),
      };
    }).toList();

    return HistoryState(
      transactions: transactions.cast<Map<String, dynamic>>(),
      summary: Map<String, dynamic>.from(response['summary'] ?? {}),
    );
  }

  Future<void> reloadHistory() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchHistory());
  }
}
