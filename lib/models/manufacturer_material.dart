// Helper function to safely parse numeric values from maps
double? _toDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class ManufacturerMaterial {
  static const Map<String, Type> _fieldTypes = {
    'uuid': String,
    'manufacturerUuid': String,
    'materialUuid': String,
    'model': String,
    'sellingLotSize': double,
    'maxRetailPrice': double,
    'currency': String,
    'website': String,
    'partNumber': String,
    'photoUuid': String,
    'updatedAt': DateTime,
  };

  final String uuid;
  final String manufacturerUuid;
  final String materialUuid;
  final String model;
  final double? sellingLotSize;
  final double? maxRetailPrice;
  final String? currency;
  final String? website;
  final String? partNumber;
  final String? photoUuid;
  final DateTime updatedAt;

  ManufacturerMaterial({
    required this.uuid,
    required this.manufacturerUuid,
    required this.materialUuid,
    required this.model,
    this.sellingLotSize,
    this.maxRetailPrice,
    this.currency,
    this.website,
    this.partNumber,
    this.photoUuid,
    required this.updatedAt,
  });

  static Type? getFieldType(String fieldName) => _fieldTypes[fieldName];

  static const Map<String, String> _entityToDbFields = {
    'uuid': 'uuid',
    'manufacturerUuid': 'manufacturer_uuid',
    'materialUuid': 'material_uuid',
    'model': 'model',
    'sellingLotSize': 'selling_lot_size',
    'maxRetailPrice': 'max_retail_price',
    'currency': 'currency',
    'website': 'website',
    'partNumber': 'part_number',
    'photoUuid': 'photo_uuid',
    'updatedAt': 'updated_at',
  };

  static String? getDatabaseFieldName(String entityField) =>
      _entityToDbFields[entityField];

  static const Map<String, String> _dbToEntityFields = {
    'uuid': 'uuid',
    'manufacturer_uuid': 'manufacturerUuid',
    'material_uuid': 'materialUuid',
    'model': 'model',
    'selling_lot_size': 'sellingLotSize',
    'max_retail_price': 'maxRetailPrice',
    'currency': 'currency',
    'website': 'website',
    'part_number': 'partNumber',
    'photo_uuid': 'photoUuid',
    'updated_at': 'updatedAt',
  };

  static String? getEntityFieldName(String dbFieldName) =>
      _dbToEntityFields[dbFieldName];

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'manufacturer_uuid': manufacturerUuid,
      'material_uuid': materialUuid,
      'model': model,
      'selling_lot_size': sellingLotSize,
      'max_retail_price': maxRetailPrice,
      'currency': currency,
      'website': website,
      'part_number': partNumber,
      'photo_uuid': photoUuid,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory ManufacturerMaterial.fromMap(Map<String, dynamic> map) {
    return ManufacturerMaterial(
      uuid: map['uuid'] as String,
      manufacturerUuid: map['manufacturer_uuid'] as String,
      materialUuid: map['material_uuid'] as String,
      model: map['model'] as String,
      sellingLotSize: _toDoubleNullable(map['selling_lot_size']),
      maxRetailPrice: _toDoubleNullable(map['max_retail_price']),
      currency: map['currency'] as String?,
      website: map['website'] as String?,
      partNumber: map['part_number'] as String?,
      photoUuid: map['photo_uuid'] as String?,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  ManufacturerMaterial copyWith({
    String? uuid,
    String? manufacturerUuid,
    String? materialUuid,
    String? model,
    double? sellingLotSize,
    double? maxRetailPrice,
    String? currency,
    String? website,
    String? partNumber,
    String? photoUuid,
    DateTime? updatedAt,
  }) {
    return ManufacturerMaterial(
      uuid: uuid ?? this.uuid,
      manufacturerUuid: manufacturerUuid ?? this.manufacturerUuid,
      materialUuid: materialUuid ?? this.materialUuid,
      model: model ?? this.model,
      sellingLotSize: sellingLotSize ?? this.sellingLotSize,
      maxRetailPrice: maxRetailPrice ?? this.maxRetailPrice,
      currency: currency ?? this.currency,
      website: website ?? this.website,
      partNumber: partNumber ?? this.partNumber,
      photoUuid: photoUuid ?? this.photoUuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManufacturerMaterial && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}

// Extended model with joined data for efficient querying
class ManufacturerMaterialWithDetails {
  static const Map<String, Type> _fieldTypes = {
    'manufacturerMaterial': ManufacturerMaterial,
    'manufacturerName': String,
    'materialName': String,
    'materialUnitOfMeasure': String,
    'vendorRate': double,
    'vendorCurrency': String,
    'vendorTaxPercent': double,
    'vendorRateBeforeTax': double,
  };

  static const Map<String, String> _entityToDbFields = {
    'manufacturerMaterial': 'manufacturer_material',
    'manufacturerName': 'manufacturer_name',
    'materialName': 'material_name',
    'materialUnitOfMeasure': 'material_unit_of_measure',
    'vendorRate': 'vendor_rate',
    'vendorCurrency': 'vendor_currency',
    'vendorTaxPercent': 'vendor_tax_percent',
    'vendorRateBeforeTax': 'vendor_rate_before_tax',
  };

  static String? getDatabaseFieldName(String entityField) =>
      _entityToDbFields[entityField];

  static const Map<String, String> _dbToEntityFields = {
    'manufacturer_material': 'manufacturerMaterial',
    'manufacturer_name': 'manufacturerName',
    'material_name': 'materialName',
    'material_unit_of_measure': 'materialUnitOfMeasure',
    'vendor_rate': 'vendorRate',
    'vendor_currency': 'vendorCurrency',
    'vendor_tax_percent': 'vendorTaxPercent',
    'vendor_rate_before_tax': 'vendorRateBeforeTax',
  };

  static String? getEntityFieldName(String dbFieldName) =>
      _dbToEntityFields[dbFieldName];

  final ManufacturerMaterial manufacturerMaterial;
  final String manufacturerName;
  final String materialName;
  final String materialUnitOfMeasure;
  final double? vendorRate;
  final String? vendorCurrency;
  final double? vendorTaxPercent;
  final double? vendorRateBeforeTax;

  ManufacturerMaterialWithDetails({
    required this.manufacturerMaterial,
    required this.manufacturerName,
    required this.materialName,
    required this.materialUnitOfMeasure,
    this.vendorRate,
    this.vendorCurrency,
    this.vendorTaxPercent,
    this.vendorRateBeforeTax,
  });

  static Type? getFieldType(String fieldName) => _fieldTypes[fieldName];

  factory ManufacturerMaterialWithDetails.fromMap(Map<String, dynamic> map) {
    return ManufacturerMaterialWithDetails(
      manufacturerMaterial: ManufacturerMaterial(
        uuid: map['uuid'] as String,
        manufacturerUuid: map['manufacturer_uuid'] as String,
        materialUuid: map['material_uuid'] as String,
        model: map['model'] as String,
        sellingLotSize: _toDoubleNullable(map['selling_lot_size']),
        maxRetailPrice: _toDoubleNullable(map['max_retail_price']),
        currency: map['currency'] as String?,
        website: map['website'] as String?,
        partNumber: map['part_number'] as String?,
        photoUuid: map['photo_uuid'] as String?,
        updatedAt: DateTime.parse(map['updated_at'] as String),
      ),
      manufacturerName: map['manufacturer_name'] as String,
      materialName: map['material_name'] as String,
      materialUnitOfMeasure: map['material_unit_of_measure'] as String,
      vendorRate: _toDoubleNullable(map['vendor_rate']),
      vendorCurrency: map['vendor_currency'] as String?,
      vendorTaxPercent: _toDoubleNullable(map['vendor_tax_percent']),
      vendorRateBeforeTax: _toDoubleNullable(map['vendor_rate_before_tax']),
    );
  }

  String get displayText => '$materialName - $manufacturerName - $model';
  String get model => manufacturerMaterial.model;
}
