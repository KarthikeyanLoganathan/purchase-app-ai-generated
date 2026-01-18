import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';

abstract class UnitOfMeasures {
  static const percent = '%';
}

abstract class UnitOfMeasureFields {
  static const name = 'name';
  static const description = 'description';
  static const numberOfDecimalPlaces = 'numberOfDecimalPlaces';
  static const updatedAt = 'updatedAt';
}

abstract class UnitOfMeasureTableFields {
  static const name = 'name';
  static const description = 'description';
  static const numberOfDecimalPlaces = 'number_of_decimal_places';
  static const updatedAt = 'updated_at';
}

class UnitOfMeasure {
  final String name; // Primary key
  final String? description;
  final int numberOfDecimalPlaces;
  final DateTime updatedAt;

  UnitOfMeasure({
    required this.name,
    this.description,
    this.numberOfDecimalPlaces = 2,
    required this.updatedAt,
  });

  static final UnitOfMeasure nosUnitOfMeasure = UnitOfMeasure(
    name: 'Nos',
    description: 'Numbers',
    numberOfDecimalPlaces: 0,
    updatedAt: DateTime.now().toUtc(),
  );

  static final UnitOfMeasure percentUnitOfMeasure = UnitOfMeasure(
    name: '%',
    description: 'Percent',
    numberOfDecimalPlaces: 2,
    updatedAt: DateTime.now().toUtc(),
  );

  Map<String, dynamic> toMap() {
    return {
      UnitOfMeasureTableFields.name: name,
      UnitOfMeasureTableFields.description: description,
      UnitOfMeasureTableFields.numberOfDecimalPlaces: numberOfDecimalPlaces,
      UnitOfMeasureTableFields.updatedAt: updatedAt,
    };
  }

  factory UnitOfMeasure.fromMap(Map<String, dynamic> map) {
    return UnitOfMeasure(
      name: map[UnitOfMeasureTableFields.name],
      description: map[UnitOfMeasureTableFields.description],
      numberOfDecimalPlaces:
          map[UnitOfMeasureTableFields.numberOfDecimalPlaces],
      updatedAt: map[UnitOfMeasureTableFields.updatedAt],
    );
  }

  UnitOfMeasure copyWith({
    String? name,
    String? description,
    int? numberOfDecimalPlaces,
    DateTime? updatedAt,
  }) {
    return UnitOfMeasure(
      name: name ?? this.name,
      description: description ?? this.description,
      numberOfDecimalPlaces:
          numberOfDecimalPlaces ?? this.numberOfDecimalPlaces,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UnitOfMeasure{name: $name, description: $description, numberOfDecimalPlaces: $numberOfDecimalPlaces, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnitOfMeasure && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  static final _nameFieldDef = ModelFieldDefinition(
      name: UnitOfMeasureFields.name,
      tableFieldName: UnitOfMeasureTableFields.name,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _descriptionFieldDef = ModelFieldDefinition(
      name: UnitOfMeasureFields.description,
      tableFieldName: UnitOfMeasureTableFields.description,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _numberOfDecimalPlacesFieldDef = ModelFieldDefinition(
      name: UnitOfMeasureFields.numberOfDecimalPlaces,
      tableFieldName: UnitOfMeasureTableFields.numberOfDecimalPlaces,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: int);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: UnitOfMeasureFields.updatedAt,
      tableFieldName: UnitOfMeasureTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'UnitOfMeasure',
      databaseTableName: TableNames.unitOfMeasures,
      type: ModelTypes.configuration,
      displayName: 'Unit of Measure',
      tableIndex: 101,
      fromMap: UnitOfMeasure.fromMap,
      toMap: (dynamic instance) => (instance as UnitOfMeasure).toMap(),
      fields: {
        UnitOfMeasureFields.name: _nameFieldDef,
        UnitOfMeasureFields.description: _descriptionFieldDef,
        UnitOfMeasureFields.numberOfDecimalPlaces:
            _numberOfDecimalPlacesFieldDef,
        UnitOfMeasureFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory UnitOfMeasure.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as UnitOfMeasure;
  }
}
