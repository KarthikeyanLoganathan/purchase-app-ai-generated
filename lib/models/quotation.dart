import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';

abstract class QuotationFields {
  static const uuid = 'uuid';
  static const id = 'id';
  static const basketUuid = 'basketUuid';
  static const vendorUuid = 'vendorUuid';
  static const date = 'date';
  static const expectedDeliveryDate = 'expectedDeliveryDate';
  static const basePrice = 'basePrice';
  static const taxAmount = 'taxAmount';
  static const totalAmount = 'totalAmount';
  static const currency = 'currency';
  static const numberOfAvailableItems = 'numberOfAvailableItems';
  static const numberOfUnavailableItems = 'numberOfUnavailableItems';
  static const projectUuid = 'projectUuid';
  static const description = 'description';
  static const updatedAt = 'updatedAt';
}

abstract class QuotationTableFields {
  static const uuid = 'uuid';
  static const id = 'id';
  static const basketUuid = 'basket_uuid';
  static const vendorUuid = 'vendor_uuid';
  static const date = 'date';
  static const expectedDeliveryDate = 'expected_delivery_date';
  static const basePrice = 'base_price';
  static const taxAmount = 'tax_amount';
  static const totalAmount = 'total_amount';
  static const currency = 'currency';
  static const numberOfAvailableItems = 'number_of_available_items';
  static const numberOfUnavailableItems = 'number_of_unavailable_items';
  static const projectUuid = 'project_uuid';
  static const description = 'description';
  static const updatedAt = 'updated_at';
}

class Quotation {
  final String uuid;
  final int? id;
  final String basketUuid;
  final String vendorUuid;
  final DateTime date;
  final DateTime? expectedDeliveryDate;
  final double basePrice;
  final double taxAmount;
  final double totalAmount;
  final String currency;
  final int numberOfAvailableItems;
  final int numberOfUnavailableItems;
  final String? projectUuid;
  final String? description;
  final DateTime updatedAt;

  Quotation({
    required this.uuid,
    this.id,
    required this.basketUuid,
    required this.vendorUuid,
    required this.date,
    this.expectedDeliveryDate,
    this.basePrice = 0.0,
    this.taxAmount = 0.0,
    this.totalAmount = 0.0,
    this.currency = 'INR',
    this.numberOfAvailableItems = 0,
    this.numberOfUnavailableItems = 0,
    this.projectUuid,
    this.description,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      QuotationTableFields.uuid: uuid,
      QuotationTableFields.id: id,
      QuotationTableFields.basketUuid: basketUuid,
      QuotationTableFields.vendorUuid: vendorUuid,
      QuotationTableFields.date: date,
      QuotationTableFields.expectedDeliveryDate: expectedDeliveryDate,
      QuotationTableFields.basePrice: basePrice,
      QuotationTableFields.taxAmount: taxAmount,
      QuotationTableFields.totalAmount: totalAmount,
      QuotationTableFields.currency: currency,
      QuotationTableFields.numberOfAvailableItems: numberOfAvailableItems,
      QuotationTableFields.numberOfUnavailableItems: numberOfUnavailableItems,
      QuotationTableFields.projectUuid: projectUuid,
      QuotationTableFields.description: description,
      QuotationTableFields.updatedAt: updatedAt,
    };
  }

  factory Quotation.fromMap(Map<String, dynamic> map) {
    return Quotation(
      uuid: map[QuotationTableFields.uuid],
      id: map[QuotationTableFields.id],
      basketUuid: map[QuotationTableFields.basketUuid],
      vendorUuid: map[QuotationTableFields.vendorUuid],
      date: map[QuotationTableFields.date],
      expectedDeliveryDate: map[QuotationTableFields.expectedDeliveryDate],
      basePrice: map[QuotationTableFields.basePrice],
      taxAmount: map[QuotationTableFields.taxAmount],
      totalAmount: map[QuotationTableFields.totalAmount],
      currency: map[QuotationTableFields.currency],
      numberOfAvailableItems: map[QuotationTableFields.numberOfAvailableItems],
      numberOfUnavailableItems:
          map[QuotationTableFields.numberOfUnavailableItems],
      projectUuid: map[QuotationTableFields.projectUuid],
      description: map[QuotationTableFields.description],
      updatedAt: map[QuotationTableFields.updatedAt],
    );
  }

