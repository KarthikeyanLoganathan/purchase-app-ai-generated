import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';
import '../utils/data_type_utils.dart';

abstract class ManufacturerMaterialFields {
  static const uuid = 'uuid';
  static const manufacturerUuid = 'manufacturerUuid';
  static const materialUuid = 'materialUuid';
  static const model = 'model';
  static const sellingLotSize = 'sellingLotSize';
  static const maxRetailPrice = 'maxRetailPrice';
  static const currency = 'currency';
  static const website = 'website';
  static const partNumber = 'partNumber';
  static const photoUuid = 'photoUuid';
  static const updatedAt = 'updatedAt';
}

abstract class ManufacturerMaterialTableFields {
  static const uuid = 'uuid';
  static const manufacturerUuid = 'manufacturer_uuid';
  static const materialUuid = 'material_uuid';
  static const model = 'model';
  static const sellingLotSize = 'selling_lot_size';
  static const maxRetailPrice = 'max_retail_price';
  static const currency = 'currency';
  static const website = 'website';
  static const partNumber = 'part_number';
  static const photoUuid = 'photo_uuid';
  static const updatedAt = 'updated_at';
}

class ManufacturerMaterial {
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

  Map<String, dynamic> toMap() {
    return {
      ManufacturerMaterialTableFields.uuid: uuid,
      ManufacturerMaterialTableFields.manufacturerUuid: manufacturerUuid,
      ManufacturerMaterialTableFields.materialUuid: materialUuid,
      ManufacturerMaterialTableFields.model: model,
      ManufacturerMaterialTableFields.sellingLotSize: sellingLotSize,
      ManufacturerMaterialTableFields.maxRetailPrice: maxRetailPrice,
      ManufacturerMaterialTableFields.currency: currency,
      ManufacturerMaterialTableFields.website: website,
      ManufacturerMaterialTableFields.partNumber: partNumber,
      ManufacturerMaterialTableFields.photoUuid: photoUuid,
      ManufacturerMaterialTableFields.updatedAt: updatedAt,
    };
  }

  factory ManufacturerMaterial.fromMap(Map<String, dynamic> map) {
    return ManufacturerMaterial(
      uuid: map[ManufacturerMaterialTableFields.uuid],
      manufacturerUuid: map[ManufacturerMaterialTableFields.manufacturerUuid],
      materialUuid: map[ManufacturerMaterialTableFields.materialUuid],
      model: map[ManufacturerMaterialTableFields.model],
      sellingLotSize: map[ManufacturerMaterialTableFields.sellingLotSize],
      maxRetailPrice: map[ManufacturerMaterialTableFields.maxRetailPrice],
      currency: map[ManufacturerMaterialTableFields.currency],
      website: map[ManufacturerMaterialTableFields.website],
      partNumber: map[ManufacturerMaterialTableFields.partNumber],
      photoUuid: map[ManufacturerMaterialTableFields.photoUuid],
      updatedAt: map[ManufacturerMaterialTableFields.updatedAt],
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

  static final _uuidFieldDef = ModelFieldDefinition(
      name: ManufacturerMaterialFields.uuid,
      tableFieldName: ManufacturerMaterialTableFields.uuid,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _manufacturerUuidFieldDef = ModelFieldDefinition(
      name: ManufacturerMaterialFields.manufacturerUuid,
      tableFieldName: ManufacturerMaterialTableFields.manufacturerUuid,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _materialUuidFieldDef = ModelFieldDefinition(
      name: ManufacturerMaterialFields.materialUuid,
      tableFieldName: ManufacturerMaterialTableFields.materialUuid,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _modelFieldDef = ModelFieldDefinition(
      name: ManufacturerMaterialFields.model,
      tableFieldName: ManufacturerMaterialTableFields.model,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _sellingLotSizeFieldDef = ModelFieldDefinition(
      name: ManufacturerMaterialFields.sellingLotSize,
      tableFieldName: ManufacturerMaterialTableFields.sellingLotSize,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: double);

  static final _maxRetailPriceFieldDef = ModelFieldDefinition(
      name: ManufacturerMaterialFields.maxRetailPrice,
      tableFieldName: ManufacturerMaterialTableFields.maxRetailPrice,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: double);

  static final _currencyFieldDef = ModelFieldDefinition(
      name: ManufacturerMaterialFields.currency,
      tableFieldName: ManufacturerMaterialTableFields.currency,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _websiteFieldDef = ModelFieldDefinition(
      name: ManufacturerMaterialFields.website,
      tableFieldName: ManufacturerMaterialTableFields.website,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _partNumberFieldDef = ModelFieldDefinition(
      name: ManufacturerMaterialFields.partNumber,
      tableFieldName: ManufacturerMaterialTableFields.partNumber,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _photoUuidFieldDef = ModelFieldDefinition(
      name: ManufacturerMaterialFields.photoUuid,
      tableFieldName: ManufacturerMaterialTableFields.photoUuid,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: ManufacturerMaterialFields.updatedAt,
      tableFieldName: ManufacturerMaterialTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'ManufacturerMaterial',
      databaseTableName: TableNames.manufacturerMaterials,
      type: ModelTypes.masterData,
      displayName: 'Manufacturer Material',
      tableIndex: 204,
      fromMap: ManufacturerMaterial.fromMap,
      toMap: (dynamic instance) => (instance as ManufacturerMaterial).toMap(),
      fields: {
        ManufacturerMaterialFields.uuid: _uuidFieldDef,
        ManufacturerMaterialFields.manufacturerUuid: _manufacturerUuidFieldDef,
        ManufacturerMaterialFields.materialUuid: _materialUuidFieldDef,
        ManufacturerMaterialFields.model: _modelFieldDef,
        ManufacturerMaterialFields.sellingLotSize: _sellingLotSizeFieldDef,
        ManufacturerMaterialFields.maxRetailPrice: _maxRetailPriceFieldDef,
        ManufacturerMaterialFields.currency: _currencyFieldDef,
        ManufacturerMaterialFields.website: _websiteFieldDef,
        ManufacturerMaterialFields.partNumber: _partNumberFieldDef,
        ManufacturerMaterialFields.photoUuid: _photoUuidFieldDef,
        ManufacturerMaterialFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory ManufacturerMaterial.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as ManufacturerMaterial;
  }
}

// Extended model with joined data for efficient querying
class ManufacturerMaterialWithDetails {
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

  factory ManufacturerMaterialWithDetails.fromDbMap(Map<String, dynamic> map) {
    return ManufacturerMaterialWithDetails(
      manufacturerMaterial: ManufacturerMaterial.fromDbMap(map),
      manufacturerName:
          DataTypeUtils.dbDeserializers[String]!(map['manufacturer_name']),
      materialName:
          DataTypeUtils.dbDeserializers[String]!(map['material_name']),
      materialUnitOfMeasure: DataTypeUtils
          .dbDeserializers[String]!(map['material_unit_of_measure']),
      vendorRate: DataTypeUtils.dbDeserializers[double]!(map['vendor_rate']),
      vendorCurrency:
          DataTypeUtils.dbDeserializers[String]!(map['vendor_currency']),
      vendorTaxPercent:
          DataTypeUtils.dbDeserializers[double]!(map['vendor_tax_percent']),
      vendorRateBeforeTax:
          DataTypeUtils.dbDeserializers[double]!(map['vendor_rate_before_tax']),
    );
  }

  String get displayText => '$materialName - $manufacturerName - $model';
  String get model => manufacturerMaterial.model;
}
