import 'package:flutter_riverpod/flutter_riverpod.dart';

class BillingState {
  final List<Map<String, dynamic>> currentBill;
  final double discountValue;
  final bool isDiscountPercentage;
  final double receivedAmount;

  BillingState({
    this.currentBill = const [],
    this.discountValue = 0.0,
    this.isDiscountPercentage = true,
    this.receivedAmount = 0.0,
  });

  BillingState copyWith({
    List<Map<String, dynamic>>? currentBill,
    double? discountValue,
    bool? isDiscountPercentage,
    double? receivedAmount,
  }) {
    return BillingState(
      currentBill: currentBill ?? this.currentBill,
      discountValue: discountValue ?? this.discountValue,
      isDiscountPercentage: isDiscountPercentage ?? this.isDiscountPercentage,
      receivedAmount: receivedAmount ?? this.receivedAmount,
    );
  }
}

class BillingNotifier extends StateNotifier<BillingState> {
  BillingNotifier() : super(BillingState());

  void addItem(Map<String, dynamic> item) {
    // Check if it already exists
    final index = state.currentBill.indexWhere((element) => element['id'] == item['id']);
    if (index != -1) {
      final updatedBill = List<Map<String, dynamic>>.from(state.currentBill);
      int newQty = (updatedBill[index]['qty'] as int) + 1;
      double price = (updatedBill[index]['price'] as num).toDouble();
      updatedBill[index] = {
        ...updatedBill[index],
        'qty': newQty,
        'total': newQty * price,
      };
      state = state.copyWith(currentBill: updatedBill);
    } else {
      state = state.copyWith(currentBill: [...state.currentBill, item]);
    }
  }

  void updateItemQuantity(int index, int newQty) {
    if (newQty < 1) return;
    final updatedBill = List<Map<String, dynamic>>.from(state.currentBill);
    double price = (updatedBill[index]['price'] as num).toDouble();
    updatedBill[index] = {
      ...updatedBill[index],
      'qty': newQty,
      'total': newQty * price,
    };
    state = state.copyWith(currentBill: updatedBill);
  }

  void removeItem(int index) {
    final updatedBill = List<Map<String, dynamic>>.from(state.currentBill);
    updatedBill.removeAt(index);
    state = state.copyWith(currentBill: updatedBill);
  }

  void updateDiscount(double value, bool isPercentage) {
    state = state.copyWith(
      discountValue: value,
      isDiscountPercentage: isPercentage,
    );
  }

  void updateReceivedAmount(double amount) {
    state = state.copyWith(receivedAmount: amount);
  }

  void clearBill() {
    state = BillingState();
  }
}

final billingProvider = StateNotifierProvider<BillingNotifier, BillingState>((ref) {
  return BillingNotifier();
});
