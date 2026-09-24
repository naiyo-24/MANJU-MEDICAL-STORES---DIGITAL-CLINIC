import 'package:flutter_riverpod/flutter_riverpod.dart';

class BillingState {
  final List<Map<String, dynamic>> currentBill;
  final double discountValue;
  final bool isDiscountPercentage;
  final double gstValue;
  final bool isGstPercentage;
  final double receivedAmount;
  final String paymentMethod;
  final String? selectedDoctorId;
  final String selectedDoctorName;
  final String? savedCustomerId;
  final String customerName;
  final String customerPhone;
  final String customerLocation;
  final String searchQuery;
  final int selectedCategoryIndex;
  final String selectedFormat;

  BillingState({
    this.currentBill = const [],
    this.discountValue = 0.0,
    this.isDiscountPercentage = true,
    this.gstValue = 0.0,
    this.isGstPercentage = true,
    this.receivedAmount = 0.0,
    this.paymentMethod = 'CASH',
    this.selectedDoctorId,
    this.selectedDoctorName = 'Walk-in',
    this.savedCustomerId,
    this.customerName = '',
    this.customerPhone = '',
    this.customerLocation = '',
    this.searchQuery = '',
    this.selectedCategoryIndex = 0,
    this.selectedFormat = 'A4',
  });

  BillingState copyWith({
    List<Map<String, dynamic>>? currentBill,
    double? discountValue,
    bool? isDiscountPercentage,
    double? gstValue,
    bool? isGstPercentage,
    double? receivedAmount,
    String? paymentMethod,
    String? selectedDoctorId,
    String? selectedDoctorName,
    String? savedCustomerId,
    String? customerName,
    String? customerPhone,
    String? customerLocation,
    String? searchQuery,
    int? selectedCategoryIndex,
    String? selectedFormat,
  }) {
    return BillingState(
      currentBill: currentBill ?? this.currentBill,
      discountValue: discountValue ?? this.discountValue,
      isDiscountPercentage: isDiscountPercentage ?? this.isDiscountPercentage,
      gstValue: gstValue ?? this.gstValue,
      isGstPercentage: isGstPercentage ?? this.isGstPercentage,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      selectedDoctorId: selectedDoctorId ?? this.selectedDoctorId,
      selectedDoctorName: selectedDoctorName ?? this.selectedDoctorName,
      savedCustomerId: savedCustomerId ?? this.savedCustomerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerLocation: customerLocation ?? this.customerLocation,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryIndex: selectedCategoryIndex ?? this.selectedCategoryIndex,
      selectedFormat: selectedFormat ?? this.selectedFormat,
    );
  }

  double get subtotal => currentBill.fold(0.0, (sum, item) => sum + ((item['total'] ?? 0.0) as num).toDouble());
  double get discountAmount => isDiscountPercentage ? (subtotal * (discountValue / 100)) : discountValue;
  double get totalAfterDiscount => subtotal - discountAmount;
  double get gstAmount => isGstPercentage ? (totalAfterDiscount * (gstValue / 100)) : gstValue;
  double get grandTotal => totalAfterDiscount + gstAmount;
}

class BillingNotifier extends Notifier<BillingState> {
  @override
  BillingState build() {
    return BillingState();
  }

  void addItem(Map<String, dynamic> item) {
    // Check if it already exists by name
    final index = state.currentBill.indexWhere((element) => element['name'] == item['name']);
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

  void setBill(List<Map<String, dynamic>> items) {
    state = state.copyWith(currentBill: items);
  }

  void updateDiscount(double value, bool isPercentage) {
    state = state.copyWith(
      discountValue: value,
      isDiscountPercentage: isPercentage,
    );
  }

  void updateGst(double value, bool isPercentage) {
    state = state.copyWith(
      gstValue: value,
      isGstPercentage: isPercentage,
    );
  }

  void updateReceivedAmount(double amount) {
    state = state.copyWith(receivedAmount: amount);
  }

  void updatePaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void updateDoctor(String? id, String name) {
    state = state.copyWith(selectedDoctorId: id, selectedDoctorName: name);
  }

  void updateCustomerInfo(String name, String phone, String location, {String? id}) {
    state = state.copyWith(
      customerName: name,
      customerPhone: phone,
      customerLocation: location,
      savedCustomerId: id ?? state.savedCustomerId,
    );
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateCategory(int index) {
    state = state.copyWith(selectedCategoryIndex: index);
  }

  void updateSelectedFormat(String format) {
    state = state.copyWith(selectedFormat: format);
  }

  void clearBill() {
    state = BillingState();
  }
}
