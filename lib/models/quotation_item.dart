import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';

abstract class QuotationItemFields {
  static const uuid = 'uuid';
  static const id = 'id';
  static const quotationUuid = 'quotationUuid';
  static const basketUuid = 'basketUuid';
  static const basketItemUuid = 'basketItemUuid';
  static const vendorPriceListUuid = 'vendorPriceListUuid';
  static const itemAvailableWithVendor = 'itemAvailableWithVendor';
  static const manufacturerMaterialUuid = 'manufacturerMaterialUuid';
  static const materialUuid = 'materialUuid';
  static const model = 'model';
  static const quantity = 'quantity';
  static const maxRetailPrice = 'maxRetailPrice';
  static const rate = 'rate';
  static const rateBeforeTax = 'rateBeforeTax';
  static const basePrice = 'basePrice';
  static const taxPercent = 'taxPercent';
  static const taxAmount = 'taxAmount';
  static const totalAmount = 'totalAmount';
  static const currency = 'currency';
  static const unitOfMeasure = 'unitOfMeasure';
  static const updatedAt = 'updatedAt';
}

abstract class QuotationItemTableFields {
  static const uuid = 'uuid';
  static const id = 'id';
  static const quotationUuid = 'quotation_uuid';
  static const basketUuid = 'basket_uuid';
  static const basketItemUuid = 'basket_item_uuid';
  static const vendorPriceListUuid = 'vendor_price_list_uuid';
  static const itemAvailableWithVendor = 'item_available_with_vendor';
  static const manufacturerMaterialUuid = 'manufacturer_material_uuid';
  static const materialUuid = 'material_uuid';
  static const model = 'model';
  static const quantity = 'quantity';
  static const maxRetailPrice = 'max_retail_price';
  static const rate = 'rate';
  static const rateBeforeTax = 'rate_before_tax';
  static const basePrice = 'base_price';
  static const taxPercent = 'tax_percent';
  static const taxAmount = 'tax_amount';
  static const totalAmount = 'total_amount';
  static const currency = 'currency';
  static const unitOfMeasure = 'unit_of_measure';
  static const updatedAt = 'updated_at';
}

class QuotationItem {
  final String uuid;
  final int? id;
  final String quotationUuid;
  final String basketUuid;
  final String basketItemUuid;
  final String? vendorPriceListUuid;
  final bool itemAvailableWithVendor;
  final String? manufacturerMaterialUuid;
  final String? materialUuid;
  final String? model;
  final double quantity;
  final double? maxRetailPrice;
  final double rate;
  final double rateBeforeTax;
  final double basePrice;
  final double taxPercent;
  final double taxAmount;
  final double totalAmount;
  final String currency;
  final String? unitOfMeasure;
  final DateTime updatedAt;

  QuotationItem({
    required this.uuid,
    this.id,
    required this.quotationUuid,
    required this.basketUuid,
    required this.basketItemUuid,
    this.vendorPriceListUuid,
    this.itemAvailableWithVendor = false,
    this.manufacturerMaterialUuid,
    this.materialUuid,
    this.model,
    this.quantity = 1.0,
    this.maxRetailPrice,
    this.rate = 0.0,
    this.rateBeforeTax = 0.0,
    this.basePrice = 0.0,
    this.taxPercent = 0.0,
    this.taxAmount = 0.0,
    this.totalAmount = 0.0,
    this.currency = 'INR',
    this.unitOfMeasure,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      QuotationItemTableFields.uuid: uuid,
      QuotationItemTableFields.id: id,
      QuotationItemTableFields.quotationUuid: quotationUuid,
      QuotationItemTableFields.basketUuid: basketUuid,
      QuotationItemTableFields.basketItemUuid: basketItemUuid,
      QuotationItemTableFields.vendorPriceListUuid: vendorPriceListUuid,
      QuotationItemTableFields.itemAvailableWithVendor: itemAvailableWithVendor,
      QuotationItemTableFields.manufacturerMaterialUuid:
          manufacturerMaterialUuid,
      QuotationItemTableFields.materialUuid: materialUuid,
      QuotationItemTableFields.model: model,
      QuotationItemTableFields.quantity: quantity,
      QuotationItemTableFields.maxRetailPrice: maxRetailPrice,
      QuotationItemTableFields.rate: rate,
      QuotationItemTableFields.rateBeforeTax: rateBeforeTax,
      QuotationItemTableFields.basePrice: basePrice,
      QuotationItemTableFields.taxPercent: taxPercent,
      QuotationItemTableFields.taxAmount: taxAmount,
      QuotationItemTableFields.totalAmount: totalAmount,
      QuotationItemTableFields.currency: currency,
      QuotationItemTableFields.unitOfMeasure: unitOfMeasure,
      QuotationItemTableFields.updatedAt: updatedAt,
    };
  }

