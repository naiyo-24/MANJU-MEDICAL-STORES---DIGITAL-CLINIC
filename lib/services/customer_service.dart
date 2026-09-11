import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import 'auth_service.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String location;
  final bool isActive;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.location = '',
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'location': location,
      'is_active': isActive,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      location: json['location'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}

class CustomerService {
  static Future<Customer> saveCustomer(Customer customer) async {
    final token = await AuthService.getToken();
    
    // For saving a customer, we hit the create user endpoint.
    // If the customer exists by phone, the backend handles it or we could use PATCH if id is present.
    // We'll use POST /api/users/create.
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/users/create'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email.isNotEmpty ? customer.email : null,
        'location': customer.location.isNotEmpty ? customer.location : null,
        'is_active': customer.isActive,
        'role': 'USER',
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Customer.fromJson(data);
    } else {
      throw Exception('Failed to save customer');
    }
  }

  static Future<void> updateCustomer(Customer customer) async {
    final token = await AuthService.getToken();
    
    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/api/users/${customer.id}'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email.isNotEmpty ? customer.email : null,
        'location': customer.location.isNotEmpty ? customer.location : null,
        'is_active': customer.isActive,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update customer');
    }
  }

  static Future<List<Customer>> getCustomers() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/users'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Customer.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch customers');
    }
  }
}
