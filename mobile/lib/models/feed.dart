class FeedProduct {
  final int id;
  final String name;
  final String category;
  final String unit;
  final String? supplier;
  final double unitPriceCfa;
  final double currentStock;
  final double minStockThreshold;
  final bool isLowStock;

  FeedProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    this.supplier,
    required this.unitPriceCfa,
    required this.currentStock,
    required this.minStockThreshold,
    this.isLowStock = false,
  });

  FeedProduct copyWith({
    double? currentStock,
    bool? isLowStock,
  }) {
    final nextStock = currentStock ?? this.currentStock;
    return FeedProduct(
      id: id,
      name: name,
      category: category,
      unit: unit,
      supplier: supplier,
      unitPriceCfa: unitPriceCfa,
      currentStock: nextStock,
      minStockThreshold: minStockThreshold,
      isLowStock: isLowStock ?? (nextStock <= minStockThreshold),
    );
  }

  factory FeedProduct.fromJson(Map<String, dynamic> json) {
    return FeedProduct(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      unit: json['unit'] as String? ?? 'kg',
      supplier: json['supplier'] as String?,
      unitPriceCfa: (json['unit_price_cfa'] as num?)?.toDouble() ?? 0.0,
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
      minStockThreshold: (json['min_stock_threshold'] as num?)?.toDouble() ?? 10.0,
      isLowStock: json['is_low_stock'] as bool? ?? false,
    );
  }
}

class InventoryMovement {
  final int id;
  final int feedProductId;
  final String movementType;
  final double quantity;
  final String unit;
  final double totalQuantity;
  final String? reason;
  final DateTime recordedAt;

  InventoryMovement({
    required this.id,
    required this.feedProductId,
    required this.movementType,
    required this.quantity,
    required this.unit,
    this.totalQuantity = 0.0,
    this.reason,
    required this.recordedAt,
  });

  factory InventoryMovement.fromJson(Map<String, dynamic> json) {
    return InventoryMovement(
      id: json['id'] as int,
      feedProductId: json['feed_product_id'] as int,
      movementType: json['movement_type'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'kg',
      reason: json['reason'] as String?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }
}
