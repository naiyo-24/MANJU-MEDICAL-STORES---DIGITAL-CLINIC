class LabTest {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String templateId;

  LabTest({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.templateId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'price': price,
    'templateId': templateId,
  };

  factory LabTest.fromJson(Map<String, dynamic> json) => LabTest(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    category: json['category'],
    price: json['price'].toDouble(),
    templateId: json['templateId'],
  );
}

class TemplateField {
  final String name;
  final String unit;
  final String normalRange;

  TemplateField({
    required this.name,
    required this.unit,
    required this.normalRange,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'unit': unit,
    'normalRange': normalRange,
  };

  factory TemplateField.fromJson(Map<String, dynamic> json) => TemplateField(
    name: json['name'],
    unit: json['unit'],
    normalRange: json['normalRange'],
  );
}

class LabTemplate {
  final String id;
  final String name;
  final List<TemplateField> fields;

  LabTemplate({
    required this.id,
    required this.name,
    required this.fields,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fields': fields.map((e) => e.toJson()).toList(),
  };

  factory LabTemplate.fromJson(Map<String, dynamic> json) => LabTemplate(
    id: json['id'],
    name: json['name'],
    fields: (json['fields'] as List).map((e) => TemplateField.fromJson(e)).toList(),
  );
}

class LabPackage {
  final String id;
  final String name;
  final String description;
  final List<String> testIds;
  final double discountedPrice;

  LabPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.testIds,
    required this.discountedPrice,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'testIds': testIds,
    'discountedPrice': discountedPrice,
  };

  factory LabPackage.fromJson(Map<String, dynamic> json) => LabPackage(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    testIds: List<String>.from(json['testIds']),
    discountedPrice: json['discountedPrice'].toDouble(),
  );
}

class LabBooking {
  final String id;
  final String patientName;
  final String patientPhone;
  final String patientAge;
  final String patientGender;
  final DateTime bookingDate;
  final List<String> testIds; // IDs of LabTest
  final List<String> packageIds; // IDs of LabPackage
  final double totalAmount;
  final String status; // Pending, Sample Collected, Processing, Ready, Delivered

  LabBooking({
    required this.id,
    required this.patientName,
    required this.patientPhone,
    required this.patientAge,
    required this.patientGender,
    required this.bookingDate,
    required this.testIds,
    required this.packageIds,
    required this.totalAmount,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientName': patientName,
    'patientPhone': patientPhone,
    'patientAge': patientAge,
    'patientGender': patientGender,
    'bookingDate': bookingDate.toIso8601String(),
    'testIds': testIds,
    'packageIds': packageIds,
    'totalAmount': totalAmount,
    'status': status,
  };

  factory LabBooking.fromJson(Map<String, dynamic> json) => LabBooking(
    id: json['id'],
    patientName: json['patientName'],
    patientPhone: json['patientPhone'],
    patientAge: json['patientAge'],
    patientGender: json['patientGender'],
    bookingDate: DateTime.parse(json['bookingDate']),
    testIds: List<String>.from(json['testIds']),
    packageIds: List<String>.from(json['packageIds']),
    totalAmount: json['totalAmount'].toDouble(),
    status: json['status'],
  );
}
