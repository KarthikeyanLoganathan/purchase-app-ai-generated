import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';

abstract class CurrencyFields {
  static const name = 'name';
  static const description = 'description';
  static const symbol = 'symbol';
  static const numberOfDecimalPlaces = 'numberOfDecimalPlaces';
  static const updatedAt = 'updatedAt';
}

abstract class CurrencyTableFields {
  static const name = 'name';
  static const description = 'description';
  static const symbol = 'symbol';
  static const numberOfDecimalPlaces = 'number_of_decimal_places';
  static const updatedAt = 'updated_at';
}

class Currency {
  final String name; // Primary key
  final String? description;
  final String? symbol;
  final int numberOfDecimalPlaces;
  final DateTime updatedAt;

  Currency({
    required this.name,
    this.description,
    this.symbol,
    this.numberOfDecimalPlaces = 2,
    required this.updatedAt,
  });

  static final inrCurrency = Currency(
    name: 'INR',
    description: 'Indian Rupee',
    symbol: '₹',
    numberOfDecimalPlaces: 2,
    updatedAt: DateTime.utc(2024, 1, 1),
  );

  Map<String, dynamic> toMap() {
    return {
      CurrencyTableFields.name: name,
      CurrencyTableFields.description: description,
      CurrencyTableFields.symbol: symbol,
      CurrencyTableFields.numberOfDecimalPlaces: numberOfDecimalPlaces,
      CurrencyTableFields.updatedAt: updatedAt,
    };
  }

  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      name: map[CurrencyTableFields.name],
      description: map[CurrencyTableFields.description],
      symbol: map[CurrencyTableFields.symbol],
      numberOfDecimalPlaces: map[CurrencyTableFields.numberOfDecimalPlaces],
      updatedAt: map[CurrencyTableFields.updatedAt],
    );
  }

  Currency copyWith({
    String? name,
    String? description,
    String? symbol,
    int? numberOfDecimalPlaces,
    DateTime? updatedAt,
  }) {
    return Currency(
      name: name ?? this.name,
      description: description ?? this.description,
      symbol: symbol ?? this.symbol,
      numberOfDecimalPlaces:
          numberOfDecimalPlaces ?? this.numberOfDecimalPlaces,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Currency{name: $name, description: $description, symbol: $symbol, numberOfDecimalPlaces: $numberOfDecimalPlaces, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Currency && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  static final _nameFieldDef = ModelFieldDefinition(
      name: CurrencyFields.name,
      tableFieldName: CurrencyTableFields.name,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _descriptionFieldDef = ModelFieldDefinition(
      name: CurrencyFields.description,
      tableFieldName: CurrencyTableFields.description,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _symbolFieldDef = ModelFieldDefinition(
      name: CurrencyFields.symbol,
      tableFieldName: CurrencyTableFields.symbol,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _numberOfDecimalPlacesFieldDef = ModelFieldDefinition(
      name: CurrencyFields.numberOfDecimalPlaces,
      tableFieldName: CurrencyTableFields.numberOfDecimalPlaces,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: int);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: CurrencyFields.updatedAt,
      tableFieldName: CurrencyTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'Currency',
      databaseTableName: TableNames.currencies,
      type: ModelTypes.configuration,
      displayName: 'Currency',
      tableIndex: 5,
      fromMap: Currency.fromMap,
      toMap: (dynamic instance) => (instance as Currency).toMap(),
      fields: {
        CurrencyFields.name: _nameFieldDef,
        CurrencyFields.description: _descriptionFieldDef,
        CurrencyFields.symbol: _symbolFieldDef,
        CurrencyFields.numberOfDecimalPlaces: _numberOfDecimalPlacesFieldDef,
        CurrencyFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory Currency.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as Currency;
  }
}
