import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getStringList('billing_history');
  print('Saved Bills: ${data?.length}');
  print(data);
}
