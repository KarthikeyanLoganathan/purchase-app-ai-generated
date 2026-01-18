import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';

abstract class PurchaseOrderFields {
  static const uuid = 'uuid';
  static const id = 'id';
  static const vendorUuid = 'vendorUuid';
  static const date = 'date';
  static const basePrice = 'basePrice';
  static const taxAmount = 'taxAmount';
  static const totalAmount = 'totalAmount';
  static const currency = 'currency';
  static const orderDate = 'orderDate';
  static const expectedDeliveryDate = 'expectedDeliveryDate';
  static const amountPaid = 'amountPaid';
  static const amountBalance = 'amountBalance';
  static const completed = 'completed';
  static const basketUuid = 'basketUuid';
  static const quotationUuid = 'quotationUuid';
  static const projectUuid = 'projectUuid';
  static const description = 'description';
  static const deliveryAddress = 'deliveryAddress';
  static const phoneNumber = 'phoneNumber';
  static const updatedAt = 'updatedAt';
}

abstract class PurchaseOrderTableFields {
  static const uuid = 'uuid';
  static const id = 'id';
  static const vendorUuid = 'vendor_uuid';
  static const date = 'date';
  static const basePrice = 'base_price';
  static const taxAmount = 'tax_amount';
  static const totalAmount = 'total_amount';
  static const currency = 'currency';
  static const orderDate = 'order_date';
  static const expectedDeliveryDate = 'expected_delivery_date';
  static const amountPaid = 'amount_paid';
  static const amountBalance = 'amount_balance';
  static const completed = 'completed';
  static const basketUuid = 'basket_uuid';
  static const quotationUuid = 'quotation_uuid';
  static const projectUuid = 'project_uuid';
  static const description = 'description';
  static const deliveryAddress = 'delivery_address';
  static const phoneNumber = 'phone_number';
  static const updatedAt = 'updated_at';
}

class PurchaseOrder {
  final String uuid;
  final int? id;
  final String vendorUuid;
  final DateTime date;
  final double basePrice;
  final double taxAmount;
  final double totalAmount;
  final String? currency;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final double amountPaid;
  final double amountBalance;
  final bool completed;
  final String? basketUuid;
  final String? quotationUuid;
  final String? projectUuid;
  final String? description;
  final String? deliveryAddress;
  final String? phoneNumber;
  final DateTime updatedAt;

