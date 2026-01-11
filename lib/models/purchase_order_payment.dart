// Helper function to safely parse numeric values from maps
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
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
      'uuid': uuid,
      'purchase_order_uuid': purchaseOrderUuid,
      'date': date.toIso8601String(),
      'amount': amount,
      'currency': currency,
      'upi_ref_number': upiRefNumber,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory PurchaseOrderPayment.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderPayment(
      uuid: map['uuid'] as String,
      purchaseOrderUuid: map['purchase_order_uuid'] as String,
      date: DateTime.parse(map['date'] as String),
      amount: _toDouble(map['amount']),
      upiRefNumber: map['upi_ref_number'] as String?,
      updatedAt: DateTime.parse(map['updated_at'] as String),
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
}
