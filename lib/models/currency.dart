class Currency {
  final String name; // Primary key
  final String? description;
  final String? symbol;
  final int numberOfDecimalPlaces;
  final bool isDefault;
  final DateTime updatedAt;

  Currency({
    required this.name,
    this.description,
    this.symbol,
    this.numberOfDecimalPlaces = 2,
    this.isDefault = false,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'symbol': symbol,
      'number_of_decimal_places': numberOfDecimalPlaces,
      'is_default': isDefault ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      name: map['name'] as String,
      description: map['description'] as String?,
      symbol: map['symbol'] as String?,
      numberOfDecimalPlaces: map['number_of_decimal_places'] as int? ?? 2,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Currency copyWith({
    String? name,
    String? description,
    String? symbol,
    int? numberOfDecimalPlaces,
    bool? isDefault,
    DateTime? updatedAt,
  }) {
    return Currency(
      name: name ?? this.name,
      description: description ?? this.description,
      symbol: symbol ?? this.symbol,
      numberOfDecimalPlaces:
          numberOfDecimalPlaces ?? this.numberOfDecimalPlaces,
      isDefault: isDefault ?? this.isDefault,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Currency{name: $name, description: $description, symbol: $symbol, numberOfDecimalPlaces: $numberOfDecimalPlaces, isDefault: $isDefault, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Currency && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
