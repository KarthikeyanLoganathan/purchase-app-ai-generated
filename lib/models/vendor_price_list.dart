import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';
import '../utils/data_type_utils.dart';

abstract class VendorPriceListFields {
  static const uuid = 'uuid';
  static const manufacturerMaterialUuid = 'manufacturerMaterialUuid';
  static const vendorUuid = 'vendorUuid';
  static const rate = 'rate';
  static const rateBeforeTax = 'rateBeforeTax';
  static const currency = 'currency';
  static const taxPercent = 'taxPercent';
  static const taxAmount = 'taxAmount';
  static const updatedAt = 'updatedAt';
}

abstract class VendorPriceListTableFields {
  static const uuid = 'uuid';
  static const manufacturerMaterialUuid = 'manufacturer_material_uuid';
  static const vendorUuid = 'vendor_uuid';
  static const rate = 'rate';
  static const rateBeforeTax = 'rate_before_tax';
  static const currency = 'currency';
  static const taxPercent = 'tax_percent';
  static const taxAmount = 'tax_amount';
  static const updatedAt = 'updated_at';
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
      VendorPriceListTableFields.uuid: uuid,
      VendorPriceListTableFields.manufacturerMaterialUuid:
          manufacturerMaterialUuid,
      VendorPriceListTableFields.vendorUuid: vendorUuid,
      VendorPriceListTableFields.rate: rate,
      VendorPriceListTableFields.rateBeforeTax: rateBeforeTax,
      VendorPriceListTableFields.currency: currency,
      VendorPriceListTableFields.taxPercent: taxPercent,
      VendorPriceListTableFields.taxAmount: taxAmount,
      VendorPriceListTableFields.updatedAt: updatedAt,
    };
  }

  factory VendorPriceList.fromMap(Map<String, dynamic> map) {
    return VendorPriceList(
      uuid: map[VendorPriceListTableFields.uuid],
      manufacturerMaterialUuid:
          map[VendorPriceListTableFields.manufacturerMaterialUuid],
      vendorUuid: map[VendorPriceListTableFields.vendorUuid],
      rate: map[VendorPriceListTableFields.rate],
      rateBeforeTax: map[VendorPriceListTableFields.rateBeforeTax],
      currency: map[VendorPriceListTableFields.currency],
      taxPercent: map[VendorPriceListTableFields.taxPercent],
      taxAmount: map[VendorPriceListTableFields.taxAmount],
      updatedAt: map[VendorPriceListTableFields.updatedAt],
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

  static final _uuidFieldDef = ModelFieldDefinition(
      name: VendorPriceListFields.uuid,
      tableFieldName: VendorPriceListTableFields.uuid,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _manufacturerMaterialUuidFieldDef = ModelFieldDefinition(
      name: VendorPriceListFields.manufacturerMaterialUuid,
      tableFieldName: VendorPriceListTableFields.manufacturerMaterialUuid,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _vendorUuidFieldDef = ModelFieldDefinition(
      name: VendorPriceListFields.vendorUuid,
      tableFieldName: VendorPriceListTableFields.vendorUuid,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _rateFieldDef = ModelFieldDefinition(
      name: VendorPriceListFields.rate,
      tableFieldName: VendorPriceListTableFields.rate,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _rateBeforeTaxFieldDef = ModelFieldDefinition(
      name: VendorPriceListFields.rateBeforeTax,
      tableFieldName: VendorPriceListTableFields.rateBeforeTax,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _currencyFieldDef = ModelFieldDefinition(
      name: VendorPriceListFields.currency,
      tableFieldName: VendorPriceListTableFields.currency,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _taxPercentFieldDef = ModelFieldDefinition(
      name: VendorPriceListFields.taxPercent,
      tableFieldName: VendorPriceListTableFields.taxPercent,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _taxAmountFieldDef = ModelFieldDefinition(
      name: VendorPriceListFields.taxAmount,
      tableFieldName: VendorPriceListTableFields.taxAmount,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: VendorPriceListFields.updatedAt,
      tableFieldName: VendorPriceListTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'VendorPriceList',
      databaseTableName: TableNames.vendorPriceLists,
      type: ModelTypes.masterData,
      displayName: 'Vendor Price List',
      tableIndex: 205,
      fromMap: VendorPriceList.fromMap,
      toMap: (dynamic instance) => (instance as VendorPriceList).toMap(),
      fields: {
        VendorPriceListFields.uuid: _uuidFieldDef,
        VendorPriceListFields.manufacturerMaterialUuid:
            _manufacturerMaterialUuidFieldDef,
        VendorPriceListFields.vendorUuid: _vendorUuidFieldDef,
        VendorPriceListFields.rate: _rateFieldDef,
        VendorPriceListFields.rateBeforeTax: _rateBeforeTaxFieldDef,
        VendorPriceListFields.currency: _currencyFieldDef,
        VendorPriceListFields.taxPercent: _taxPercentFieldDef,
        VendorPriceListFields.taxAmount: _taxAmountFieldDef,
        VendorPriceListFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory VendorPriceList.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as VendorPriceList;
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

  factory VendorPriceListWithDetails.fromDbMap(Map<String, dynamic> map) {
    return VendorPriceListWithDetails(
      vendorPriceList: VendorPriceList.fromDbMap(map),
      vendorName: DataTypeUtils.dbDeserializers[String]!(map['vendor_name']),
      manufacturerName:
          DataTypeUtils.dbDeserializers[String]!(map['manufacturer_name']),
      materialName:
          DataTypeUtils.dbDeserializers[String]!(map['material_name']),
      materialUnitOfMeasure: DataTypeUtils
          .dbDeserializers[String]!(map['material_unit_of_measure']),
      manufacturerMaterialModel: DataTypeUtils
          .dbDeserializers[String]!(map['manufacturer_material_model']),
    );
  }
}
