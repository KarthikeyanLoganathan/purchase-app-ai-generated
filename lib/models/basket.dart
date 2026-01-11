class Basket {
  static const Map<String, Type> _fieldTypes = {
    'uuid': String,
    'id': int,
    'date': String,
    'description': String,
    'expectedDeliveryDate': String,
    'totalPrice': double,
    'currency': String,
    'numberOfItems': int,
    'projectUuid': String,
    'deliveryAddress': String,
    'phoneNumber': String,
    'updatedAt': String,
  };

  final String uuid;
  final int? id;
  final String date;
  final String? description;
  final String? expectedDeliveryDate;
  final double totalPrice;
  final String currency;
  final int numberOfItems;
  final String? projectUuid;
  final String? deliveryAddress;
  final String? phoneNumber;
  final String updatedAt;

  Basket({
    required this.uuid,
    this.id,
    required this.date,
    this.description,
    this.expectedDeliveryDate,
    this.totalPrice = 0.0,
    this.currency = 'INR',
    this.numberOfItems = 0,
    this.projectUuid,
    this.deliveryAddress,
    this.phoneNumber,
    required this.updatedAt,
  });

  static Type? getFieldType(String fieldName) => _fieldTypes[fieldName];

  static const Map<String, String> _entityToDbFields = {
    'uuid': 'uuid',
    'id': 'id',
    'date': 'date',
    'description': 'description',
    'expectedDeliveryDate': 'expected_delivery_date',
    'totalPrice': 'total_price',
    'currency': 'currency',
    'numberOfItems': 'number_of_items',
    'projectUuid': 'project_uuid',
    'deliveryAddress': 'delivery_address',
    'phoneNumber': 'phone_number',
    'updatedAt': 'updated_at',
  };

  static String? getDatabaseFieldName(String entityField) =>
      _entityToDbFields[entityField];

  static const Map<String, String> _dbToEntityFields = {
    'uuid': 'uuid',
    'id': 'id',
    'date': 'date',
    'description': 'description',
    'expected_delivery_date': 'expectedDeliveryDate',
    'total_price': 'totalPrice',
    'currency': 'currency',
    'number_of_items': 'numberOfItems',
    'project_uuid': 'projectUuid',
    'delivery_address': 'deliveryAddress',
    'phone_number': 'phoneNumber',
    'updated_at': 'updatedAt',
  };

  static String? getEntityFieldName(String dbFieldName) =>
      _dbToEntityFields[dbFieldName];

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'id': id,
      'date': date,
      'description': description,
      'expected_delivery_date': expectedDeliveryDate,
      'total_price': totalPrice,
      'currency': currency,
      'number_of_items': numberOfItems,
      'project_uuid': projectUuid,
      'delivery_address': deliveryAddress,
      'phone_number': phoneNumber,
      'updated_at': updatedAt,
    };
  }

  factory Basket.fromMap(Map<String, dynamic> map) {
    return Basket(
      uuid: map['uuid'],
      id: map['id'],
      date: map['date'],
      description: map['description'],
      expectedDeliveryDate: map['expected_delivery_date'],
      totalPrice: (map['total_price'] is String)
          ? double.tryParse(map['total_price']) ?? 0.0
          : (map['total_price'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'INR',
      numberOfItems: (map['number_of_items'] is String)
          ? int.tryParse(map['number_of_items']) ?? 0
          : (map['number_of_items'] ?? 0).toInt(),
      projectUuid: map['project_uuid'],
      deliveryAddress: map['delivery_address'],
      phoneNumber: map['phone_number'],
      updatedAt: map['updated_at'],
    );
  }

  Basket copyWith({
    String? uuid,
    int? id,
    String? date,
    String? description,
    String? expectedDeliveryDate,
    double? totalPrice,
    String? currency,
    int? numberOfItems,
    String? projectUuid,
    String? deliveryAddress,
    String? phoneNumber,
    String? updatedAt,
  }) {
    return Basket(
      uuid: uuid ?? this.uuid,
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      totalPrice: totalPrice ?? this.totalPrice,
      currency: currency ?? this.currency,
      numberOfItems: numberOfItems ?? this.numberOfItems,
      projectUuid: projectUuid ?? this.projectUuid,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
