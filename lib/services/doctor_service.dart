import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import 'auth_service.dart';

class Doctor {
  final String id;
  final String name;

  Doctor({required this.id, required this.name});

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Doctor',
    );
  }
}

class DoctorService {
  static Future<List<Doctor>> fetchDoctors() async {
    final token = await AuthService.getToken();
    
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/doctors/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Doctor.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch doctors: ${response.body}');
    }
  }
}
