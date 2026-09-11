import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';

class AuthService {
  static const String _tokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _roleKey = 'user_role';

  /// Admin login using email and password
  static Future<bool> adminLogin(String email, String password) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/auth/admin-login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['access_token']);
        await prefs.setString(_userIdKey, data['user_id']);
        await prefs.setString(_roleKey, data['role']);
        return true;
      } else {
        final data = json.decode(response.body);
        throw data['detail'] ?? 'Invalid User ID or Password. Please try again.';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'Unable to connect to the server. Please check your internet connection.';
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_roleKey);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}