  PurchaseOrder({
    required this.uuid,
    this.id,
    required this.vendorUuid,
    required this.date,
    required this.basePrice,
    required this.taxAmount,
    required this.totalAmount,
    this.currency,
    required this.orderDate,
    this.expectedDeliveryDate,
    this.amountPaid = 0.0,
    this.amountBalance = 0.0,
    this.completed = false,
    this.basketUuid,
    this.quotationUuid,
    this.projectUuid,
    this.description,
    this.deliveryAddress,
    this.phoneNumber,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      PurchaseOrderTableFields.uuid: uuid,
      PurchaseOrderTableFields.id: id,
      PurchaseOrderTableFields.vendorUuid: vendorUuid,
      PurchaseOrderTableFields.date: date,
      PurchaseOrderTableFields.basePrice: basePrice,
      PurchaseOrderTableFields.taxAmount: taxAmount,
      PurchaseOrderTableFields.totalAmount: totalAmount,
      PurchaseOrderTableFields.currency: currency,
      PurchaseOrderTableFields.orderDate: orderDate,
      PurchaseOrderTableFields.expectedDeliveryDate: expectedDeliveryDate,
      PurchaseOrderTableFields.amountPaid: amountPaid,
      PurchaseOrderTableFields.amountBalance: amountBalance,
      PurchaseOrderTableFields.completed: completed,
      PurchaseOrderTableFields.basketUuid: basketUuid,
      PurchaseOrderTableFields.quotationUuid: quotationUuid,
      PurchaseOrderTableFields.projectUuid: projectUuid,
      PurchaseOrderTableFields.description: description,
      PurchaseOrderTableFields.deliveryAddress: deliveryAddress,
      PurchaseOrderTableFields.phoneNumber: phoneNumber,
      PurchaseOrderTableFields.updatedAt: updatedAt,
    };
  }

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    return PurchaseOrder(
      uuid: map[PurchaseOrderTableFields.uuid],
      id: map[PurchaseOrderTableFields.id],
      vendorUuid: map[PurchaseOrderTableFields.vendorUuid],
      date: map[PurchaseOrderTableFields.date],
      basePrice: map[PurchaseOrderTableFields.basePrice],
      taxAmount: map[PurchaseOrderTableFields.taxAmount],
      totalAmount: map[PurchaseOrderTableFields.totalAmount],
      currency: map[PurchaseOrderTableFields.currency],
      orderDate: map[PurchaseOrderTableFields.orderDate],
      expectedDeliveryDate: map[PurchaseOrderTableFields.expectedDeliveryDate],
      amountPaid: map[PurchaseOrderTableFields.amountPaid],
      amountBalance: map[PurchaseOrderTableFields.amountBalance],
      completed: map[PurchaseOrderTableFields.completed],
      basketUuid: map[PurchaseOrderTableFields.basketUuid],
      quotationUuid: map[PurchaseOrderTableFields.quotationUuid],
      projectUuid: map[PurchaseOrderTableFields.projectUuid],
      description: map[PurchaseOrderTableFields.description],
      deliveryAddress: map[PurchaseOrderTableFields.deliveryAddress],
      phoneNumber: map[PurchaseOrderTableFields.phoneNumber],
      updatedAt: map[PurchaseOrderTableFields.updatedAt],
    );
  }

  PurchaseOrder copyWith({
    String? uuid,
    int? id,
    String? vendorUuid,
    DateTime? date,
    double? basePrice,
    double? taxAmount,
    double? totalAmount,
    String? currency,
    DateTime? orderDate,
    DateTime? expectedDeliveryDate,
    double? amountPaid,
    double? amountBalance,
    bool? completed,
    String? basketUuid,
    String? quotationUuid,
    String? projectUuid,
    String? description,
    String? deliveryAddress,
    String? phoneNumber,
    DateTime? updatedAt,
  }) {
    return PurchaseOrder(
      uuid: uuid ?? this.uuid,
      id: id ?? this.id,
      vendorUuid: vendorUuid ?? this.vendorUuid,
      date: date ?? this.date,
      basePrice: basePrice ?? this.basePrice,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      orderDate: orderDate ?? this.orderDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      amountPaid: amountPaid ?? this.amountPaid,
      amountBalance: amountBalance ?? this.amountBalance,
      completed: completed ?? this.completed,
      basketUuid: basketUuid ?? this.basketUuid,
      quotationUuid: quotationUuid ?? this.quotationUuid,
      projectUuid: projectUuid ?? this.projectUuid,
      description: description ?? this.description,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static final _uuidFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.uuid,
      tableFieldName: PurchaseOrderTableFields.uuid,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _idFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.id,
      tableFieldName: PurchaseOrderTableFields.id,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: int);

  static final _vendorUuidFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.vendorUuid,
      tableFieldName: PurchaseOrderTableFields.vendorUuid,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _dateFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.date,
      tableFieldName: PurchaseOrderTableFields.date,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final _basePriceFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.basePrice,
      tableFieldName: PurchaseOrderTableFields.basePrice,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _taxAmountFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.taxAmount,
      tableFieldName: PurchaseOrderTableFields.taxAmount,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _totalAmountFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.totalAmount,
      tableFieldName: PurchaseOrderTableFields.totalAmount,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _currencyFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.currency,
      tableFieldName: PurchaseOrderTableFields.currency,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _orderDateFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.orderDate,
      tableFieldName: PurchaseOrderTableFields.orderDate,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final _expectedDeliveryDateFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.expectedDeliveryDate,
      tableFieldName: PurchaseOrderTableFields.expectedDeliveryDate,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: DateTime);

  static final _amountPaidFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.amountPaid,
      tableFieldName: PurchaseOrderTableFields.amountPaid,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _amountBalanceFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.amountBalance,
      tableFieldName: PurchaseOrderTableFields.amountBalance,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _completedFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.completed,
      tableFieldName: PurchaseOrderTableFields.completed,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: bool);

  static final _basketUuidFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.basketUuid,
      tableFieldName: PurchaseOrderTableFields.basketUuid,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _quotationUuidFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.quotationUuid,
      tableFieldName: PurchaseOrderTableFields.quotationUuid,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _projectUuidFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.projectUuid,
      tableFieldName: PurchaseOrderTableFields.projectUuid,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _descriptionFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.description,
      tableFieldName: PurchaseOrderTableFields.description,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _deliveryAddressFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.deliveryAddress,
      tableFieldName: PurchaseOrderTableFields.deliveryAddress,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _phoneNumberFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.phoneNumber,
      tableFieldName: PurchaseOrderTableFields.phoneNumber,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: PurchaseOrderFields.updatedAt,
      tableFieldName: PurchaseOrderTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'PurchaseOrder',
      databaseTableName: TableNames.purchaseOrders,
      type: ModelTypes.transactionData,
      displayName: 'Purchase Order',
      tableIndex: 301,
      fromMap: PurchaseOrder.fromMap,
      toMap: (dynamic instance) => (instance as PurchaseOrder).toMap(),
      fields: {
        PurchaseOrderFields.uuid: _uuidFieldDef,
        PurchaseOrderFields.id: _idFieldDef,
        PurchaseOrderFields.vendorUuid: _vendorUuidFieldDef,
        PurchaseOrderFields.date: _dateFieldDef,
        PurchaseOrderFields.basePrice: _basePriceFieldDef,
        PurchaseOrderFields.taxAmount: _taxAmountFieldDef,
        PurchaseOrderFields.totalAmount: _totalAmountFieldDef,
        PurchaseOrderFields.currency: _currencyFieldDef,
        PurchaseOrderFields.orderDate: _orderDateFieldDef,
        PurchaseOrderFields.expectedDeliveryDate: _expectedDeliveryDateFieldDef,
        PurchaseOrderFields.amountPaid: _amountPaidFieldDef,
        PurchaseOrderFields.amountBalance: _amountBalanceFieldDef,
        PurchaseOrderFields.completed: _completedFieldDef,
        PurchaseOrderFields.basketUuid: _basketUuidFieldDef,
        PurchaseOrderFields.quotationUuid: _quotationUuidFieldDef,
        PurchaseOrderFields.projectUuid: _projectUuidFieldDef,
        PurchaseOrderFields.description: _descriptionFieldDef,
        PurchaseOrderFields.deliveryAddress: _deliveryAddressFieldDef,
        PurchaseOrderFields.phoneNumber: _phoneNumberFieldDef,
        PurchaseOrderFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory PurchaseOrder.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as PurchaseOrder;
  }
}
