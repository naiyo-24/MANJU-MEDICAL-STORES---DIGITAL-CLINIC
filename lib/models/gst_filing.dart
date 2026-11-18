class GstFiling {
  final String id;
  final String shopId;
  final String shopName;
  final String gstNumber;
  final String turnover;
  final String durationMonths;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String fileType;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const GstFiling({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.gstNumber,
    required this.turnover,
    required this.durationMonths,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileType,
    required this.createdAt,
    this.updatedAt,
  });

  factory GstFiling.fromJson(Map<String, dynamic> json) {
    return GstFiling(
      id: json['id']?.toString() ?? '',
      shopId: json['shop_id']?.toString() ?? '',
      shopName: json['shop_name']?.toString() ?? '',
      gstNumber: json['gst_number']?.toString() ?? '',
      turnover: json['turnover']?.toString() ?? '',
      durationMonths: json['duration_months']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      filePath: json['file_path']?.toString() ?? '',
      fileSize: (json['file_size'] is num) ? (json['file_size'] as num).toInt() : 0,
      fileType: json['file_type']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'shop_name': shopName,
      'gst_number': gstNumber,
      'turnover': turnover,
      'duration_months': durationMonths,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'file_type': fileType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get formattedFileSize {
    if (fileSize <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = fileSize.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
