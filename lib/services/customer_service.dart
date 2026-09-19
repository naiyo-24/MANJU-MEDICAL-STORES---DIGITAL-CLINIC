import 'package:dio/dio.dart';
import '../config/api_client.dart';
import '../models/counter_models.dart';
export '../models/counter_models.dart';

class CustomerService {
  static Future<Customer> saveCustomer(Customer customer) async {
    // For saving a customer, we hit the create user endpoint.
    // If the customer exists by phone, the backend handles it or we could use PATCH if id is present.
    // We'll use POST /api/users/create.
    final response = await ApiClient().dio.post(
      '/api/users/create',
      data: {
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email.isNotEmpty ? customer.email : null,
        'location': customer.location.isNotEmpty ? customer.location : null,
        'is_active': customer.isActive,
        'role': 'USER',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Customer.fromJson(response.data);
    } else {
      throw Exception('Failed to save customer');
    }
  }

  static Future<void> updateCustomer(Customer customer) async {
    final response = await ApiClient().dio.patch(
      '/api/users/${customer.id}',
      data: {
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email.isNotEmpty ? customer.email : null,
        'location': customer.location.isNotEmpty ? customer.location : null,
        'is_active': customer.isActive,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update customer');
    }
  }

  static Future<List<Customer>> getCustomers() async {
    final response = await ApiClient().dio.get('/api/users');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => Customer.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch customers');
    }
  }
}
