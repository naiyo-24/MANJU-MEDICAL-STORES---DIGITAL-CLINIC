import 'package:flutter_riverpod/flutter_riverpod.dart';

class BillingState {
  final List<Map<String, dynamic>> currentBill;
  final double discountValue;
  final bool isDiscountPercentage;
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
  final bool isGstEnabled;
  final String gstNumber;
  final double roundOff;

  BillingState({
    this.currentBill = const [],
    this.isGstEnabled = true,
    this.gstNumber = '',
    this.roundOff = 0.0,
    this.discountValue = 0.0,
    this.isDiscountPercentage = true,
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
    this.selectedFormat = 'A5',
  });

  BillingState copyWith({
    List<Map<String, dynamic>>? currentBill,
    double? discountValue,
    bool? isDiscountPercentage,
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
    bool? isGstEnabled,
    String? gstNumber,
    double? roundOff,
  }) {
    return BillingState(
      currentBill: currentBill ?? this.currentBill,
      discountValue: discountValue ?? this.discountValue,
      isDiscountPercentage: isDiscountPercentage ?? this.isDiscountPercentage,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      selectedDoctorId: selectedDoctorId ?? this.selectedDoctorId,
      selectedDoctorName: selectedDoctorName ?? this.selectedDoctorName,
      savedCustomerId: savedCustomerId ?? this.savedCustomerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerLocation: customerLocation ?? this.customerLocation,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryIndex:
          selectedCategoryIndex ?? this.selectedCategoryIndex,
      selectedFormat: selectedFormat ?? this.selectedFormat,
      isGstEnabled: isGstEnabled ?? this.isGstEnabled,
      gstNumber: gstNumber ?? this.gstNumber,
      roundOff: roundOff ?? this.roundOff,
    );
  }

  double get subtotal => currentBill.fold(0.0, (sum, item) {
    double cgst = (item['cgst'] as num?)?.toDouble() ?? 0.0;
    double sgst = (item['sgst'] as num?)?.toDouble() ?? 0.0;
    double gstRate = cgst + sgst;
    double total = ((item['total'] ?? 0.0) as num).toDouble();
    double base = gstRate > 0 ? total / (1 + gstRate / 100) : total;
    return sum + base;
  });
  double get discountAmount =>
      isDiscountPercentage ? (subtotal * (discountValue / 100)) : discountValue;
  double get totalAfterDiscount => subtotal - discountAmount;

  double get itemGstAmount {
    return currentBill.fold(0.0, (sum, item) {
      double cgst = (item['cgst'] as num?)?.toDouble() ?? 0.0;
      double sgst = (item['sgst'] as num?)?.toDouble() ?? 0.0;
      double gstRate = cgst + sgst;
      double total = (item['total'] as num?)?.toDouble() ?? 0.0;
      double base = gstRate > 0 ? total / (1 + gstRate / 100) : total;
      // Subtract proportional item discount from the item taxable base
      double proportionalDiscount = subtotal > 0
          ? (base / subtotal) * discountAmount
          : 0.0;
      double itemBaseAfterDiscount = base - proportionalDiscount;
      return sum + (itemBaseAfterDiscount * gstRate / 100);
    });
  }

  double get gstAmount => isGstEnabled ? itemGstAmount : 0.0;
  double get rawGrandTotal => totalAfterDiscount + gstAmount;
  double get grandTotal => rawGrandTotal + roundOff;
}

class BillingNotifier extends Notifier<BillingState> {
  @override
  BillingState build() {
    return BillingState();
  }

  void setRoundOff(double value) {
    state = state.copyWith(roundOff: value);
  }

  bool addItem(Map<String, dynamic> item) {
    // Check if it already exists by name
    final index = state.currentBill.indexWhere(
      (element) => element['name'] == item['name'],
    );
    if (index != -1) {
      return false; // Item already exists, don't add duplicate
    } else {
      state = state.copyWith(currentBill: [...state.currentBill, item]);
      return true; // Item added successfully
    }
  }

  void updateItemQuantity(int index, int newQty) {
    if (newQty < 1) return;
    final updatedBill = List<Map<String, dynamic>>.from(state.currentBill);
    double price = (updatedBill[index]['price'] as num).toDouble();
    double discount = (updatedBill[index]['discount'] as num?)?.toDouble() ?? 0.0;
    bool isLoose = updatedBill[index]['is_loose'] ?? false;
    int packSize = updatedBill[index]['pack_size'] ?? 1;

    double effectivePrice = isLoose ? (price / packSize) : price;
    double itemTotal = newQty * effectivePrice;
    double itemTotalAfterDiscount = itemTotal - (itemTotal * (discount / 100));
    
    updatedBill[index] = {
      ...updatedBill[index],
      'qty': newQty,
      'total': itemTotalAfterDiscount,
    };
    state = state.copyWith(currentBill: updatedBill);
  }

  void toggleItemLoose(int index) {
    final updatedBill = List<Map<String, dynamic>>.from(state.currentBill);
    bool currentLoose = updatedBill[index]['is_loose'] ?? false;
    bool newLoose = !currentLoose;
    
    double price = (updatedBill[index]['price'] as num).toDouble();
    double discount = (updatedBill[index]['discount'] as num?)?.toDouble() ?? 0.0;
    int packSize = updatedBill[index]['pack_size'] ?? 1;
    int qty = (updatedBill[index]['qty'] as num).toInt();

    double effectivePrice = newLoose ? (price / packSize) : price;
    double itemTotal = qty * effectivePrice;
    double itemTotalAfterDiscount = itemTotal - (itemTotal * (discount / 100));

    updatedBill[index] = {
      ...updatedBill[index],
      'is_loose': newLoose,
      'total': itemTotalAfterDiscount,
    };
    state = state.copyWith(currentBill: updatedBill);
  }

  void updateItemDiscount(int index, double discount) {
    final updatedBill = List<Map<String, dynamic>>.from(state.currentBill);
    double price = (updatedBill[index]['price'] as num).toDouble();
    int qty = (updatedBill[index]['qty'] as num).toInt();
    
    bool isLoose = updatedBill[index]['is_loose'] ?? false;
    int packSize = updatedBill[index]['pack_size'] ?? 1;

    double effectivePrice = isLoose ? (price / packSize) : price;
    double itemTotal = qty * effectivePrice;
    double itemTotalAfterDiscount = itemTotal - (itemTotal * (discount / 100));
    
    updatedBill[index] = {
      ...updatedBill[index],
      'discount': discount,
      'total': itemTotalAfterDiscount,
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

  void updateItemGst(int index, bool enabled, double rate) {
    final updatedBill = List<Map<String, dynamic>>.from(state.currentBill);
    updatedBill[index] = {
      ...updatedBill[index],
      'gst_enabled': enabled,
      'gst_rate': rate,
      'cgst': enabled ? rate / 2 : 0.0,
      'sgst': enabled ? rate / 2 : 0.0,
    };
    state = state.copyWith(currentBill: updatedBill);
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

  void updateCustomerInfo(
    String name,
    String phone,
    String location, {
    String? id,
  }) {
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

  void toggleGst(bool? value) {
    if (value != null) {
      state = state.copyWith(isGstEnabled: value);
    }
  }

  void updateGstNumber(String number) {
    state = state.copyWith(gstNumber: number);
  }
}
