import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';

abstract class MaterialFields {
  static const uuid = 'uuid';
  static const id = 'id';
  static const name = 'name';
  static const description = 'description';
  static const unitOfMeasure = 'unitOfMeasure';
  static const website = 'website';
  static const photoUuid = 'photoUuid';
  static const updatedAt = 'updatedAt';
}

abstract class MaterialTableFields {
  static const uuid = 'uuid';
  static const id = 'id';
  static const name = 'name';
  static const description = 'description';
  static const unitOfMeasure = 'unit_of_measure';
  static const website = 'website';
  static const photoUuid = 'photo_uuid';
  static const updatedAt = 'updated_at';
}

class Material {
  final String uuid;
  final int? id;
  final String name;
  final String? description;
  final String unitOfMeasure;
  final String? website;
  final String? photoUuid;
  final DateTime updatedAt;

  Material({
    required this.uuid,
    this.id,
    required this.name,
    this.description,
    required this.unitOfMeasure,
    this.website,
    this.photoUuid,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      MaterialTableFields.uuid: uuid,
      MaterialTableFields.id: id,
      MaterialTableFields.name: name,
      MaterialTableFields.description: description,
      MaterialTableFields.unitOfMeasure: unitOfMeasure,
      MaterialTableFields.website: website,
      MaterialTableFields.photoUuid: photoUuid,
      MaterialTableFields.updatedAt: updatedAt,
    };
  }

  factory Material.fromMap(Map<String, dynamic> map) {
    return Material(
      uuid: map[MaterialTableFields.uuid],
      id: map[MaterialTableFields.id],
      name: map[MaterialTableFields.name],
      description: map[MaterialTableFields.description],
      unitOfMeasure: map[MaterialTableFields.unitOfMeasure],
      website: map[MaterialTableFields.website],
      photoUuid: map[MaterialTableFields.photoUuid],
      updatedAt: map[MaterialTableFields.updatedAt],
    );
  }

  Material copyWith({
    String? uuid,
    int? id,
    String? name,
    String? description,
    String? unitOfMeasure,
    String? website,
    String? photoUuid,
    DateTime? updatedAt,
  }) {
    return Material(
      uuid: uuid ?? this.uuid,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      website: website ?? this.website,
      photoUuid: photoUuid ?? this.photoUuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Material && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;

  static final _uuidFieldDef = ModelFieldDefinition(
      name: MaterialFields.uuid,
      tableFieldName: MaterialTableFields.uuid,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _idFieldDef = ModelFieldDefinition(
      name: MaterialFields.id,
      tableFieldName: MaterialTableFields.id,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: int);

  static final _nameFieldDef = ModelFieldDefinition(
      name: MaterialFields.name,
      tableFieldName: MaterialTableFields.name,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _descriptionFieldDef = ModelFieldDefinition(
      name: MaterialFields.description,
      tableFieldName: MaterialTableFields.description,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _unitOfMeasureFieldDef = ModelFieldDefinition(
      name: MaterialFields.unitOfMeasure,
      tableFieldName: MaterialTableFields.unitOfMeasure,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _websiteFieldDef = ModelFieldDefinition(
      name: MaterialFields.website,
      tableFieldName: MaterialTableFields.website,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _photoUuidFieldDef = ModelFieldDefinition(
      name: MaterialFields.photoUuid,
      tableFieldName: MaterialTableFields.photoUuid,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: MaterialFields.updatedAt,
      tableFieldName: MaterialTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'Material',
      databaseTableName: TableNames.materials,
      type: ModelTypes.masterData,
      displayName: 'Material',
      tableIndex: 203,
      fromMap: Material.fromMap,
      toMap: (dynamic instance) => (instance as Material).toMap(),
      fields: {
        MaterialFields.uuid: _uuidFieldDef,
        MaterialFields.id: _idFieldDef,
        MaterialFields.name: _nameFieldDef,
        MaterialFields.description: _descriptionFieldDef,
        MaterialFields.unitOfMeasure: _unitOfMeasureFieldDef,
        MaterialFields.website: _websiteFieldDef,
        MaterialFields.photoUuid: _photoUuidFieldDef,
        MaterialFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory Material.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as Material;
  }
}
