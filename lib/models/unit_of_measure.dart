class UnitOfMeasure {
  final String name; // Primary key
  final String? description;
  final int numberOfDecimalPlaces;
  final bool isDefault;
  final DateTime updatedAt;

  UnitOfMeasure({
    required this.name,
    this.description,
    this.numberOfDecimalPlaces = 2,
    this.isDefault = false,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'number_of_decimal_places': numberOfDecimalPlaces,
      'is_default': isDefault ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UnitOfMeasure.fromMap(Map<String, dynamic> map) {
    return UnitOfMeasure(
      name: map['name'] as String,
      description: map['description'] as String?,
      numberOfDecimalPlaces: map['number_of_decimal_places'] as int? ?? 2,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  UnitOfMeasure copyWith({
    String? name,
    String? description,
    int? numberOfDecimalPlaces,
    bool? isDefault,
    DateTime? updatedAt,
  }) {
    return UnitOfMeasure(
      name: name ?? this.name,
      description: description ?? this.description,
      numberOfDecimalPlaces:
          numberOfDecimalPlaces ?? this.numberOfDecimalPlaces,
      isDefault: isDefault ?? this.isDefault,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UnitOfMeasure{name: $name, description: $description, numberOfDecimalPlaces: $numberOfDecimalPlaces, isDefault: $isDefault, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnitOfMeasure && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
