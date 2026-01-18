import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';

abstract class DefaultsTypes {
  static const currency = 'Currency';
  static const unitOfMeasure = 'UnitOfMeasure';
  static final List<String> allTypes =
      List.unmodifiable([currency, unitOfMeasure]);
}

abstract class DefaultsFields {
  static const type = 'type';
  static const value = 'value';
  static const updatedAt = 'updatedAt';
}

abstract class DefaultsTableFields {
  static const type = 'type';
  static const value = 'value';
  static const updatedAt = 'updated_at';
}

class Defaults {
  final String type; // Primary key - allowed values: Currency, UnitOfMeasure
  final String value;
  final DateTime updatedAt;

  Defaults({
    required this.type,
    required this.value,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      DefaultsTableFields.type: type,
      DefaultsTableFields.value: value,
      DefaultsTableFields.updatedAt: updatedAt,
    };
  }

  factory Defaults.fromMap(Map<String, dynamic> map) {
    return Defaults(
      type: map[DefaultsTableFields.type],
      value: map[DefaultsTableFields.value],
      updatedAt: map[DefaultsTableFields.updatedAt],
    );
  }

  Defaults copyWith({
    String? type,
    String? value,
    DateTime? updatedAt,
  }) {
    return Defaults(
      type: type ?? this.type,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Defaults{type: $type, value: $value, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Defaults && other.type == type;
  }

  @override
  int get hashCode => type.hashCode;

  static final _typeFieldDef = ModelFieldDefinition(
      name: DefaultsFields.type,
      tableFieldName: DefaultsTableFields.type,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _valueFieldDef = ModelFieldDefinition(
      name: DefaultsFields.value,
      tableFieldName: DefaultsTableFields.value,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: DefaultsFields.updatedAt,
      tableFieldName: DefaultsTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'Defaults',
      databaseTableName: TableNames.defaults,
      type: ModelTypes.configuration,
      displayName: 'Defaults',
      tableIndex: 100,
      fromMap: Defaults.fromMap,
      toMap: (dynamic instance) => (instance as Defaults).toMap(),
      fields: {
        DefaultsFields.type: _typeFieldDef,
        DefaultsFields.value: _valueFieldDef,
        DefaultsFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory Defaults.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as Defaults;
  }
}
