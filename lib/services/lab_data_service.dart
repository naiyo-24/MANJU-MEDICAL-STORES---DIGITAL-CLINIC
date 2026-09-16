import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/lab_models.dart';
import '../config/api_constants.dart';
import 'auth_service.dart';

class LabDataService {
  static const String _testsKey = 'lab_tests';
  static const String _templatesKey = 'lab_templates';
  static const String _packagesKey = 'lab_packages';
  static const String _customCategoriesKey = 'custom_categories';

  // --- Custom Categories (API) ---
  static Future<String?> _getCategoryIdByName(String name) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-category/'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var item in data) {
          if (item['name'] == name) return item['id'];
        }
      }
    } catch (e) {
      print('Error getting category ID: $e');
    }
    return null;
  }

  static Future<List<String>> getCustomCategories() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-category/'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => e['name'].toString()).toList();
      }
    } catch (e) {
      print('Error getting categories: $e');
    }
    return [];
  }

  static Future<void> saveCustomCategory(String category) async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-category/'),
        headers: headers,
        body: json.encode({'name': category}),
      );
    } catch (e) {
      print('Error saving category: $e');
    }
  }

  static Future<void> deleteCustomCategory(String category) async {
    final id = await _getCategoryIdByName(category);
    if (id != null) {
      try {
        final headers = await _getHeaders();
        await http.delete(Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-category/$id'), headers: headers);
      } catch (e) {
        print('Error deleting category: $e');
      }
    }
  }
  
  static Future<void> renameCustomCategory(String oldName, String newName) async {
    final id = await _getCategoryIdByName(oldName);
    if (id != null) {
      try {
        final headers = await _getHeaders();
        await http.patch(
          Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-category/$id'),
          headers: headers,
          body: json.encode({'name': newName}),
        );
      } catch (e) {
        print('Error renaming category: $e');
      }
    } else {
      await saveCustomCategory(newName);
    }
  }

  // --- Common HTTP ---
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Tests ---
  static Future<List<LabTest>> getTests() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-catalog/'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.where((item) => item['type'] == 'SINGLE_TEST').map((j) => LabTest.fromJson(j)).toList();
      }
    } catch (e) {
      print('Error fetching tests: $e');
    }
    return [];
  }

  static Future<void> saveTest(LabTest test) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode(test.toJson());
      
      if (test.id.isEmpty) {
        await http.post(
          Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-catalog/'),
          headers: headers,
          body: body,
        );
        return;
      }
      
      final patchResponse = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-catalog/${test.id}'),
        headers: headers,
        body: body,
      );
      
      if (patchResponse.statusCode == 404 || patchResponse.statusCode == 422 || patchResponse.statusCode == 405) {
        await http.post(
          Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-catalog/'),
          headers: headers,
          body: body,
        );
      }
    } catch (e) {
      print('Error saving test: $e');
    }
  }

  static Future<bool> uploadCSV(List<int> fileBytes, String fileName) async {
    try {
      final token = await AuthService.getToken();
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-catalog/upload-csv'));
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        fileBytes,
        filename: fileName,
      ));
      
      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('CSV upload error: $e');
      return false;
    }
  }

  static Future<void> deleteTest(String id) async {
    try {
      final headers = await _getHeaders();
      await http.delete(Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-catalog/$id'), headers: headers);
    } catch (e) {
      print('Error deleting test: $e');
    }
  }

  // --- Templates ---
  static Future<List<LabTemplate>> getTemplates() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-template/'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((j) => LabTemplate.fromJson(j)).toList();
      }
    } catch (e) {
      print('Error getting templates: $e');
    }
    return [];
  }

  static Future<void> saveTemplate(LabTemplate template) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode(template.toJson());
      
      final patchResponse = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-template/${template.id}'),
        headers: headers,
        body: body,
      );
      
      if (patchResponse.statusCode == 404 || patchResponse.statusCode == 405) {
        await http.post(
          Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-template/'),
          headers: headers,
          body: body,
        );
      }
    } catch (e) {
      print('Error saving template: $e');
    }
  }

  static Future<void> deleteTemplate(String id) async {
    try {
      final headers = await _getHeaders();
      await http.delete(Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-template/$id'), headers: headers);
    } catch (e) {
      print('Error deleting template: $e');
    }
  }

  // --- Packages ---
  static Future<List<LabPackage>> getPackages() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-catalog/'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.where((item) => item['type'] == 'PACKAGE').map((j) => LabPackage.fromJson(j)).toList();
      }
    } catch (e) {
      print('Error fetching packages: $e');
    }
    return [];
  }

  static Future<bool> uploadCatalogCsv(List<int> fileBytes, String filename) async {
    try {
      final headers = await _getHeaders();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-catalog/upload-csv'),
      );
      
      request.headers.addAll({
        if (headers.containsKey('Authorization')) 
          'Authorization': headers['Authorization']!
      });

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
      ));

      final streamedResponse = await request.send();
      return streamedResponse.statusCode == 201;
    } catch (e) {
      print('Error uploading CSV: $e');
      return false;
    }
  }

  static Future<void> savePackage(LabPackage pkg) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode(pkg.toJson());
      
      final patchResponse = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-catalog/${pkg.id}'),
        headers: headers,
        body: body,
      );
      
      if (patchResponse.statusCode == 404 || patchResponse.statusCode == 422) {
        await http.post(
          Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-catalog/'),
          headers: headers,
          body: body,
        );
      }
    } catch (e) {
      print('Error saving package: $e');
    }
  }

  static Future<void> deletePackage(String id) async {
    try {
      final headers = await _getHeaders();
      await http.delete(Uri.parse('${ApiConstants.baseUrl}/api/admin/lab-catalog/$id'), headers: headers);
    } catch (e) {
      print('Error deleting package: $e');
    }
  }

  // --- Bookings ---
  static const String _bookingsKey = 'lab_bookings';

  static Future<List<LabBooking>> getBookings() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/lab-bookings'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          final formDetails = item['form_details'] ?? {};
          final bookedItems = item['booked_items'] as List<dynamic>? ?? [];
          final testIds = bookedItems.where((i) => i['type'] == 'TEST').map((i) => i['id'].toString()).toList();
          final packageIds = bookedItems.where((i) => i['type'] == 'PACKAGE').map((i) => i['id'].toString()).toList();

          return LabBooking(
            id: item['id'],
            patientName: formDetails['patientName'] ?? 'Unknown',
            patientPhone: formDetails['patientPhone'] ?? '',
            patientAge: formDetails['patientAge'] ?? '',
            patientGender: formDetails['patientGender'] ?? 'Other',
            bookingDate: item['preferred_date'] != null ? DateTime.parse(item['preferred_date']) : DateTime.now(),
            testIds: testIds,
            packageIds: packageIds,
            totalAmount: (item['total_amount'] ?? 0).toDouble(),
            status: item['status'] ?? 'Pending',
          );
        }).toList();
      }
    } catch (e) {
      print('Error getting bookings: $e');
    }
    return [];
  }

  static Future<void> saveBooking(LabBooking booking) async {
    try {
      final headers = await _getHeaders();
      final userId = await AuthService.getUserId() ?? ''; // Or generate UUID if not logged in
      
      final body = {
        'user_id': userId,
        'payment_method': 'COD',
        'item_ids': [...booking.testIds, ...booking.packageIds],
        'preferred_date': booking.bookingDate.toIso8601String().split('T')[0],
        'form_details': {
          'patientName': booking.patientName,
          'patientPhone': booking.patientPhone,
          'patientAge': booking.patientAge,
          'patientGender': booking.patientGender,
        },
      };

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/lab-bookings'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode != 201) {
        print('Failed to save booking: ${response.body}');
      }
    } catch (e) {
      print('Error saving booking: $e');
    }
  }

  static Future<void> deleteBooking(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/api/lab-bookings/$id/cancel'),
        headers: headers,
      );
      if (response.statusCode != 200) {
        print('Failed to delete booking: ${response.body}');
      }
    } catch (e) {
      print('Error deleting booking: $e');
    }
  }

  // --- Reports ---
  static const String _reportsKey = 'lab_reports';

  static Future<List<LabReport>> getReports() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_reportsKey) ?? [];
    if (jsonList.isEmpty) {
      return [
        LabReport(
          id: 'r1', reportId: 'RPT202609001', patientName: 'Rahul Das', patientPhone: '+91 98765 43210', patientAge: '32 Years', patientGender: 'Male',
          referredBy: 'Dr. Anirban Sen', testsPackageName: 'CBC, ESR', reportDate: DateTime.parse('2026-09-09T16:20:00'),
          status: 'Delivered', isSent: true, sampleId: 'S202609001', collectionDate: DateTime.parse('2026-09-09T09:30:00'),
        ),
        LabReport(
          id: 'r2', reportId: 'RPT202609002', patientName: 'Priya Sharma', patientPhone: '+91 98300 11223', patientAge: '28 Years', patientGender: 'Female',
          referredBy: 'Self', testsPackageName: 'Thyroid Profile', reportDate: DateTime.parse('2026-09-09T14:15:00'),
          status: 'Ready', isSent: false, sampleId: 'S202609002', collectionDate: DateTime.parse('2026-09-09T09:45:00'),
        ),
        LabReport(
          id: 'r3', reportId: 'RPT202609003', patientName: 'Suman Roy', patientPhone: '+91 98300 11223', patientAge: '45 Years', patientGender: 'Male',
          referredBy: 'Dr. Sen', testsPackageName: 'Full Body Checkup', reportDate: DateTime.parse('2026-09-09T12:40:00'),
          status: 'In Processing', isSent: false, sampleId: 'S202609003', collectionDate: DateTime.parse('2026-09-09T10:10:00'),
        ),
        LabReport(
          id: 'r4', reportId: 'RPT202609004', patientName: 'Neha Patel', patientPhone: '+91 98765 43210', patientAge: '52 Years', patientGender: 'Female',
          referredBy: 'Self', testsPackageName: 'Lipid Profile', reportDate: DateTime.parse('2026-09-09T11:10:00'),
          status: 'Delivered', isSent: true, sampleId: 'S202609004', collectionDate: DateTime.parse('2026-09-09T10:25:00'),
        ),
        LabReport(
          id: 'r5', reportId: 'RPT202609005', patientName: 'Karan Mehta', patientPhone: '+91 98765 43210', patientAge: '60 Years', patientGender: 'Male',
          referredBy: 'Dr. Anirban Sen', testsPackageName: 'HbA1c', reportDate: DateTime.parse('2026-09-09T10:50:00'),
          status: 'Pending', isSent: false, sampleId: 'S202609005', collectionDate: DateTime.parse('2026-09-09T11:00:00'),
        ),
        LabReport(
          id: 'r6', reportId: 'RPT202609006', patientName: 'Anita Singh', patientPhone: '+91 98765 43210', patientAge: '30 Years', patientGender: 'Female',
          referredBy: 'Self', testsPackageName: 'Vitamin D', reportDate: DateTime.parse('2026-09-08T17:30:00'),
          status: 'Delivered', isSent: true, sampleId: 'S202609006', collectionDate: DateTime.parse('2026-09-08T11:20:00'),
        ),
        LabReport(
          id: 'r7', reportId: 'RPT202609007', patientName: 'Deepak Shaw', patientPhone: '+91 98765 43210', patientAge: '40 Years', patientGender: 'Male',
          referredBy: 'System', testsPackageName: 'Liver Function Test', reportDate: DateTime.parse('2026-09-08T16:10:00'),
          status: 'Ready', isSent: false, sampleId: 'S202609007', collectionDate: DateTime.parse('2026-09-08T11:45:00'),
        ),
        LabReport(
          id: 'r8', reportId: 'RPT202609008', patientName: 'Pooja Verma', patientPhone: '+91 98765 43210', patientAge: '25 Years', patientGender: 'Female',
          referredBy: 'Self', testsPackageName: 'Diabetic Profile', reportDate: DateTime.parse('2026-09-08T13:25:00'),
          status: 'In Processing', isSent: false, sampleId: 'S202609008', collectionDate: DateTime.parse('2026-09-08T12:10:00'),
        ),
        LabReport(
          id: 'r9', reportId: 'RPT202609009', patientName: 'Amit Kumar', patientPhone: '+91 98765 43210', patientAge: '35 Years', patientGender: 'Male',
          referredBy: 'Dr. Sen', testsPackageName: 'KFT', reportDate: DateTime.parse('2026-09-08T11:45:00'),
          status: 'Delivered', isSent: true, sampleId: 'S202609009', collectionDate: DateTime.parse('2026-09-08T12:30:00'),
        ),
        LabReport(
          id: 'r10', reportId: 'RPT202609010', patientName: 'Rita Ghosh', patientPhone: '+91 98765 43210', patientAge: '42 Years', patientGender: 'Female',
          referredBy: 'Self', testsPackageName: 'Hormone Package', reportDate: DateTime.parse('2026-09-08T10:20:00'),
          status: 'Ready', isSent: false, sampleId: 'S202609010', collectionDate: DateTime.parse('2026-09-08T12:45:00'),
        ),
      ];
    }
    return jsonList.map((j) => LabReport.fromJson(jsonDecode(j))).toList();
  }

  static Future<List<LabActivity>> getActivities() async {
    return [
      LabActivity(
        id: 'a1', dateTime: DateTime.parse('2026-09-09T16:45:00'), type: 'Report Sent', description: 'Report sent via WhatsApp to Suman Roy', referenceId: 'RPT202609001', performedBy: 'Amit Kumar',
        patientName: 'Suman Roy', patientPhone: '9830011223', message: 'Dear Suman Roy,\nYour lab report is ready. Please find the attached report.\n\nRegards,\nManju Diagnostic Lab',
      ),
      LabActivity(id: 'a2', dateTime: DateTime.parse('2026-09-09T16:20:00'), type: 'Report Generated', description: 'Lab report generated for Rahul Das', referenceId: 'RPT202609002', performedBy: 'Dr. Sen', patientName: 'Rahul Das', patientPhone: '9876543210'),
      LabActivity(id: 'a3', dateTime: DateTime.parse('2026-09-09T15:10:00'), type: 'Sample Processed', description: 'Biochemistry tests processed', referenceId: 'SMP202609003', performedBy: 'Neha Patel'),
      LabActivity(id: 'a4', dateTime: DateTime.parse('2026-09-09T11:25:00'), type: 'Sample Collected', description: 'Sample collected from Priya Sharma', referenceId: 'SMP202609004', performedBy: 'Amit Kumar', patientName: 'Priya Sharma', patientPhone: '9123456789'),
      LabActivity(id: 'a5', dateTime: DateTime.parse('2026-09-09T10:15:00'), type: 'Booking Created', description: 'New booking created for Karan Mehta', referenceId: 'LB000126', performedBy: 'Reception', patientName: 'Karan Mehta', patientPhone: '9123044567'),
      LabActivity(id: 'a6', dateTime: DateTime.parse('2026-09-08T18:30:00'), type: 'Report Delivered', description: 'Report delivered (Email) to Anita Singh', referenceId: 'RPT202609005', performedBy: 'System', patientName: 'Anita Singh', patientPhone: '9876509876'),
      LabActivity(id: 'a7', dateTime: DateTime.parse('2026-09-08T16:10:00'), type: 'Status Updated', description: 'Sample status changed to In Processing', referenceId: 'SMP202609006', performedBy: 'Neha Patel'),
      LabActivity(id: 'a8', dateTime: DateTime.parse('2026-09-08T12:05:00'), type: 'Payment Received', description: 'Payment received ₹1,200 (UPI)', referenceId: 'LB000127', performedBy: 'Reception'),
      LabActivity(id: 'a9', dateTime: DateTime.parse('2026-09-08T10:50:00'), type: 'Template Used', description: 'Lipid Profile template used', referenceId: 'LB000128', performedBy: 'Dr. Sen'),
      LabActivity(id: 'a10', dateTime: DateTime.parse('2026-09-08T09:30:00'), type: 'Login', description: 'User logged in', referenceId: '-', performedBy: 'Lab Admin'),
    ];
  }
}
