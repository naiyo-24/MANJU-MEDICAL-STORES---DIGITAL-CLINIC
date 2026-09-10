import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String age;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.age,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'age': age,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      age: json['age'] ?? '',
    );
  }
}

class CustomerService {
  static const String _customersKey = 'saved_customers';

  static Future<void> saveCustomer(Customer customer) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> customersJson = prefs.getStringList(_customersKey) ?? [];
    
    // Check if customer with same phone exists and update, else add new
    int index = customersJson.indexWhere((c) {
      final map = jsonDecode(c);
      return map['phone'] == customer.phone && customer.phone.isNotEmpty;
    });

    if (index != -1) {
      customersJson[index] = jsonEncode(customer.toJson());
    } else {
      customersJson.add(jsonEncode(customer.toJson()));
    }

    await prefs.setStringList(_customersKey, customersJson);
  }

  static Future<List<Customer>> getCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> customersJson = prefs.getStringList(_customersKey) ?? [];
    
    return customersJson.map((c) => Customer.fromJson(jsonDecode(c))).toList();
  }
}
