import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';

abstract class PurchaseOrderItemFields {
  static const uuid = 'uuid';
  static const purchaseOrderUuid = 'purchaseOrderUuid';
  static const manufacturerMaterialUuid = 'manufacturerMaterialUuid';
  static const materialUuid = 'materialUuid';
  static const model = 'model';
  static const quantity = 'quantity';
  static const rate = 'rate';
  static const rateBeforeTax = 'rateBeforeTax';
  static const basePrice = 'basePrice';
  static const taxPercent = 'taxPercent';
  static const taxAmount = 'taxAmount';
  static const totalAmount = 'totalAmount';
  static const currency = 'currency';
  static const basketItemUuid = 'basketItemUuid';
  static const quotationItemUuid = 'quotationItemUuid';
  static const unitOfMeasure = 'unitOfMeasure';
  static const updatedAt = 'updatedAt';
}

abstract class PurchaseOrderItemTableFields {
  static const uuid = 'uuid';
  static const purchaseOrderUuid = 'purchase_order_uuid';
  static const manufacturerMaterialUuid = 'manufacturer_material_uuid';
  static const materialUuid = 'material_uuid';
  static const model = 'model';
  static const quantity = 'quantity';
  static const rate = 'rate';
  static const rateBeforeTax = 'rate_before_tax';
  static const basePrice = 'base_price';
  static const taxPercent = 'tax_percent';
  static const taxAmount = 'tax_amount';
  static const totalAmount = 'total_amount';
  static const currency = 'currency';
  static const basketItemUuid = 'basket_item_uuid';
  static const quotationItemUuid = 'quotation_item_uuid';
  static const unitOfMeasure = 'unit_of_measure';
  static const updatedAt = 'updated_at';
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
      PurchaseOrderItemTableFields.uuid: uuid,
      PurchaseOrderItemTableFields.purchaseOrderUuid: purchaseOrderUuid,
      PurchaseOrderItemTableFields.manufacturerMaterialUuid:
          manufacturerMaterialUuid,
      PurchaseOrderItemTableFields.materialUuid: materialUuid,
      PurchaseOrderItemTableFields.model: model,
      PurchaseOrderItemTableFields.quantity: quantity,
      PurchaseOrderItemTableFields.rate: rate,
      PurchaseOrderItemTableFields.rateBeforeTax: rateBeforeTax,
      PurchaseOrderItemTableFields.basePrice: basePrice,
      PurchaseOrderItemTableFields.taxPercent: taxPercent,
      PurchaseOrderItemTableFields.taxAmount: taxAmount,
      PurchaseOrderItemTableFields.totalAmount: totalAmount,
      PurchaseOrderItemTableFields.currency: currency,
      PurchaseOrderItemTableFields.basketItemUuid: basketItemUuid,
      PurchaseOrderItemTableFields.quotationItemUuid: quotationItemUuid,
      PurchaseOrderItemTableFields.unitOfMeasure: unitOfMeasure,
      PurchaseOrderItemTableFields.updatedAt: updatedAt,
    };
  }

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      uuid: map[PurchaseOrderItemTableFields.uuid],
      purchaseOrderUuid: map[PurchaseOrderItemTableFields.purchaseOrderUuid],
      manufacturerMaterialUuid:
          map[PurchaseOrderItemTableFields.manufacturerMaterialUuid],
      materialUuid: map[PurchaseOrderItemTableFields.materialUuid],
      model: map[PurchaseOrderItemTableFields.model],
      quantity: map[PurchaseOrderItemTableFields.quantity],
      rate: map[PurchaseOrderItemTableFields.rate],
      rateBeforeTax: map[PurchaseOrderItemTableFields.rateBeforeTax],
      basePrice: map[PurchaseOrderItemTableFields.basePrice],
      taxPercent: map[PurchaseOrderItemTableFields.taxPercent],
      taxAmount: map[PurchaseOrderItemTableFields.taxAmount],
      totalAmount: map[PurchaseOrderItemTableFields.totalAmount],
      currency: map[PurchaseOrderItemTableFields.currency],
      basketItemUuid: map[PurchaseOrderItemTableFields.basketItemUuid],
      quotationItemUuid: map[PurchaseOrderItemTableFields.quotationItemUuid],
      unitOfMeasure: map[PurchaseOrderItemTableFields.unitOfMeasure],
      updatedAt: map[PurchaseOrderItemTableFields.updatedAt],
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

  static final _uuidFieldDef = ModelFieldDefinition(
      name: PurchaseOrderItemFields.uuid,
      tableFieldName: PurchaseOrderItemTableFields.uuid,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _purchaseOrderUuidFieldDef = ModelFieldDefinition(
      name: PurchaseOrderItemFields.purchaseOrderUuid,
      tableFieldName: PurchaseOrderItemTableFields.purchaseOrderUuid,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _manufacturerMaterialUuidFieldDef = ModelFieldDefinition(
      name: PurchaseOrderItemFields.manufacturerMaterialUuid,
      tableFieldName: PurchaseOrderItemTableFields.manufacturerMaterialUuid,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _materialUuidFieldDef = ModelFieldDefinition(
      name: PurchaseOrderItemFields.materialUuid,
      tableFieldName: PurchaseOrderItemTableFields.materialUuid,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _modelFieldDef = ModelFieldDefinition(
      name: PurchaseOrderItemFields.model,
      tableFieldName: PurchaseOrderItemTableFields.model,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _quantityFieldDef = ModelFieldDefinition(
      name: PurchaseOrderItemFields.quantity,
      tableFieldName: PurchaseOrderItemTableFields.quantity,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _rateFieldDef = ModelFieldDefinition(
      name: PurchaseOrderItemFields.rate,
      tableFieldName: PurchaseOrderItemTableFields.rate,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _rateBeforeTaxFieldDef = ModelFieldDefinition(
      name: PurchaseOrderItemFields.rateBeforeTax,
      tableFieldName: PurchaseOrderItemTableFields.rateBeforeTax,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _basePriceFieldDef = ModelFieldDefinition(
      name: PurchaseOrderItemFields.basePrice,
      tableFieldName: PurchaseOrderItemTableFields.basePrice,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _taxPercentFieldDef = ModelFieldDefinition(
      name: PurchaseOrderItemFields.taxPercent,
      tableFieldName: PurchaseOrderItemTableFields.taxPercent,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _taxAmountFieldDef = ModelFieldDefinition(
      name: PurchaseOrderItemFields.taxAmount,
      tableFieldName: PurchaseOrderItemTableFields.taxAmount,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _totalAmountFieldDef = ModelFieldDefinition(
      name: PurchaseOrderItemFields.totalAmount,
      tableFieldName: PurchaseOrderItemTableFields.totalAmount,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _currencyFieldDef = ModelFieldDefinition(
      name: PurchaseOrderItemFields.currency,
      tableFieldName: PurchaseOrderItemTableFields.currency,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _basketItemUuidFieldDef = ModelFieldDefinition(
      name: PurchaseOrderItemFields.basketItemUuid,
      tableFieldName: PurchaseOrderItemTableFields.basketItemUuid,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _quotationItemUuidFieldDef = ModelFieldDefinition(
      name: PurchaseOrderItemFields.quotationItemUuid,
      tableFieldName: PurchaseOrderItemTableFields.quotationItemUuid,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _unitOfMeasureFieldDef = ModelFieldDefinition(
      name: PurchaseOrderItemFields.unitOfMeasure,
      tableFieldName: PurchaseOrderItemTableFields.unitOfMeasure,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: PurchaseOrderItemFields.updatedAt,
      tableFieldName: PurchaseOrderItemTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'PurchaseOrderItem',
      databaseTableName: TableNames.purchaseOrderItems,
      type: ModelTypes.transactionData,
      displayName: 'Purchase Order Item',
      tableIndex: 302,
      fromMap: PurchaseOrderItem.fromMap,
      toMap: (dynamic instance) => (instance as PurchaseOrderItem).toMap(),
      fields: {
        PurchaseOrderItemFields.uuid: _uuidFieldDef,
        PurchaseOrderItemFields.purchaseOrderUuid: _purchaseOrderUuidFieldDef,
        PurchaseOrderItemFields.manufacturerMaterialUuid:
            _manufacturerMaterialUuidFieldDef,
        PurchaseOrderItemFields.materialUuid: _materialUuidFieldDef,
        PurchaseOrderItemFields.model: _modelFieldDef,
        PurchaseOrderItemFields.quantity: _quantityFieldDef,
        PurchaseOrderItemFields.rate: _rateFieldDef,
        PurchaseOrderItemFields.rateBeforeTax: _rateBeforeTaxFieldDef,
        PurchaseOrderItemFields.basePrice: _basePriceFieldDef,
        PurchaseOrderItemFields.taxPercent: _taxPercentFieldDef,
        PurchaseOrderItemFields.taxAmount: _taxAmountFieldDef,
        PurchaseOrderItemFields.totalAmount: _totalAmountFieldDef,
        PurchaseOrderItemFields.currency: _currencyFieldDef,
        PurchaseOrderItemFields.basketItemUuid: _basketItemUuidFieldDef,
        PurchaseOrderItemFields.quotationItemUuid: _quotationItemUuidFieldDef,
        PurchaseOrderItemFields.unitOfMeasure: _unitOfMeasureFieldDef,
        PurchaseOrderItemFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory PurchaseOrderItem.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as PurchaseOrderItem;
  }
}
