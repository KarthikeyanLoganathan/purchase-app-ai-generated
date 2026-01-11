// Helper function to safely parse numeric values from maps
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class VendorPriceList {
  static const Map<String, Type> _fieldTypes = {
    'uuid': String,
    'manufacturerMaterialUuid': String,
    'vendorUuid': String,
    'rate': double,
    'rateBeforeTax': double,
    'currency': String,
    'taxPercent': double,
    'taxAmount': double,
    'updatedAt': DateTime,
  };

  final String uuid;
  final String manufacturerMaterialUuid;
  final String vendorUuid;
  final double rate;
  final double rateBeforeTax;
  final String? currency;
  final double taxPercent;
  final double taxAmount;
  final DateTime updatedAt;

  VendorPriceList({
    required this.uuid,
    required this.manufacturerMaterialUuid,
    required this.vendorUuid,
    required this.rate,
    this.rateBeforeTax = 0.0,
    this.currency,
    required this.taxPercent,
    required this.taxAmount,
    required this.updatedAt,
  });

  static Type? getFieldType(String fieldName) => _fieldTypes[fieldName];

  static const Map<String, String> _entityToDbFields = {
    'uuid': 'uuid',
    'manufacturerMaterialUuid': 'manufacturer_material_uuid',
    'vendorUuid': 'vendor_uuid',
    'rate': 'rate',
    'rateBeforeTax': 'rate_before_tax',
    'currency': 'currency',
    'taxPercent': 'tax_percent',
    'taxAmount': 'tax_amount',
    'updatedAt': 'updated_at',
  };

  static String? getDatabaseFieldName(String entityField) =>
      _entityToDbFields[entityField];

  static const Map<String, String> _dbToEntityFields = {
    'uuid': 'uuid',
    'manufacturer_material_uuid': 'manufacturerMaterialUuid',
    'vendor_uuid': 'vendorUuid',
    'rate': 'rate',
    'rate_before_tax': 'rateBeforeTax',
    'currency': 'currency',
    'tax_percent': 'taxPercent',
    'tax_amount': 'taxAmount',
    'updated_at': 'updatedAt',
  };

  static String? getEntityFieldName(String dbFieldName) =>
      _dbToEntityFields[dbFieldName];

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'manufacturer_material_uuid': manufacturerMaterialUuid,
      'vendor_uuid': vendorUuid,
      'rate': rate,
      'rate_before_tax': rateBeforeTax,
      'currency': currency,
      'tax_percent': taxPercent,
      'tax_amount': taxAmount,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory VendorPriceList.fromMap(Map<String, dynamic> map) {
    return VendorPriceList(
      uuid: map['uuid'] as String,
      manufacturerMaterialUuid: map['manufacturer_material_uuid'] as String,
      vendorUuid: map['vendor_uuid'] as String,
      rate: _toDouble(map['rate']),
      rateBeforeTax: _toDouble(map['rate_before_tax']),
      currency: map['currency'] as String?,
      taxPercent: _toDouble(map['tax_percent']),
      taxAmount: _toDouble(map['tax_amount']),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  VendorPriceList copyWith({
    String? uuid,
    String? manufacturerMaterialUuid,
    String? vendorUuid,
    double? rate,
    double? rateBeforeTax,
    String? currency,
    double? taxPercent,
    double? taxAmount,
    DateTime? updatedAt,
  }) {
    return VendorPriceList(
      uuid: uuid ?? this.uuid,
      manufacturerMaterialUuid:
          manufacturerMaterialUuid ?? this.manufacturerMaterialUuid,
      vendorUuid: vendorUuid ?? this.vendorUuid,
      rate: rate ?? this.rate,
      rateBeforeTax: rateBeforeTax ?? this.rateBeforeTax,
      currency: currency ?? this.currency,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Extended model with joined data for efficient querying
class VendorPriceListWithDetails {
  static const Map<String, Type> _fieldTypes = {
    'vendorPriceList': VendorPriceList,
    'vendorName': String,
    'manufacturerName': String,
    'materialName': String,
    'materialUnitOfMeasure': String,
    'manufacturerMaterialModel': String,
  };

  static const Map<String, String> _entityToDbFields = {
    'vendorPriceList': 'vendor_price_list',
    'vendorName': 'vendor_name',
    'manufacturerName': 'manufacturer_name',
    'materialName': 'material_name',
    'materialUnitOfMeasure': 'material_unit_of_measure',
    'manufacturerMaterialModel': 'manufacturer_material_model',
  };

  static String? getDatabaseFieldName(String entityField) =>
      _entityToDbFields[entityField];

  static const Map<String, String> _dbToEntityFields = {
    'vendor_price_list': 'vendorPriceList',
    'vendor_name': 'vendorName',
    'manufacturer_name': 'manufacturerName',
    'material_name': 'materialName',
    'material_unit_of_measure': 'materialUnitOfMeasure',
    'manufacturer_material_model': 'manufacturerMaterialModel',
  };

  static String? getEntityFieldName(String dbFieldName) =>
      _dbToEntityFields[dbFieldName];

  final VendorPriceList vendorPriceList;
  final String vendorName;
  final String manufacturerName;
  final String materialName;
  final String materialUnitOfMeasure;
  final String manufacturerMaterialModel;

  VendorPriceListWithDetails({
    required this.vendorPriceList,
    required this.vendorName,
    required this.manufacturerName,
    required this.materialName,
    required this.materialUnitOfMeasure,
    required this.manufacturerMaterialModel,
  });

  static Type? getFieldType(String fieldName) => _fieldTypes[fieldName];

  factory VendorPriceListWithDetails.fromMap(Map<String, dynamic> map) {
    return VendorPriceListWithDetails(
      vendorPriceList: VendorPriceList(
        uuid: map['uuid'] as String,
        manufacturerMaterialUuid: map['manufacturer_material_uuid'] as String,
        vendorUuid: map['vendor_uuid'] as String,
        rate: _toDouble(map['rate']),
        rateBeforeTax: _toDouble(map['rate_before_tax']),
        currency: map['currency'] as String?,
        taxPercent: _toDouble(map['tax_percent']),
        taxAmount: _toDouble(map['tax_amount']),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      ),
      vendorName: map['vendor_name'] as String,
      manufacturerName: map['manufacturer_name'] as String,
      materialName: map['material_name'] as String,
      materialUnitOfMeasure: map['material_unit_of_measure'] as String,
      manufacturerMaterialModel: map['manufacturer_material_model'] as String,
    );
  }
}
