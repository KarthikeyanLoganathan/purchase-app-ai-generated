// Helper function to safely parse numeric values from maps
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class VendorPriceList {
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
