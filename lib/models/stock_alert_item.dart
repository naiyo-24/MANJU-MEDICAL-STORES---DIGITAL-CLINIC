import '../services/inventory_service.dart';

class StockAlertItem {
  final String id;
  final String name;
  final String sku;
  final String manufacturer;
  final String batchNumber;
  final int stockQuantity;
  final int looseStock;
  final int lowStockThreshold;
  final double unitPrice;
  final double buyingPrice;
  final String? hsnCode;
  final String expiryDate;
  final double? gst;
  final double? discount;
  final int? packSize;
  final String? rackId;
  final String? categoryId;
  final String? distributorId;
  final String? distributorName;
  final String? distributorPhone;

  const StockAlertItem({
    required this.id,
    required this.name,
    this.sku = '',
    required this.manufacturer,
    required this.batchNumber,
    required this.stockQuantity,
    this.looseStock = 0,
    required this.lowStockThreshold,
    this.unitPrice = 0.0,
    this.buyingPrice = 0.0,
    this.hsnCode,
    this.expiryDate = '',
    this.gst = 0.0,
    this.discount = 0.0,
    this.packSize = 1,
    this.rackId,
    this.categoryId,
    this.distributorId,
    this.distributorName,
    this.distributorPhone,
  });

  bool get isOutOfStock => stockQuantity <= 0 && looseStock <= 0;

  factory StockAlertItem.fromInventoryItem(InventoryItem item) {
    return StockAlertItem(
      id: item.id,
      name: item.name,
      sku: item.sku,
      manufacturer: item.manufacturer,
      batchNumber: item.batchNumber,
      stockQuantity: item.stockQuantity,
      looseStock: item.looseStock,
      lowStockThreshold: item.lowStockThreshold ?? 10,
      unitPrice: item.unitPrice,
      buyingPrice: item.buyingPrice,
      hsnCode: item.hsnCode,
      expiryDate: item.expiryDate,
      gst: item.gst,
      discount: item.discount,
      packSize: item.packSize,
      rackId: item.rackId,
      categoryId: item.categoryId,
      distributorId: item.distributorId,
      distributorName: item.distributor,
      distributorPhone: null,
    );
  }

  factory StockAlertItem.fromJson(Map<String, dynamic> json) {
    return StockAlertItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      sku: json['sku']?.toString() ?? '',
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
      unitPrice: json['unit_price'] != null
          ? (json['unit_price'] as num).toDouble()
          : 0.0,
      buyingPrice: json['buying_price'] != null
          ? (json['buying_price'] as num).toDouble()
          : 0.0,
      hsnCode: json['hsn_code']?.toString(),
      expiryDate: json['expiry_date']?.toString() ?? '',
      gst: json['gst'] != null ? (json['gst'] as num).toDouble() : 0.0,
      discount: json['discount'] != null ? (json['discount'] as num).toDouble() : 0.0,
      packSize: json['pack_size'] != null ? int.tryParse(json['pack_size'].toString()) ?? 1 : 1,
      rackId: json['rack_id']?.toString(),
      categoryId: json['category_id']?.toString(),
      distributorId: json['distributor_id']?.toString(),
      distributorName: json['distributor_name']?.toString() ?? json['distributor']?.toString(),
      distributorPhone: json['distributor_phone']?.toString(),
    );
  }
}
