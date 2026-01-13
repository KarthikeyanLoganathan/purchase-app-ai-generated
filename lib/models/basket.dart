import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';

abstract class BasketFields {
  static const uuid = 'uuid';
  static const id = 'id';
  static const date = 'date';
  static const description = 'description';
  static const expectedDeliveryDate = 'expectedDeliveryDate';
  static const totalPrice = 'totalPrice';
  static const currency = 'currency';
  static const numberOfItems = 'numberOfItems';
  static const projectUuid = 'projectUuid';
  static const deliveryAddress = 'deliveryAddress';
  static const phoneNumber = 'phoneNumber';
  static const updatedAt = 'updatedAt';
}

abstract class BasketTableFields {
  static const uuid = 'uuid';
  static const id = 'id';
  static const date = 'date';
  static const description = 'description';
  static const expectedDeliveryDate = 'expected_delivery_date';
  static const totalPrice = 'total_price';
  static const currency = 'currency';
  static const numberOfItems = 'number_of_items';
  static const projectUuid = 'project_uuid';
  static const deliveryAddress = 'delivery_address';
  static const phoneNumber = 'phone_number';
  static const updatedAt = 'updated_at';
}

class Basket {
  final String uuid;
  final int? id;
  final DateTime date;
  final String? description;
  final DateTime? expectedDeliveryDate;
  final double totalPrice;
  final String currency;
  final int numberOfItems;
  final String? projectUuid;
  final String? deliveryAddress;
  final String? phoneNumber;
  final DateTime updatedAt;

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

  Map<String, dynamic> toMap() {
    return {
      BasketTableFields.uuid: uuid,
      BasketTableFields.id: id,
      BasketTableFields.date: date,
      BasketTableFields.description: description,
      BasketTableFields.expectedDeliveryDate: expectedDeliveryDate,
      BasketTableFields.totalPrice: totalPrice,
      BasketTableFields.currency: currency,
      BasketTableFields.numberOfItems: numberOfItems,
      BasketTableFields.projectUuid: projectUuid,
      BasketTableFields.deliveryAddress: deliveryAddress,
      BasketTableFields.phoneNumber: phoneNumber,
      BasketTableFields.updatedAt: updatedAt,
    };
  }

  factory Basket.fromMap(Map<String, dynamic> map) {
    return Basket(
      uuid: map[BasketTableFields.uuid],
      id: map[BasketTableFields.id],
      date: map[BasketTableFields.date],
      description: map[BasketTableFields.description],
      expectedDeliveryDate: map[BasketTableFields.expectedDeliveryDate],
      totalPrice: map[BasketTableFields.totalPrice],
      currency: map[BasketTableFields.currency],
      numberOfItems: map[BasketTableFields.numberOfItems],
      projectUuid: map[BasketTableFields.projectUuid],
      deliveryAddress: map[BasketTableFields.deliveryAddress],
      phoneNumber: map[BasketTableFields.phoneNumber],
      updatedAt: map[BasketTableFields.updatedAt],
    );
  }

  Basket copyWith({
    String? uuid,
    int? id,
    DateTime? date,
    String? description,
    DateTime? expectedDeliveryDate,
    double? totalPrice,
    String? currency,
    int? numberOfItems,
    String? projectUuid,
    String? deliveryAddress,
    String? phoneNumber,
    DateTime? updatedAt,
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

  static final _uuidFieldDef = ModelFieldDefinition(
      name: BasketFields.uuid,
      tableFieldName: BasketTableFields.uuid,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _idFieldDef = ModelFieldDefinition(
      name: BasketFields.id,
      tableFieldName: BasketTableFields.id,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: int);

  static final _dateFieldDef = ModelFieldDefinition(
      name: BasketFields.date,
      tableFieldName: BasketTableFields.date,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final _descriptionFieldDef = ModelFieldDefinition(
      name: BasketFields.description,
      tableFieldName: BasketTableFields.description,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _expectedDeliveryDateFieldDef = ModelFieldDefinition(
      name: BasketFields.expectedDeliveryDate,
      tableFieldName: BasketTableFields.expectedDeliveryDate,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: DateTime);

  static final _totalPriceFieldDef = ModelFieldDefinition(
      name: BasketFields.totalPrice,
      tableFieldName: BasketTableFields.totalPrice,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _currencyFieldDef = ModelFieldDefinition(
      name: BasketFields.currency,
      tableFieldName: BasketTableFields.currency,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _numberOfItemsFieldDef = ModelFieldDefinition(
      name: BasketFields.numberOfItems,
      tableFieldName: BasketTableFields.numberOfItems,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: int);

  static final _projectUuidFieldDef = ModelFieldDefinition(
      name: BasketFields.projectUuid,
      tableFieldName: BasketTableFields.projectUuid,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _deliveryAddressFieldDef = ModelFieldDefinition(
      name: BasketFields.deliveryAddress,
      tableFieldName: BasketTableFields.deliveryAddress,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _phoneNumberFieldDef = ModelFieldDefinition(
      name: BasketFields.phoneNumber,
      tableFieldName: BasketTableFields.phoneNumber,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: BasketFields.updatedAt,
      tableFieldName: BasketTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'Basket',
      databaseTableName: TableNames.baskets,
      type: ModelTypes.transactionData,
      displayName: 'Basket',
      tableIndex: 311,
      fromMap: Basket.fromMap,
      toMap: (dynamic instance) => (instance as Basket).toMap(),
      fields: {
        BasketFields.uuid: _uuidFieldDef,
        BasketFields.id: _idFieldDef,
        BasketFields.date: _dateFieldDef,
        BasketFields.description: _descriptionFieldDef,
        BasketFields.expectedDeliveryDate: _expectedDeliveryDateFieldDef,
        BasketFields.totalPrice: _totalPriceFieldDef,
        BasketFields.currency: _currencyFieldDef,
        BasketFields.numberOfItems: _numberOfItemsFieldDef,
        BasketFields.projectUuid: _projectUuidFieldDef,
        BasketFields.deliveryAddress: _deliveryAddressFieldDef,
        BasketFields.phoneNumber: _phoneNumberFieldDef,
        BasketFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory Basket.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as Basket;
  }
}
