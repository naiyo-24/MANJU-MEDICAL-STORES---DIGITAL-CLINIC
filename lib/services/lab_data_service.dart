import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lab_models.dart';

class LabDataService {
  static const String _testsKey = 'lab_tests';
  static const String _templatesKey = 'lab_templates';
  static const String _packagesKey = 'lab_packages';

  // --- Tests ---
  static Future<List<LabTest>> getTests() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_testsKey) ?? [];
    if (jsonList.isEmpty) {
      // Return some dummy data
      return [
        LabTest(id: 't1', name: 'Complete Blood Count (CBC)', description: 'Evaluates overall health and detects a wide range of disorders.', category: 'Hematology', price: 350.0, templateId: 'temp_cbc'),
        LabTest(id: 't2', name: 'Lipid Profile', description: 'Measures the amount of cholesterol and triglycerides in your blood.', category: 'Biochemistry', price: 1200.0, templateId: 'temp_lipid'),
        LabTest(id: 't3', name: 'Thyroid Profile (T3, T4, TSH)', description: 'Checks how well your thyroid is working.', category: 'Endocrinology', price: 950.0, templateId: 'temp_thyroid'),
      ];
    }
    return jsonList.map((j) => LabTest.fromJson(jsonDecode(j))).toList();
  }

  static Future<void> saveTest(LabTest test) async {
    final tests = await getTests();
    final index = tests.indexWhere((t) => t.id == test.id);
    if (index >= 0) {
      tests[index] = test;
    } else {
      tests.add(test);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_testsKey, tests.map((t) => jsonEncode(t.toJson())).toList());
  }

  static Future<void> deleteTest(String id) async {
    final tests = await getTests();
    tests.removeWhere((t) => t.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_testsKey, tests.map((t) => jsonEncode(t.toJson())).toList());
  }

  // --- Templates ---
  static Future<List<LabTemplate>> getTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_templatesKey) ?? [];
    if (jsonList.isEmpty) {
      return [
        LabTemplate(id: 'temp_cbc', name: 'CBC Template', fields: [
          TemplateField(name: 'Hemoglobin', unit: 'g/dL', normalRange: '13.0 - 17.0'),
          TemplateField(name: 'WBC Count', unit: 'cells/mcL', normalRange: '4000 - 11000'),
          TemplateField(name: 'Platelet Count', unit: 'lakhs/mcL', normalRange: '1.5 - 4.5'),
        ]),
        LabTemplate(id: 'temp_lipid', name: 'Lipid Profile Template', fields: [
          TemplateField(name: 'Total Cholesterol', unit: 'mg/dL', normalRange: '< 200'),
          TemplateField(name: 'HDL Cholesterol', unit: 'mg/dL', normalRange: '> 40'),
          TemplateField(name: 'LDL Cholesterol', unit: 'mg/dL', normalRange: '< 100'),
          TemplateField(name: 'Triglycerides', unit: 'mg/dL', normalRange: '< 150'),
        ]),
      ];
    }
    return jsonList.map((j) => LabTemplate.fromJson(jsonDecode(j))).toList();
  }

  static Future<void> saveTemplate(LabTemplate template) async {
    final templates = await getTemplates();
    final index = templates.indexWhere((t) => t.id == template.id);
    if (index >= 0) {
      templates[index] = template;
    } else {
      templates.add(template);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_templatesKey, templates.map((t) => jsonEncode(t.toJson())).toList());
  }

  static Future<void> deleteTemplate(String id) async {
    final templates = await getTemplates();
    templates.removeWhere((t) => t.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_templatesKey, templates.map((t) => jsonEncode(t.toJson())).toList());
  }

  // --- Packages ---
  static Future<List<LabPackage>> getPackages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_packagesKey) ?? [];
    if (jsonList.isEmpty) {
      return [
        LabPackage(id: 'pkg1', name: 'Basic Health Checkup', description: 'Essential tests for monitoring general health.', testIds: ['t1', 't2'], discountedPrice: 1400.0),
        LabPackage(id: 'pkg2', name: 'Comprehensive Body Profile', description: 'A thorough examination of vital body organs and functions.', testIds: ['t1', 't2', 't3'], discountedPrice: 2200.0),
      ];
    }
    return jsonList.map((j) => LabPackage.fromJson(jsonDecode(j))).toList();
  }

  static Future<void> savePackage(LabPackage pkg) async {
    final packages = await getPackages();
    final index = packages.indexWhere((p) => p.id == pkg.id);
    if (index >= 0) {
      packages[index] = pkg;
    } else {
      packages.add(pkg);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_packagesKey, packages.map((p) => jsonEncode(p.toJson())).toList());
  }

  static Future<void> deletePackage(String id) async {
    final packages = await getPackages();
    packages.removeWhere((p) => p.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_packagesKey, packages.map((p) => jsonEncode(p.toJson())).toList());
  }

  // --- Bookings ---
  static const String _bookingsKey = 'lab_bookings';

  static Future<List<LabBooking>> getBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_bookingsKey) ?? [];
    if (jsonList.isEmpty) {
      // Mock data
      return [
        LabBooking(
          id: 'b1',
          patientName: 'John Doe',
          patientPhone: '9876543210',
          patientAge: '34',
          patientGender: 'Male',
          bookingDate: DateTime.now().subtract(const Duration(days: 1)),
          testIds: ['t1'],
          packageIds: [],
          totalAmount: 350.0,
          status: 'Sample Collected',
        ),
      ];
    }
    return jsonList.map((j) => LabBooking.fromJson(jsonDecode(j))).toList();
  }

  static Future<void> saveBooking(LabBooking booking) async {
    final bookings = await getBookings();
    final index = bookings.indexWhere((b) => b.id == booking.id);
    if (index >= 0) {
      bookings[index] = booking;
    } else {
      bookings.add(booking);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_bookingsKey, bookings.map((b) => jsonEncode(b.toJson())).toList());
  }

  static Future<void> deleteBooking(String id) async {
    final bookings = await getBookings();
    bookings.removeWhere((b) => b.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_bookingsKey, bookings.map((b) => jsonEncode(b.toJson())).toList());
  }
}