  factory QuotationItem.fromMap(Map<String, dynamic> map) {
    return QuotationItem(
      uuid: map[QuotationItemTableFields.uuid],
      id: map[QuotationItemTableFields.id],
      quotationUuid: map[QuotationItemTableFields.quotationUuid],
      basketUuid: map[QuotationItemTableFields.basketUuid],
      basketItemUuid: map[QuotationItemTableFields.basketItemUuid],
      vendorPriceListUuid: map[QuotationItemTableFields.vendorPriceListUuid],
      itemAvailableWithVendor:
          map[QuotationItemTableFields.itemAvailableWithVendor],
      manufacturerMaterialUuid:
          map[QuotationItemTableFields.manufacturerMaterialUuid],
      materialUuid: map[QuotationItemTableFields.materialUuid],
      model: map[QuotationItemTableFields.model],
      quantity: map[QuotationItemTableFields.quantity],
      maxRetailPrice: map[QuotationItemTableFields.maxRetailPrice],
      rate: map[QuotationItemTableFields.rate],
      rateBeforeTax: map[QuotationItemTableFields.rateBeforeTax],
      basePrice: map[QuotationItemTableFields.basePrice],
      taxPercent: map[QuotationItemTableFields.taxPercent],
      taxAmount: map[QuotationItemTableFields.taxAmount],
      totalAmount: map[QuotationItemTableFields.totalAmount],
      currency: map[QuotationItemTableFields.currency],
      unitOfMeasure: map[QuotationItemTableFields.unitOfMeasure],
      updatedAt: map[QuotationItemTableFields.updatedAt],
    );
  }

  QuotationItem copyWith({
    String? uuid,
    int? id,
    String? quotationUuid,
    String? basketUuid,
    String? basketItemUuid,
    String? vendorPriceListUuid,
    bool? itemAvailableWithVendor,
    String? manufacturerMaterialUuid,
    String? materialUuid,
    String? model,
    double? quantity,
    double? maxRetailPrice,
    double? rate,
    double? rateBeforeTax,
    double? basePrice,
    double? taxPercent,
    double? taxAmount,
    double? totalAmount,
    String? currency,
    String? unitOfMeasure,
    DateTime? updatedAt,
  }) {
    return QuotationItem(
      uuid: uuid ?? this.uuid,
      id: id ?? this.id,
      quotationUuid: quotationUuid ?? this.quotationUuid,
      basketUuid: basketUuid ?? this.basketUuid,
      basketItemUuid: basketItemUuid ?? this.basketItemUuid,
      vendorPriceListUuid: vendorPriceListUuid ?? this.vendorPriceListUuid,
      itemAvailableWithVendor:
          itemAvailableWithVendor ?? this.itemAvailableWithVendor,
      manufacturerMaterialUuid:
          manufacturerMaterialUuid ?? this.manufacturerMaterialUuid,
      materialUuid: materialUuid ?? this.materialUuid,
      model: model ?? this.model,
      quantity: quantity ?? this.quantity,
      maxRetailPrice: maxRetailPrice ?? this.maxRetailPrice,
      rate: rate ?? this.rate,
      rateBeforeTax: rateBeforeTax ?? this.rateBeforeTax,
      basePrice: basePrice ?? this.basePrice,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static final _uuidFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.uuid,
      tableFieldName: QuotationItemTableFields.uuid,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _idFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.id,
      tableFieldName: QuotationItemTableFields.id,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: int);

  static final _quotationUuidFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.quotationUuid,
      tableFieldName: QuotationItemTableFields.quotationUuid,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _basketUuidFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.basketUuid,
      tableFieldName: QuotationItemTableFields.basketUuid,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _basketItemUuidFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.basketItemUuid,
      tableFieldName: QuotationItemTableFields.basketItemUuid,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _vendorPriceListUuidFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.vendorPriceListUuid,
      tableFieldName: QuotationItemTableFields.vendorPriceListUuid,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _itemAvailableWithVendorFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.itemAvailableWithVendor,
      tableFieldName: QuotationItemTableFields.itemAvailableWithVendor,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: bool);

  static final _manufacturerMaterialUuidFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.manufacturerMaterialUuid,
      tableFieldName: QuotationItemTableFields.manufacturerMaterialUuid,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _materialUuidFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.materialUuid,
      tableFieldName: QuotationItemTableFields.materialUuid,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _modelFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.model,
      tableFieldName: QuotationItemTableFields.model,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _quantityFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.quantity,
      tableFieldName: QuotationItemTableFields.quantity,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _maxRetailPriceFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.maxRetailPrice,
      tableFieldName: QuotationItemTableFields.maxRetailPrice,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: double);

  static final _rateFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.rate,
      tableFieldName: QuotationItemTableFields.rate,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _rateBeforeTaxFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.rateBeforeTax,
      tableFieldName: QuotationItemTableFields.rateBeforeTax,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _basePriceFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.basePrice,
      tableFieldName: QuotationItemTableFields.basePrice,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _taxPercentFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.taxPercent,
      tableFieldName: QuotationItemTableFields.taxPercent,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _taxAmountFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.taxAmount,
      tableFieldName: QuotationItemTableFields.taxAmount,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _totalAmountFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.totalAmount,
      tableFieldName: QuotationItemTableFields.totalAmount,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _currencyFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.currency,
      tableFieldName: QuotationItemTableFields.currency,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _unitOfMeasureFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.unitOfMeasure,
      tableFieldName: QuotationItemTableFields.unitOfMeasure,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: QuotationItemFields.updatedAt,
      tableFieldName: QuotationItemTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'QuotationItem',
      databaseTableName: TableNames.quotationItems,
      type: ModelTypes.transactionData,
      displayName: 'Quotation Item',
      tableIndex: 322,
      fromMap: QuotationItem.fromMap,
      toMap: (dynamic instance) => (instance as QuotationItem).toMap(),
      fields: {
        QuotationItemFields.uuid: _uuidFieldDef,
        QuotationItemFields.id: _idFieldDef,
        QuotationItemFields.quotationUuid: _quotationUuidFieldDef,
        QuotationItemFields.basketUuid: _basketUuidFieldDef,
        QuotationItemFields.basketItemUuid: _basketItemUuidFieldDef,
        QuotationItemFields.vendorPriceListUuid: _vendorPriceListUuidFieldDef,
        QuotationItemFields.itemAvailableWithVendor:
            _itemAvailableWithVendorFieldDef,
        QuotationItemFields.manufacturerMaterialUuid:
            _manufacturerMaterialUuidFieldDef,
        QuotationItemFields.materialUuid: _materialUuidFieldDef,
        QuotationItemFields.model: _modelFieldDef,
        QuotationItemFields.quantity: _quantityFieldDef,
        QuotationItemFields.maxRetailPrice: _maxRetailPriceFieldDef,
        QuotationItemFields.rate: _rateFieldDef,
        QuotationItemFields.rateBeforeTax: _rateBeforeTaxFieldDef,
        QuotationItemFields.basePrice: _basePriceFieldDef,
        QuotationItemFields.taxPercent: _taxPercentFieldDef,
        QuotationItemFields.taxAmount: _taxAmountFieldDef,
        QuotationItemFields.totalAmount: _totalAmountFieldDef,
        QuotationItemFields.currency: _currencyFieldDef,
        QuotationItemFields.unitOfMeasure: _unitOfMeasureFieldDef,
        QuotationItemFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory QuotationItem.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as QuotationItem;
  }
}
