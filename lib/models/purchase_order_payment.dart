import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';

abstract class PurchaseOrderPaymentFields {
  static const uuid = 'uuid';
  static const purchaseOrderUuid = 'purchaseOrderUuid';
  static const date = 'date';
  static const amount = 'amount';
  static const currency = 'currency';
  static const upiRefNumber = 'upiRefNumber';
  static const updatedAt = 'updatedAt';
}

abstract class PurchaseOrderPaymentTableFields {
  static const uuid = 'uuid';
  static const purchaseOrderUuid = 'purchase_order_uuid';
  static const date = 'date';
  static const amount = 'amount';
  static const currency = 'currency';
  static const upiRefNumber = 'upi_ref_number';
  static const updatedAt = 'updated_at';
}

class PurchaseOrderPayment {
  final String uuid;
  final String purchaseOrderUuid;
  final DateTime date;
  final double amount;
  final String? currency;
  final String? upiRefNumber;
  final DateTime updatedAt;

  PurchaseOrderPayment({
    required this.uuid,
    required this.purchaseOrderUuid,
    required this.date,
    required this.amount,
    this.currency,
    this.upiRefNumber,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      PurchaseOrderPaymentTableFields.uuid: uuid,
      PurchaseOrderPaymentTableFields.purchaseOrderUuid: purchaseOrderUuid,
      PurchaseOrderPaymentTableFields.date: date,
      PurchaseOrderPaymentTableFields.amount: amount,
      PurchaseOrderPaymentTableFields.currency: currency,
      PurchaseOrderPaymentTableFields.upiRefNumber: upiRefNumber,
      PurchaseOrderPaymentTableFields.updatedAt: updatedAt,
    };
  }

  factory PurchaseOrderPayment.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderPayment(
      uuid: map[PurchaseOrderPaymentTableFields.uuid],
      purchaseOrderUuid: map[PurchaseOrderPaymentTableFields.purchaseOrderUuid],
      date: map[PurchaseOrderPaymentTableFields.date],
      amount: map[PurchaseOrderPaymentTableFields.amount],
      currency: map[PurchaseOrderPaymentTableFields.currency],
      upiRefNumber: map[PurchaseOrderPaymentTableFields.upiRefNumber],
      updatedAt: map[PurchaseOrderPaymentTableFields.updatedAt],
    );
  }

  PurchaseOrderPayment copyWith({
    String? uuid,
    String? purchaseOrderUuid,
    DateTime? date,
    double? amount,
    String? currency,
    String? upiRefNumber,
    DateTime? updatedAt,
  }) {
    return PurchaseOrderPayment(
      uuid: uuid ?? this.uuid,
      purchaseOrderUuid: purchaseOrderUuid ?? this.purchaseOrderUuid,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      upiRefNumber: upiRefNumber ?? this.upiRefNumber,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static final _uuidFieldDef = ModelFieldDefinition(
      name: PurchaseOrderPaymentFields.uuid,
      tableFieldName: PurchaseOrderPaymentTableFields.uuid,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _purchaseOrderUuidFieldDef = ModelFieldDefinition(
      name: PurchaseOrderPaymentFields.purchaseOrderUuid,
      tableFieldName: PurchaseOrderPaymentTableFields.purchaseOrderUuid,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _dateFieldDef = ModelFieldDefinition(
      name: PurchaseOrderPaymentFields.date,
      tableFieldName: PurchaseOrderPaymentTableFields.date,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final _amountFieldDef = ModelFieldDefinition(
      name: PurchaseOrderPaymentFields.amount,
      tableFieldName: PurchaseOrderPaymentTableFields.amount,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: double);

  static final _currencyFieldDef = ModelFieldDefinition(
      name: PurchaseOrderPaymentFields.currency,
      tableFieldName: PurchaseOrderPaymentTableFields.currency,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _upiRefNumberFieldDef = ModelFieldDefinition(
      name: PurchaseOrderPaymentFields.upiRefNumber,
      tableFieldName: PurchaseOrderPaymentTableFields.upiRefNumber,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: PurchaseOrderPaymentFields.updatedAt,
      tableFieldName: PurchaseOrderPaymentTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'PurchaseOrderPayment',
      databaseTableName: TableNames.purchaseOrderPayments,
      type: ModelTypes.transactionData,
      displayName: 'Purchase Order Payment',
      tableIndex: 303,
      fromMap: PurchaseOrderPayment.fromMap,
      toMap: (dynamic instance) => (instance as PurchaseOrderPayment).toMap(),
      fields: {
        PurchaseOrderPaymentFields.uuid: _uuidFieldDef,
        PurchaseOrderPaymentFields.purchaseOrderUuid:
            _purchaseOrderUuidFieldDef,
        PurchaseOrderPaymentFields.date: _dateFieldDef,
        PurchaseOrderPaymentFields.amount: _amountFieldDef,
        PurchaseOrderPaymentFields.currency: _currencyFieldDef,
        PurchaseOrderPaymentFields.upiRefNumber: _upiRefNumberFieldDef,
        PurchaseOrderPaymentFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory PurchaseOrderPayment.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as PurchaseOrderPayment;
  }
}
