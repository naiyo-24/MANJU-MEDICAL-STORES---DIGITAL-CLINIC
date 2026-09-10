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
        LabTest(id: 't1', testCode: 'T001', name: 'Complete Blood Count (CBC)', description: 'Measures different components of blood including RBC, WBC, Hemoglobin, Platelets, etc.', category: 'Hematology', price: 350.0, templateId: 'temp_cbc', sampleType: 'Blood', reportingTime: '6 - 8 hours', isActive: true),
        LabTest(id: 't2', testCode: 'T002', name: 'Lipid Profile', description: 'Measures the amount of cholesterol and triglycerides in your blood.', category: 'Biochemistry', price: 1200.0, templateId: 'temp_lipid', sampleType: 'Blood', reportingTime: '12 hours', isActive: true),
        LabTest(id: 't3', testCode: 'T003', name: 'Thyroid Profile (T3, T4, TSH)', description: 'Checks how well your thyroid is working.', category: 'Hormones', price: 950.0, templateId: 'temp_thyroid', sampleType: 'Blood', reportingTime: '24 hours', isActive: true),
        LabTest(id: 't4', testCode: 'T004', name: 'HbA1c', description: 'Measures average blood sugar levels over the past 3 months.', category: 'Diabetes', price: 650.0, templateId: 'temp_hba1c', sampleType: 'Blood', reportingTime: '6 hours', isActive: true),
        LabTest(id: 't5', testCode: 'T005', name: 'Vitamin D (25-OH)', description: 'Measures the level of Vitamin D in your blood.', category: 'Vitamins', price: 850.0, templateId: 'temp_vitd', sampleType: 'Blood', reportingTime: '24 hours', isActive: true),
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
        LabTemplate(id: 'temp_cbc', name: 'CBC Template', testName: 'Complete Blood Count (CBC)', category: 'Hematology', type: 'Tabular', reportFormat: 'A4 Portrait', isActive: true, description: 'Complete Blood Count with RBC, WBC, Hemoglobin, Platelets etc.', showPatientDetails: true, showReferrals: true, showLabLogo: true, showRemarksSection: false, defaultRemarks: 'Kindly correlate clinically.', fields: [
          TemplateField(name: 'Hemoglobin', shortCode: 'Hb', unit: 'g/dL', normalRange: '13.0 - 17.0', resultType: 'Numeric', decimals: 1),
          TemplateField(name: 'Total WBC Count', shortCode: 'WBC', unit: '10^3/uL', normalRange: '4.0 - 11.0', resultType: 'Numeric', decimals: 1),
          TemplateField(name: 'RBC Count', shortCode: 'RBC', unit: '10^6/uL', normalRange: '4.5 - 5.9', resultType: 'Numeric', decimals: 2),
          TemplateField(name: 'Platelet Count', shortCode: 'PLT', unit: '10^3/uL', normalRange: '150 - 450', resultType: 'Numeric', decimals: 0),
        ]),
        LabTemplate(id: 'temp_lipid', name: 'Lipid Profile Template', testName: 'Lipid Profile', category: 'Biochemistry', type: 'Tabular', reportFormat: 'A4 Portrait', isActive: true, description: '', showPatientDetails: true, showReferrals: true, showLabLogo: true, showRemarksSection: false, defaultRemarks: '', fields: [
          TemplateField(name: 'Total Cholesterol', shortCode: 'TC', unit: 'mg/dL', normalRange: '< 200', resultType: 'Numeric', decimals: 1),
          TemplateField(name: 'HDL Cholesterol', shortCode: 'HDL', unit: 'mg/dL', normalRange: '> 40', resultType: 'Numeric', decimals: 1),
          TemplateField(name: 'LDL Cholesterol', shortCode: 'LDL', unit: 'mg/dL', normalRange: '< 100', resultType: 'Numeric', decimals: 1),
          TemplateField(name: 'Triglycerides', shortCode: 'TG', unit: 'mg/dL', normalRange: '< 150', resultType: 'Numeric', decimals: 1),
        ]),
        LabTemplate(id: 'temp_thyroid', name: 'Thyroid Profile Template', category: 'Hormones', type: 'Tabular', isActive: true, fields: [
          TemplateField(name: 'T3', unit: 'ng/dL', normalRange: '80 - 200'),
          TemplateField(name: 'T4', unit: 'ug/dL', normalRange: '5.1 - 14.1'),
          TemplateField(name: 'TSH', unit: 'uIU/mL', normalRange: '0.27 - 4.2'),
        ]),
        LabTemplate(id: 'temp_serology', name: 'Serology Template', category: 'Serology', type: 'Tabular', isActive: false, fields: [
          TemplateField(name: 'Widal Test', unit: 'Titer', normalRange: '< 1:80'),
          TemplateField(name: 'CRP', unit: 'mg/L', normalRange: '< 6.0'),
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
        LabPackage(id: 'pkg1', name: 'Full Body Checkup', category: 'Wellness', description: 'A complete health checkup package to assess your overall health and wellness.', testIds: List.generate(32, (i) => 't$i'), discountedPrice: 2500.0, isActive: true),
        LabPackage(id: 'pkg2', name: 'Health Checkup Basic', category: 'Wellness', description: 'Basic tests for general wellness.', testIds: List.generate(18, (i) => 't$i'), discountedPrice: 1499.0, isActive: true),
        LabPackage(id: 'pkg3', name: 'Diabetic Profile', category: 'Diabetes', description: 'Comprehensive screening for diabetes and related complications.', testIds: List.generate(12, (i) => 't$i'), discountedPrice: 999.0, isActive: true),
        LabPackage(id: 'pkg4', name: 'Thyroid Package', category: 'Hormones', description: 'Complete thyroid function test.', testIds: List.generate(5, (i) => 't$i'), discountedPrice: 799.0, isActive: true),
        LabPackage(id: 'pkg5', name: 'Women Wellness', category: 'Wellness', description: 'Specialized health checkup for women.', testIds: List.generate(28, (i) => 't$i'), discountedPrice: 2200.0, isActive: true),
        LabPackage(id: 'pkg6', name: 'Cardiac Risk Profile', category: 'Cardiology', description: 'Assess risk factors for heart diseases.', testIds: List.generate(15, (i) => 't$i'), discountedPrice: 1799.0, isActive: true),
        LabPackage(id: 'pkg7', name: 'Senior Citizen Health', category: 'Wellness', description: 'Extensive screening for seniors.', testIds: List.generate(40, (i) => 't$i'), discountedPrice: 3000.0, isActive: true),
        LabPackage(id: 'pkg8', name: 'Vitamin Profile', category: 'Vitamins', description: 'Check essential vitamin levels.', testIds: List.generate(10, (i) => 't$i'), discountedPrice: 850.0, isActive: false),
        LabPackage(id: 'pkg9', name: 'Kidney Health Package', category: 'Nephrology', description: 'Complete assessment of kidney function.', testIds: List.generate(14, (i) => 't$i'), discountedPrice: 1600.0, isActive: true),
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
          id: 'b1', sampleId: 'S20260909001', patientName: 'Rahul Das', patientPhone: '9876543210', patientAge: '34 Years', patientGender: 'Male',
          bookingDate: DateTime.parse('2026-09-09T09:30:00'), testIds: [], packageIds: [], testsDescription: 'CBC, ESR',
          sampleType: 'Blood', collectedBy: 'Amit', assignedTo: 'Amit', expectedReportDate: DateTime.parse('2026-09-09T18:00:00'),
          totalAmount: 350.0, status: 'Collected',
        ),
        LabBooking(
          id: 'b2', sampleId: 'S20260909002', patientName: 'Priya Sharma', patientPhone: '9830011223', patientAge: '28 Years', patientGender: 'Female',
          bookingDate: DateTime.parse('2026-09-09T09:45:00'), testIds: [], packageIds: [], testsDescription: 'Thyroid Profile',
          sampleType: 'Blood', collectedBy: 'Neha', assignedTo: 'Neha', expectedReportDate: DateTime.parse('2026-09-09T14:00:00'),
          totalAmount: 850.0, status: 'In Processing',
        ),
        LabBooking(
          id: 'b3', sampleId: 'S20260909003', patientName: 'Suman Roy', patientPhone: '9830011223', patientAge: '45 Years', patientGender: 'Male',
          bookingDate: DateTime.parse('2026-09-09T10:10:00'), testIds: [], packageIds: [], testsDescription: 'Full Body Checkup (32 Tests)',
          sampleType: 'Blood', collectedBy: 'Amit', assignedTo: 'Dr. Sen', expectedReportDate: DateTime.parse('2026-09-09T18:00:00'),
          totalAmount: 2500.0, status: 'Ready',
        ),
        LabBooking(
          id: 'b4', sampleId: 'S20260909004', patientName: 'Neha Patel', patientPhone: '9876543210', patientAge: '52 Years', patientGender: 'Female',
          bookingDate: DateTime.parse('2026-09-09T10:25:00'), testIds: [], packageIds: [], testsDescription: 'Lipid Profile',
          sampleType: 'Blood', collectedBy: 'Amit', assignedTo: 'Amit', expectedReportDate: DateTime.parse('2026-09-09T15:00:00'),
          totalAmount: 600.0, status: 'Collected',
        ),
        LabBooking(
          id: 'b5', sampleId: 'S20260909005', patientName: 'Karan Mehta', patientPhone: '9876543210', patientAge: '60 Years', patientGender: 'Male',
          bookingDate: DateTime.parse('2026-09-09T11:00:00'), testIds: [], packageIds: [], testsDescription: 'HbA1c',
          sampleType: 'Blood', collectedBy: 'Neha', assignedTo: 'Neha', expectedReportDate: DateTime.parse('2026-09-09T16:00:00'),
          totalAmount: 400.0, status: 'In Processing',
        ),
        LabBooking(
          id: 'b6', sampleId: 'S20260909006', patientName: 'Anita Singh', patientPhone: '9876543210', patientAge: '30 Years', patientGender: 'Female',
          bookingDate: DateTime.parse('2026-09-09T11:20:00'), testIds: [], packageIds: [], testsDescription: 'Vitamin D',
          sampleType: 'Blood', collectedBy: 'Amit', assignedTo: 'Dr. Sen', expectedReportDate: DateTime.parse('2026-09-09T18:00:00'),
          totalAmount: 1200.0, status: 'Ready',
        ),
        LabBooking(
          id: 'b7', sampleId: 'S20260909007', patientName: 'Deepak Shaw', patientPhone: '9876543210', patientAge: '40 Years', patientGender: 'Male',
          bookingDate: DateTime.parse('2026-09-09T11:45:00'), testIds: [], packageIds: [], testsDescription: 'LFT',
          sampleType: 'Blood', collectedBy: 'System', assignedTo: 'System', expectedReportDate: DateTime.parse('2026-09-09T18:00:00'),
          totalAmount: 700.0, status: 'Delivered',
        ),
        LabBooking(
          id: 'b8', sampleId: 'S20260909008', patientName: 'Pooja Verma', patientPhone: '9876543210', patientAge: '25 Years', patientGender: 'Female',
          bookingDate: DateTime.parse('2026-09-09T12:10:00'), testIds: [], packageIds: [], testsDescription: 'Diabetic Profile',
          sampleType: 'Blood', collectedBy: 'Amit', assignedTo: 'Amit', expectedReportDate: DateTime.parse('2026-09-09T18:00:00'),
          totalAmount: 900.0, status: 'Collected',
        ),
        LabBooking(
          id: 'b9', sampleId: 'S20260909009', patientName: 'Amit Kumar', patientPhone: '9876543210', patientAge: '35 Years', patientGender: 'Male',
          bookingDate: DateTime.parse('2026-09-09T12:30:00'), testIds: [], packageIds: [], testsDescription: 'KFT',
          sampleType: 'Blood', collectedBy: 'Neha', assignedTo: 'Neha', expectedReportDate: DateTime.parse('2026-09-09T18:00:00'),
          totalAmount: 800.0, status: 'In Processing',
        ),
        LabBooking(
          id: 'b10', sampleId: 'S20260909010', patientName: 'Rita Ghosh', patientPhone: '9876543210', patientAge: '42 Years', patientGender: 'Female',
          bookingDate: DateTime.parse('2026-09-09T12:45:00'), testIds: [], packageIds: [], testsDescription: 'Hormone Package',
          sampleType: 'Blood', collectedBy: '-', assignedTo: '-', expectedReportDate: null,
          totalAmount: 1500.0, status: 'Pending',
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
