class BasketItem {
  final String uuid;
  final String basketUuid;
  final int? id;
  final String manufacturerMaterialUuid;
  final String? materialUuid;
  final String? model;
  final String? manufacturerUuid;
  final double quantity;
  final String? unitOfMeasure;
  final double? maxRetailPrice;
  final double price;
  final String currency;
  final String updatedAt;

  BasketItem({
    required this.uuid,
    required this.basketUuid,
    this.id,
    required this.manufacturerMaterialUuid,
    this.materialUuid,
    this.model,
    this.manufacturerUuid,
    this.quantity = 1.0,
    this.unitOfMeasure,
    this.maxRetailPrice,
    this.price = 0.0,
    this.currency = 'INR',
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'basket_uuid': basketUuid,
      'id': id,
      'manufacturer_material_uuid': manufacturerMaterialUuid,
      'material_uuid': materialUuid,
      'model': model,
      'manufacturer_uuid': manufacturerUuid,
      'quantity': quantity,
      'unit_of_measure': unitOfMeasure,
      'max_retail_price': maxRetailPrice,
      'price': price,
      'currency': currency,
      'updated_at': updatedAt,
    };
  }

  factory BasketItem.fromMap(Map<String, dynamic> map) {
    return BasketItem(
      uuid: map['uuid'],
      basketUuid: map['basket_uuid'],
      id: map['id'],
      manufacturerMaterialUuid: map['manufacturer_material_uuid'],
      materialUuid: map['material_uuid'],
      model: map['model'],
      manufacturerUuid: map['manufacturer_uuid'],
      quantity: map['quantity'] ?? 1.0,
      unitOfMeasure: map['unit_of_measure'],
      maxRetailPrice: map['max_retail_price'],
      price: map['price'] ?? 0.0,
      currency: map['currency'] ?? 'INR',
      updatedAt: map['updated_at'],
    );
  }

  BasketItem copyWith({
    String? uuid,
    String? basketUuid,
    int? id,
    String? manufacturerMaterialUuid,
    String? materialUuid,
    String? model,
    String? manufacturerUuid,
    double? quantity,
    String? unitOfMeasure,
    double? maxRetailPrice,
    double? price,
    String? currency,
    String? updatedAt,
  }) {
    return BasketItem(
      uuid: uuid ?? this.uuid,
      basketUuid: basketUuid ?? this.basketUuid,
      id: id ?? this.id,
      manufacturerMaterialUuid:
          manufacturerMaterialUuid ?? this.manufacturerMaterialUuid,
      materialUuid: materialUuid ?? this.materialUuid,
      model: model ?? this.model,
      manufacturerUuid: manufacturerUuid ?? this.manufacturerUuid,
      quantity: quantity ?? this.quantity,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      maxRetailPrice: maxRetailPrice ?? this.maxRetailPrice,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
