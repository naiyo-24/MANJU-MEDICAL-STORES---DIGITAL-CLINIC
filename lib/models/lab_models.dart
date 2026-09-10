class LabTest {
  final String id;
  final String name;
  final String testCode;
  final String description;
  final String category;
  final double price;
  final String templateId;
  final String sampleType;
  final String reportingTime;
  final bool isActive;

  LabTest({
    required this.id,
    required this.name,
    this.testCode = '',
    required this.description,
    required this.category,
    required this.price,
    required this.templateId,
    this.sampleType = 'Blood',
    this.reportingTime = '24 hours',
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'testCode': testCode,
    'description': description,
    'category': category,
    'price': price,
    'templateId': templateId,
    'sampleType': sampleType,
    'reportingTime': reportingTime,
    'isActive': isActive,
  };

  factory LabTest.fromJson(Map<String, dynamic> json) => LabTest(
    id: json['id'],
    name: json['name'],
    testCode: json['testCode'] ?? '',
    description: json['description'],
    category: json['category'],
    price: json['price'].toDouble(),
    templateId: json['templateId'],
    sampleType: json['sampleType'] ?? 'Blood',
    reportingTime: json['reportingTime'] ?? '24 hours',
    isActive: json['isActive'] ?? true,
  );
}

class TemplateField {
  final String name;
  final String shortCode;
  final String unit;
  final String normalRange;
  final String resultType;
  final int decimals;

  TemplateField({
    required this.name,
    this.shortCode = '',
    required this.unit,
    required this.normalRange,
    this.resultType = 'Numeric',
    this.decimals = 1,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'shortCode': shortCode,
    'unit': unit,
    'normalRange': normalRange,
    'resultType': resultType,
    'decimals': decimals,
  };

  factory TemplateField.fromJson(Map<String, dynamic> json) => TemplateField(
    name: json['name'],
    shortCode: json['shortCode'] ?? '',
    unit: json['unit'],
    normalRange: json['normalRange'],
    resultType: json['resultType'] ?? 'Numeric',
    decimals: json['decimals'] ?? 1,
  );
}

class LabTemplate {
  final String id;
  final String name;
  final String testName;
  final String category;
  final String type;
  final String reportFormat;
  final bool isActive;
  final String description;
  final bool showPatientDetails;
  final bool showReferrals;
  final bool showLabLogo;
  final bool showRemarksSection;
  final String defaultRemarks;
  final List<TemplateField> fields;

  LabTemplate({
    required this.id,
    required this.name,
    this.testName = '',
    this.category = 'General',
    this.type = 'Tabular',
    this.reportFormat = 'A4 Portrait',
    this.isActive = true,
    this.description = '',
    this.showPatientDetails = true,
    this.showReferrals = true,
    this.showLabLogo = true,
    this.showRemarksSection = false,
    this.defaultRemarks = '',
    required this.fields,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'testName': testName,
    'category': category,
    'type': type,
    'reportFormat': reportFormat,
    'isActive': isActive,
    'description': description,
    'showPatientDetails': showPatientDetails,
    'showReferrals': showReferrals,
    'showLabLogo': showLabLogo,
    'showRemarksSection': showRemarksSection,
    'defaultRemarks': defaultRemarks,
    'fields': fields.map((e) => e.toJson()).toList(),
  };

  factory LabTemplate.fromJson(Map<String, dynamic> json) => LabTemplate(
    id: json['id'],
    name: json['name'],
    testName: json['testName'] ?? '',
    category: json['category'] ?? 'General',
    type: json['type'] ?? 'Tabular',
    reportFormat: json['reportFormat'] ?? 'A4 Portrait',
    isActive: json['isActive'] ?? true,
    description: json['description'] ?? '',
    showPatientDetails: json['showPatientDetails'] ?? true,
    showReferrals: json['showReferrals'] ?? true,
    showLabLogo: json['showLabLogo'] ?? true,
    showRemarksSection: json['showRemarksSection'] ?? false,
    defaultRemarks: json['defaultRemarks'] ?? '',
    fields: (json['fields'] as List).map((e) => TemplateField.fromJson(e)).toList(),
  );
}

class LabPackage {
  final String id;
  final String name;
  final String category;
  final String description;
  final List<String> testIds;
  final double discountedPrice;
  final bool isActive;

  LabPackage({
    required this.id,
    required this.name,
    this.category = 'Wellness',
    required this.description,
    required this.testIds,
    required this.discountedPrice,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'description': description,
    'testIds': testIds,
    'discountedPrice': discountedPrice,
    'isActive': isActive,
  };

  factory LabPackage.fromJson(Map<String, dynamic> json) => LabPackage(
    id: json['id'],
    name: json['name'],
    category: json['category'] ?? 'Wellness',
    description: json['description'],
    testIds: List<String>.from(json['testIds']),
    discountedPrice: json['discountedPrice'].toDouble(),
    isActive: json['isActive'] ?? true,
  );
}

class LabBooking {
  final String id;
  final String sampleId;
  final String patientName;
  final String patientPhone;
  final String patientAge;
  final String patientGender;
  final DateTime bookingDate; // Maps to Collection Date
  final List<String> testIds; // IDs of LabTest
  final List<String> packageIds; // IDs of LabPackage
  final String testsDescription;
  final String sampleType;
  final String collectedBy;
  final String assignedTo;
  final DateTime? expectedReportDate;
  final double totalAmount;
  final String status; // Pending, Collected, In Processing, Ready, Delivered

  LabBooking({
    required this.id,
    this.sampleId = '',
    required this.patientName,
    required this.patientPhone,
    required this.patientAge,
    required this.patientGender,
    required this.bookingDate,
    required this.testIds,
    required this.packageIds,
    this.testsDescription = '',
    this.sampleType = 'Blood',
    this.collectedBy = '',
    this.assignedTo = '',
    this.expectedReportDate,
    required this.totalAmount,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sampleId': sampleId,
    'patientName': patientName,
    'patientPhone': patientPhone,
    'patientAge': patientAge,
    'patientGender': patientGender,
    'bookingDate': bookingDate.toIso8601String(),
    'testIds': testIds,
    'packageIds': packageIds,
    'testsDescription': testsDescription,
    'sampleType': sampleType,
    'collectedBy': collectedBy,
    'assignedTo': assignedTo,
    'expectedReportDate': expectedReportDate?.toIso8601String(),
    'totalAmount': totalAmount,
    'status': status,
  };

  factory LabBooking.fromJson(Map<String, dynamic> json) => LabBooking(
    id: json['id'],
    sampleId: json['sampleId'] ?? '',
    patientName: json['patientName'],
    patientPhone: json['patientPhone'],
    patientAge: json['patientAge'],
    patientGender: json['patientGender'],
    bookingDate: DateTime.parse(json['bookingDate']),
    testIds: List<String>.from(json['testIds']),
    packageIds: List<String>.from(json['packageIds']),
    testsDescription: json['testsDescription'] ?? '',
    sampleType: json['sampleType'] ?? 'Blood',
    collectedBy: json['collectedBy'] ?? '',
    assignedTo: json['assignedTo'] ?? '',
    expectedReportDate: json['expectedReportDate'] != null ? DateTime.parse(json['expectedReportDate']) : null,
    totalAmount: json['totalAmount'].toDouble(),
    status: json['status'],
  );
}
