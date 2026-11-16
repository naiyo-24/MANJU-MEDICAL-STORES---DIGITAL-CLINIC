import '../services/inventory_service.dart';

class StockAlertItem {
  final String id;
  final String name;
  final String manufacturer;
  final String batchNumber;
  final int stockQuantity;
  final int looseStock;
  final int lowStockThreshold;
  final String? distributorId;
  final String? distributorName;
  final String? distributorPhone;

  const StockAlertItem({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.batchNumber,
    required this.stockQuantity,
    this.looseStock = 0,
    required this.lowStockThreshold,
    this.distributorId,
    this.distributorName,
    this.distributorPhone,
  });

  bool get isOutOfStock => stockQuantity <= 0 && looseStock <= 0;

  factory StockAlertItem.fromInventoryItem(InventoryItem item) {
    return StockAlertItem(
      id: item.id,
      name: item.name,
      manufacturer: item.manufacturer,
      batchNumber: item.batchNumber,
      stockQuantity: item.stockQuantity,
      looseStock: item.looseStock,
      lowStockThreshold: item.lowStockThreshold ?? 10,
      distributorId: item.distributorId,
      distributorName: item.distributor,
      distributorPhone: null,
    );
  }

  factory StockAlertItem.fromJson(Map<String, dynamic> json) {
    return StockAlertItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      manufacturer: json['manufacturer']?.toString() ?? '',
      batchNumber: json['batch_number']?.toString() ?? '',
      stockQuantity: json['stock_quantity'] != null
          ? int.tryParse(json['stock_quantity'].toString()) ?? 0
          : 0,
      looseStock: json['loose_stock'] != null
          ? int.tryParse(json['loose_stock'].toString()) ?? 0
          : 0,
      lowStockThreshold: json['low_stock_threshold'] != null
          ? int.tryParse(json['low_stock_threshold'].toString()) ?? 10
          : 10,
      distributorId: json['distributor_id']?.toString(),
      distributorName: json['distributor_name']?.toString() ?? json['distributor']?.toString(),
      distributorPhone: json['distributor_phone']?.toString(),
    );
  }
}
