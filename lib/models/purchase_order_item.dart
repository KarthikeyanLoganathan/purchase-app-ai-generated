// Helper function to safely parse numeric values from maps
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class PurchaseOrderItem {
  final String uuid;
  final String purchaseOrderUuid;
  final String manufacturerMaterialUuid;
  final String materialUuid;
  final String model;
  final double quantity;
  final double rate;
  final double rateBeforeTax;
  final double basePrice;
  final double taxPercent;
  final double taxAmount;
  final double totalAmount;
  final String? currency;
  final String? basketItemUuid;
  final String? quotationItemUuid;
  final String? unitOfMeasure;
  final DateTime updatedAt;

  PurchaseOrderItem({
    required this.uuid,
    required this.purchaseOrderUuid,
    required this.manufacturerMaterialUuid,
    required this.materialUuid,
    required this.model,
    required this.quantity,
    required this.rate,
    this.rateBeforeTax = 0.0,
    required this.basePrice,
    required this.taxPercent,
    required this.taxAmount,
    required this.totalAmount,
    this.currency,
    this.basketItemUuid,
    this.quotationItemUuid,
    this.unitOfMeasure,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'purchase_order_uuid': purchaseOrderUuid,
      'manufacturer_material_uuid': manufacturerMaterialUuid,
      'material_uuid': materialUuid,
      'model': model,
      'quantity': quantity,
      'rate': rate,
      'rate_before_tax': rateBeforeTax,
      'base_price': basePrice,
      'tax_percent': taxPercent,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'currency': currency,
      'basket_item_uuid': basketItemUuid,
      'quotation_item_uuid': quotationItemUuid,
      'unit_of_measure': unitOfMeasure,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      uuid: map['uuid'] as String,
      purchaseOrderUuid: map['purchase_order_uuid'] as String,
      manufacturerMaterialUuid: map['manufacturer_material_uuid'] as String,
      materialUuid: map['material_uuid'] as String? ?? '',
      model: map['model'] as String? ?? '',
      quantity: _toDouble(map['quantity']),
      rate: _toDouble(map['rate']),
      rateBeforeTax: _toDouble(map['rate_before_tax']),
      basePrice: _toDouble(map['base_price']),
      taxPercent: _toDouble(map['tax_percent']),
      taxAmount: _toDouble(map['tax_amount']),
      totalAmount: _toDouble(map['total_amount']),
      currency: map['currency'] as String?,
      basketItemUuid: map['basket_item_uuid'] as String?,
      quotationItemUuid: map['quotation_item_uuid'] as String?,
      unitOfMeasure: map['unit_of_measure'] as String?,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  PurchaseOrderItem copyWith({
    String? uuid,
    String? purchaseOrderUuid,
    String? manufacturerMaterialUuid,
    String? materialUuid,
    String? model,
    double? quantity,
    double? rate,
    double? rateBeforeTax,
    double? basePrice,
    double? taxPercent,
    double? taxAmount,
    double? totalAmount,
    String? currency,
    String? basketItemUuid,
    String? quotationItemUuid,
    String? unitOfMeasure,
    DateTime? updatedAt,
  }) {
    return PurchaseOrderItem(
      uuid: uuid ?? this.uuid,
      purchaseOrderUuid: purchaseOrderUuid ?? this.purchaseOrderUuid,
      manufacturerMaterialUuid:
          manufacturerMaterialUuid ?? this.manufacturerMaterialUuid,
      materialUuid: materialUuid ?? this.materialUuid,
      model: model ?? this.model,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      rateBeforeTax: rateBeforeTax ?? this.rateBeforeTax,
      basePrice: basePrice ?? this.basePrice,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      basketItemUuid: basketItemUuid ?? this.basketItemUuid,
      quotationItemUuid: quotationItemUuid ?? this.quotationItemUuid,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
