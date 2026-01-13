import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';

abstract class BasketItemFields {
  static const uuid = 'uuid';
  static const basketUuid = 'basketUuid';
  static const id = 'id';
  static const manufacturerMaterialUuid = 'manufacturerMaterialUuid';
  static const materialUuid = 'materialUuid';
  static const model = 'model';
  static const manufacturerUuid = 'manufacturerUuid';
  static const quantity = 'quantity';
  static const unitOfMeasure = 'unitOfMeasure';
  static const maxRetailPrice = 'maxRetailPrice';
  static const price = 'price';
  static const currency = 'currency';
  static const updatedAt = 'updatedAt';
}

abstract class BasketItemTableFields {
  static const uuid = 'uuid';
  static const basketUuid = 'basket_uuid';
  static const id = 'id';
  static const manufacturerMaterialUuid = 'manufacturer_material_uuid';
  static const materialUuid = 'material_uuid';
  static const model = 'model';
  static const manufacturerUuid = 'manufacturer_uuid';
  static const quantity = 'quantity';
  static const unitOfMeasure = 'unit_of_measure';
  static const maxRetailPrice = 'max_retail_price';
  static const price = 'price';
  static const currency = 'currency';
  static const updatedAt = 'updated_at';
}

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
  final DateTime updatedAt;

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
      BasketItemTableFields.uuid: uuid,
      BasketItemTableFields.basketUuid: basketUuid,
      BasketItemTableFields.id: id,
      BasketItemTableFields.manufacturerMaterialUuid: manufacturerMaterialUuid,
      BasketItemTableFields.materialUuid: materialUuid,
      BasketItemTableFields.model: model,
      BasketItemTableFields.manufacturerUuid: manufacturerUuid,
      BasketItemTableFields.quantity: quantity,
      BasketItemTableFields.unitOfMeasure: unitOfMeasure,
      BasketItemTableFields.maxRetailPrice: maxRetailPrice,
      BasketItemTableFields.price: price,
      BasketItemTableFields.currency: currency,
      BasketItemTableFields.updatedAt: updatedAt,
    };
  }

  factory BasketItem.fromMap(Map<String, dynamic> map) {
    return BasketItem(
      uuid: map[BasketItemTableFields.uuid],
      basketUuid: map[BasketItemTableFields.basketUuid],
      id: map[BasketItemTableFields.id],
      manufacturerMaterialUuid:
          map[BasketItemTableFields.manufacturerMaterialUuid],
      materialUuid: map[BasketItemTableFields.materialUuid],
      model: map[BasketItemTableFields.model],
      manufacturerUuid: map[BasketItemTableFields.manufacturerUuid],
      quantity: map[BasketItemTableFields.quantity],
      unitOfMeasure: map[BasketItemTableFields.unitOfMeasure],
      maxRetailPrice: map[BasketItemTableFields.maxRetailPrice],
      price: map[BasketItemTableFields.price],
      currency: map[BasketItemTableFields.currency],
      updatedAt: map[BasketItemTableFields.updatedAt],
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
    DateTime? updatedAt,
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

  static final _uuidFieldDef = ModelFieldDefinition(
      name: BasketItemFields.uuid,
      tableFieldName: BasketItemTableFields.uuid,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _basketUuidFieldDef = ModelFieldDefinition(
      name: BasketItemFields.basketUuid,
      tableFieldName: BasketItemTableFields.basketUuid,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _idFieldDef = ModelFieldDefinition(
      name: BasketItemFields.id,
      tableFieldName: BasketItemTableFields.id,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: int);

  static final _manufacturerMaterialUuidFieldDef = ModelFieldDefinition(
      name: BasketItemFields.manufacturerMaterialUuid,
      tableFieldName: BasketItemTableFields.manufacturerMaterialUuid,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _materialUuidFieldDef = ModelFieldDefinition(
      name: BasketItemFields.materialUuid,
      tableFieldName: BasketItemTableFields.materialUuid,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _modelFieldDef = ModelFieldDefinition(
      name: BasketItemFields.model,
      tableFieldName: BasketItemTableFields.model,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _manufacturerUuidFieldDef = ModelFieldDefinition(
      name: BasketItemFields.manufacturerUuid,
      tableFieldName: BasketItemTableFields.manufacturerUuid,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _quantityFieldDef = ModelFieldDefinition(
      name: BasketItemFields.quantity,
      tableFieldName: BasketItemTableFields.quantity,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _unitOfMeasureFieldDef = ModelFieldDefinition(
      name: BasketItemFields.unitOfMeasure,
      tableFieldName: BasketItemTableFields.unitOfMeasure,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _maxRetailPriceFieldDef = ModelFieldDefinition(
      name: BasketItemFields.maxRetailPrice,
      tableFieldName: BasketItemTableFields.maxRetailPrice,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: double);

  static final _priceFieldDef = ModelFieldDefinition(
      name: BasketItemFields.price,
      tableFieldName: BasketItemTableFields.price,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _currencyFieldDef = ModelFieldDefinition(
      name: BasketItemFields.currency,
      tableFieldName: BasketItemTableFields.currency,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: BasketItemFields.updatedAt,
      tableFieldName: BasketItemTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'BasketItem',
      databaseTableName: TableNames.basketItems,
      type: ModelTypes.transactionData,
      displayName: 'Basket Item',
      tableIndex: 312,
      fromMap: BasketItem.fromMap,
      toMap: (dynamic instance) => (instance as BasketItem).toMap(),
      fields: {
        BasketItemFields.uuid: _uuidFieldDef,
        BasketItemFields.basketUuid: _basketUuidFieldDef,
        BasketItemFields.id: _idFieldDef,
        BasketItemFields.manufacturerMaterialUuid:
            _manufacturerMaterialUuidFieldDef,
        BasketItemFields.materialUuid: _materialUuidFieldDef,
        BasketItemFields.model: _modelFieldDef,
        BasketItemFields.manufacturerUuid: _manufacturerUuidFieldDef,
        BasketItemFields.quantity: _quantityFieldDef,
        BasketItemFields.unitOfMeasure: _unitOfMeasureFieldDef,
        BasketItemFields.maxRetailPrice: _maxRetailPriceFieldDef,
        BasketItemFields.price: _priceFieldDef,
        BasketItemFields.currency: _currencyFieldDef,
        BasketItemFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory BasketItem.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as BasketItem;
  }
}