  Quotation copyWith({
    String? uuid,
    int? id,
    String? basketUuid,
    String? vendorUuid,
    DateTime? date,
    DateTime? expectedDeliveryDate,
    double? basePrice,
    double? taxAmount,
    double? totalAmount,
    String? currency,
    int? numberOfAvailableItems,
    int? numberOfUnavailableItems,
    String? projectUuid,
    String? description,
    DateTime? updatedAt,
  }) {
    return Quotation(
      uuid: uuid ?? this.uuid,
      id: id ?? this.id,
      basketUuid: basketUuid ?? this.basketUuid,
      vendorUuid: vendorUuid ?? this.vendorUuid,
      date: date ?? this.date,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      basePrice: basePrice ?? this.basePrice,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      numberOfAvailableItems:
          numberOfAvailableItems ?? this.numberOfAvailableItems,
      numberOfUnavailableItems:
          numberOfUnavailableItems ?? this.numberOfUnavailableItems,
      projectUuid: projectUuid ?? this.projectUuid,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static final _uuidFieldDef = ModelFieldDefinition(
      name: QuotationFields.uuid,
      tableFieldName: QuotationTableFields.uuid,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _idFieldDef = ModelFieldDefinition(
      name: QuotationFields.id,
      tableFieldName: QuotationTableFields.id,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: int);

  static final _basketUuidFieldDef = ModelFieldDefinition(
      name: QuotationFields.basketUuid,
      tableFieldName: QuotationTableFields.basketUuid,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _vendorUuidFieldDef = ModelFieldDefinition(
      name: QuotationFields.vendorUuid,
      tableFieldName: QuotationTableFields.vendorUuid,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _dateFieldDef = ModelFieldDefinition(
      name: QuotationFields.date,
      tableFieldName: QuotationTableFields.date,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final _expectedDeliveryDateFieldDef = ModelFieldDefinition(
      name: QuotationFields.expectedDeliveryDate,
      tableFieldName: QuotationTableFields.expectedDeliveryDate,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: DateTime);

  static final _basePriceFieldDef = ModelFieldDefinition(
      name: QuotationFields.basePrice,
      tableFieldName: QuotationTableFields.basePrice,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _taxAmountFieldDef = ModelFieldDefinition(
      name: QuotationFields.taxAmount,
      tableFieldName: QuotationTableFields.taxAmount,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _totalAmountFieldDef = ModelFieldDefinition(
      name: QuotationFields.totalAmount,
      tableFieldName: QuotationTableFields.totalAmount,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _currencyFieldDef = ModelFieldDefinition(
      name: QuotationFields.currency,
      tableFieldName: QuotationTableFields.currency,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _numberOfAvailableItemsFieldDef = ModelFieldDefinition(
      name: QuotationFields.numberOfAvailableItems,
      tableFieldName: QuotationTableFields.numberOfAvailableItems,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: int);

  static final _numberOfUnavailableItemsFieldDef = ModelFieldDefinition(
      name: QuotationFields.numberOfUnavailableItems,
      tableFieldName: QuotationTableFields.numberOfUnavailableItems,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: int);

  static final _projectUuidFieldDef = ModelFieldDefinition(
      name: QuotationFields.projectUuid,
      tableFieldName: QuotationTableFields.projectUuid,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _descriptionFieldDef = ModelFieldDefinition(
      name: QuotationFields.description,
      tableFieldName: QuotationTableFields.description,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: QuotationFields.updatedAt,
      tableFieldName: QuotationTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'Quotation',
      databaseTableName: TableNames.quotations,
      type: ModelTypes.transactionData,
      displayName: 'Quotation',
      tableIndex: 321,
      fromMap: Quotation.fromMap,
      toMap: (dynamic instance) => (instance as Quotation).toMap(),
      fields: {
        QuotationFields.uuid: _uuidFieldDef,
        QuotationFields.id: _idFieldDef,
        QuotationFields.basketUuid: _basketUuidFieldDef,
        QuotationFields.vendorUuid: _vendorUuidFieldDef,
        QuotationFields.date: _dateFieldDef,
        QuotationFields.expectedDeliveryDate: _expectedDeliveryDateFieldDef,
        QuotationFields.basePrice: _basePriceFieldDef,
        QuotationFields.taxAmount: _taxAmountFieldDef,
        QuotationFields.totalAmount: _totalAmountFieldDef,
        QuotationFields.currency: _currencyFieldDef,
        QuotationFields.numberOfAvailableItems: _numberOfAvailableItemsFieldDef,
        QuotationFields.numberOfUnavailableItems:
            _numberOfUnavailableItemsFieldDef,
        QuotationFields.projectUuid: _projectUuidFieldDef,
        QuotationFields.description: _descriptionFieldDef,
        QuotationFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory Quotation.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as Quotation;
  }
}
