class Manufacturer {
  final String id;
  final String shopId;
  final String name;
  final String? shortCode;
  final int isDeleted;
  final String? createdAt;
  final String? updatedAt;

  Manufacturer({
    required this.id,
    required this.shopId,
    required this.name,
    this.shortCode,
    this.isDeleted = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Manufacturer.fromJson(Map<String, dynamic> json) {
    return Manufacturer(
      id: json['id']?.toString() ?? '',
      shopId: (json['shop_id'] ?? json['shopId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      shortCode: json['short_code']?.toString() ?? json['shortCode']?.toString(),
      isDeleted: json['is_deleted'] is int
          ? json['is_deleted']
          : int.tryParse(json['is_deleted']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      if (shortCode != null) 'short_code': shortCode,
      'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  @override
  String toString() => shortCode != null && shortCode!.isNotEmpty
      ? '$name ($shortCode)'
      : name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Manufacturer &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
